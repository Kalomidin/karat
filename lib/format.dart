import 'package:intl/intl.dart';
import 'package:karat/config/shop.dart';
import 'package:karat/domain/day.dart';

final NumberFormat _currency = NumberFormat.currency(
  locale: Shop.locale,
  name: Shop.currencyCode,
  symbol: Shop.currencySymbol,
  decimalDigits: 2,
);

String formatCents(int cents, {bool signed = false}) {
  final body = _currency.format(cents.abs() / 100);
  if (cents < 0) return '-$body';
  if (signed && cents > 0) return '+$body';
  return body;
}

String formatGrams(double grams, {String languageCode = 'en'}) {
  final unit = languageCode == 'ru' ? 'г' : 'g';
  return '${gramsToDisplay(grams)} $unit';
}

String gramsToDisplay(double grams) {
  var text = grams.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text;
}

String formatDay(Day day, {String languageCode = 'en'}) {
  return DateFormat.yMMMd(_dateLocale(languageCode)).format(day.date);
}

String formatWeekRange(Day start, {String languageCode = 'en'}) {
  final locale = _dateLocale(languageCode);
  final end = start.addDays(6);
  final dayMonth = DateFormat.MMMd(locale);
  final dayMonthYear = DateFormat.yMMMd(locale);
  if (start.year == end.year) {
    return '${dayMonth.format(start.date)} – ${dayMonthYear.format(end.date)}';
  }
  return '${dayMonthYear.format(start.date)} – ${dayMonthYear.format(end.date)}';
}

String _dateLocale(String languageCode) =>
    languageCode == 'ru' ? 'ru' : 'en_US';
