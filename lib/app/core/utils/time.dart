class TimeUtils {
  static String formatHoursMinutes(int seconds) {
    final minutes = (seconds / 60).floor();
    final hrs = (minutes / 60).floor();
    final mins = minutes % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }
}
