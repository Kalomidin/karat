import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LanguageStore {
  Future<String?> read();

  Future<void> write(String code);
}

class PreferencesLanguageStore implements LanguageStore {
  static const key = 'karat.language';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, code);
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController({this.store});

  final LanguageStore? store;

  /// Null follows the device language.
  Locale? override;

  Future<void> load() async {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('ru');
    final code = await store?.read();
    if (code == 'en' || code == 'ru') {
      override = Locale(code!);
    }
    notifyListeners();
  }

  Future<void> choose(String code) async {
    if (code != 'en' && code != 'ru') return;
    override = Locale(code);
    notifyListeners();
    await store?.write(code);
  }
}
