import 'package:flutter_test/flutter_test.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('the device language is used until a choice is saved', () {
    expect(resolveKaratLocale(const Locale('ru'), null), const Locale('ru'));
    expect(
      resolveKaratLocale(const Locale('ru', 'KZ'), null),
      const Locale('ru'),
    );
    expect(
      resolveKaratLocale(const Locale('en', 'GB'), null),
      const Locale('en'),
    );
    expect(resolveKaratLocale(const Locale('fr'), null), const Locale('en'));
    expect(
      resolveKaratLocale(const Locale('ru'), const Locale('en')),
      const Locale('en'),
    );
  });
}
