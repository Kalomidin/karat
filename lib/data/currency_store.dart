import 'package:shared_preferences/shared_preferences.dart';

abstract class CurrencyStore {
  Future<String?> read();

  Future<void> write(String id);
}

class PreferencesCurrencyStore implements CurrencyStore {
  static const key = 'karat.currency';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, id);
  }
}
