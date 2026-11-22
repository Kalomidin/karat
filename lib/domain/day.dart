/// A calendar day on the device, with no clock time attached.
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

  /// Start of this device day, written as a UTC timestamp.
  String get utcStart => utcStamp(DateTime(year, month, day));

  /// A server timestamp, shown as the calendar day on this device.
  factory Day.fromServer(String value) {
    if (value.contains('T')) {
      return Day.fromDateTime(DateTime.parse(value).toLocal());
    }
    return Day.parse(value);
  }

  Day addDays(int days) => Day.fromDateTime(date.add(Duration(days: days)));

  /// Monday of the week that contains this day.
  Day get weekStart => addDays(-(date.weekday - DateTime.monday));

  Day get monthStart => Day(year, month, 1);

  Day get monthEnd {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return Day.fromDateTime(nextMonth.subtract(const Duration(days: 1)));
  }

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

/// UTC timestamp with no fractional seconds, which the server accepts.
String utcStamp(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  final year = utc.year.toString().padLeft(4, '0');
  return '$year-${two(utc.month)}-${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}
