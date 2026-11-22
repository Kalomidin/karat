/// A calendar day in the shop's local time, with no clock time attached.
class Day implements Comparable<Day> {
  const Day(this.year, this.month, this.day);

  factory Day.fromDateTime(DateTime date) {
    return Day(date.year, date.month, date.day);
  }

  factory Day.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Expected a date, got $value.');
    }
    final day = Day(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    final check = day.date;
    if (check.year != day.year ||
        check.month != day.month ||
        check.day != day.day) {
      throw FormatException('Expected a date, got $value.');
    }
    return day;
  }

  final int year;
  final int month;
  final int day;

  DateTime get date => DateTime(year, month, day);

  String get iso {
    final monthText = month.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    return '$year-$monthText-$dayText';
  }

  Day addDays(int days) => Day.fromDateTime(date.add(Duration(days: days)));

  /// Monday of the week that contains this day.
  Day get weekStart => addDays(-(date.weekday - DateTime.monday));

  @override
  int compareTo(Day other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator >(Day other) => compareTo(other) > 0;
  bool operator >=(Day other) => compareTo(other) >= 0;
  bool operator <(Day other) => compareTo(other) < 0;
  bool operator <=(Day other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    return other is Day &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
