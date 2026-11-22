import 'package:karat/config/shop.dart';

/// Parses a non-negative whole amount. Cents and dirams are not used.
int? parseCents(String raw) {
  var cleaned = raw.trim().replaceAll(',', '').replaceAll(' ', '');
  if (cleaned.startsWith(Shop.currencySymbol)) {
    cleaned = cleaned.substring(Shop.currencySymbol.length);
  }
  if (cleaned.isEmpty) return null;
  if (!RegExp(r'^\d+$').hasMatch(cleaned)) return null;
  final units = int.parse(cleaned);
  if (units > 100000000) return null;
  return units * 100;
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
  final units = cents.abs() ~/ 100;
  return cents < 0 ? '-$units' : '$units';
}

String gramsToInput(double grams) {
  var text = grams.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text;
}
