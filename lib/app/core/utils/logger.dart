class Logger {
  static void d(String tag, String message) {
    // simple wrapper
    // ignore: avoid_print
    print('[$tag] $message');
  }
}
