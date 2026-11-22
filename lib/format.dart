import 'package:intl/intl.dart';
import 'package:karat/config/shop.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';

String formatCents(int cents, {bool signed = false, String? currencyId}) {
  final symbol = currencyId == null
      ? Shop.currencySymbol
      : currencySymbolFor(currencyId);
  final body = NumberFormat.currency(
    locale: Shop.locale,
    symbol: symbol,
    decimalDigits: 0,
  ).format(cents.abs() / 100);
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

String formatPeriod(Day start, Day end, {String languageCode = 'en'}) {
  if (start == end) return formatDay(start, languageCode: languageCode);
  final locale = _dateLocale(languageCode);
  final dayMonth = DateFormat.MMMd(locale);
  final dayMonthYear = DateFormat.yMMMd(locale);
  if (start.year == end.year) {
    return '${dayMonth.format(start.date)} – ${dayMonthYear.format(end.date)}';
  }
  return '${dayMonthYear.format(start.date)} – ${dayMonthYear.format(end.date)}';
}

String _dateLocale(String languageCode) =>
    languageCode == 'ru' ? 'ru' : 'en_US';
