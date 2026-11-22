import 'package:karat/config/shop.dart';

/// Parses a non-negative amount typed by the user into cents.
///
/// Accepts `50`, `50.5`, `50.50`, and thousands separators. More than two
/// decimal places is rejected so a value is never silently rounded.
int? parseCents(String raw) {
  var cleaned = raw.trim().replaceAll(',', '').replaceAll(' ', '');
  if (cleaned.startsWith(Shop.currencySymbol)) {
    cleaned = cleaned.substring(Shop.currencySymbol.length);
  }
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final dollars = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  final cents = dollars * 100 + int.parse(fraction);
  if (cents > 10000000000) return null;
  return cents;
}

/// Parses a weight in grams. Zero and negative weights are rejected.
double? parseGrams(String raw) {
  final value = double.tryParse(raw.trim());
  if (value == null || value <= 0 || value > 100000) return null;
  final rounded = (value * 1000).round() / 1000;
  if (rounded <= 0) return null;
  return rounded;
}

String centsToInput(int cents) {
  final dollars = cents.abs() ~/ 100;
  final remainder = (cents.abs() % 100).toString().padLeft(2, '0');
  final text = '$dollars.$remainder';
  return cents < 0 ? '-$text' : text;
}

String gramsToInput(double grams) {
  var text = grams.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text;
}
