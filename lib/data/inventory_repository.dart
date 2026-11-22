import 'dart:convert';

import 'package:karat/domain/jewellery_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class InventoryRepository {
  Future<List<JewelleryItem>> load(String userId);

  Future<void> save(String userId, List<JewelleryItem> items);
}

class SharedPreferencesInventory implements InventoryRepository {
  static String _key(String userId) => 'karat.book.$userId';

  @override
  Future<List<JewelleryItem>> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stock book is not a list.');
    }
    return decoded.map((entry) {
      if (entry is! Map) {
        throw const FormatException('A stock entry is malformed.');
      }
      return JewelleryItem.fromJson(entry.cast<String, Object?>());
    }).toList();
  }

  @override
  Future<void> save(String userId, List<JewelleryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((item) => item.toJson()).toList());
    final wrote = await prefs.setString(_key(userId), encoded);
    if (!wrote) {
      throw StateError('Could not write the stock book.');
    }
  }
}
