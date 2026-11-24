class Termpaint < Formula
  desc "Low level terminal access library"
  homepage "https://termpaint.namepad.de/"
  url "https://github.com/termpaint/termpaint/releases/download/0.3.1/termpaint-0.3.1.tar.gz"
  sha256 "bd380831b3db7de95ae15d050755281abb82034e484728e9ca208bf1aea5d70a"
  license "BSL-1.0"

  depends_on "fmt" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build

  def install
    args = std_meson_args + [
      "-Dsystem-docopt=disabled",
      "-Dsystem-fmt=enabled",
      "-Dsystem-catch2=disabled",
      "-Dsystem-picojson=disabled",
      "-Dttyrescue-fexec-blob=false",
      "-Dttyrescue-install=true",
      "-Dttyrescue-path=#{libexec}",
      "-Dtools-path=#{libexec}",
    ]

    system "meson", "setup", "build", *args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stddef.h>
      #include <termpaint_event.h>
      #include <termpaint_input.h>

      static int received = 0;

      static void on_event(void *userdata, termpaint_event *event) {
        (void)userdata;
        if (event->type == TERMPAINT_EV_CHAR &&
            event->c.length == 1 && event->c.string[0] == 'q') {
          received = 1;
        }
      }

      int main(void) {
        termpaint_input *input = termpaint_input_new();
        if (!input) return 1;
        termpaint_input_set_event_cb(input, on_event, NULL);
        termpaint_input_add_data(input, "q", 1);
        termpaint_input_free(input);
        return received ? 0 : 1;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-ltermpaint",
                   "-Wl,-rpath,#{lib}", "-o", "test"
    system "./test"

    assert_path_exists lib/"pkgconfig/termpaint.pc"
    assert_path_exists libexec/"ttyrescue"
    assert_path_exists libexec/"inputevents"
    assert_path_exists libexec/"detect"
  end
end
