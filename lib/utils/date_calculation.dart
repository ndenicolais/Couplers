import 'package:intl/intl.dart';

class DateCalculations {
  static List<Map<String, String>> calculateAnniversaries(
      DateTime coupleDate, String anniversaryLabel) {
    DateTime today = DateTime.now();
    List<Map<String, String>> anniversaries = [];
    int yearsDiff = today.year - coupleDate.year;

    for (int i = 1; i <= yearsDiff; i++) {
      DateTime anniversaryDate =
          DateTime(coupleDate.year + i, coupleDate.month, coupleDate.day);

      if (anniversaryDate.isAfter(today)) {
        break;
      }

      String formattedDate =
          DateFormat('dd MMMM yyyy', 'it_IT').format(anniversaryDate);
      anniversaries.add({
        'anniversary': '$i° $anniversaryLabel',
        'date': formattedDate,
      });
    }

    return anniversaries.reversed.toList();
  }

  static List<Map<String, String>> calculateDayversaries(
      DateTime coupleDate, String dayversaryLabel) {
    DateTime today = DateTime.now();
    List<Map<String, String>> dayversaries = [];
    int daysDiff = today.difference(coupleDate).inDays;

    for (int i = 1; i <= daysDiff ~/ 100; i++) {
      DateTime dayversaryDate = coupleDate.add(Duration(days: i * 100));
      String formattedDate =
          DateFormat('dd MMMM yyyy', 'it_IT').format(dayversaryDate);
      dayversaries.add({
        'dayversary': '${i * 100}° $dayversaryLabel',
        'date': formattedDate,
      });
    }

    return dayversaries.reversed.toList();
  }
}
