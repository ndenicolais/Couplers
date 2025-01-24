class TimeUtils {
  static Map<String, int> calculateCoupleTime(DateTime togetherDate) {
    DateTime now = DateTime.now();
    int years = now.year - togetherDate.year;
    int months = now.month - togetherDate.month;
    int days = now.day - togetherDate.day;

    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (days < 0) {
      months -= 1;
      days += DateTime(now.year, now.month, 0).day;
    }

    Duration diff = now.difference(togetherDate);
    int hours = diff.inHours % 24;
    int minutes = diff.inMinutes % 60;
    int seconds = diff.inSeconds % 60;

    return {
      'years': years,
      'months': months,
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }
}
