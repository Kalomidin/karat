import 'dart:convert';

import 'package:karat/auth/auth_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopProfile {
  const ShopProfile({this.name = '', this.shopName = '', this.photoPath = ''});

  final String name;
  final String shopName;
  final String photoPath;

  Map<String, Object?> toJson() {
    return {'name': name, 'shopName': shopName, 'photoPath': photoPath};
  }

  factory ShopProfile.fromJson(Map<String, Object?> json) {
    return ShopProfile(
      name: json['name'] is String ? json['name'] as String : '',
      shopName: json['shopName'] is String ? json['shopName'] as String : '',
      photoPath: json['photoPath'] is String ? json['photoPath'] as String : '',
    );
  }
}

abstract class ProfileStore {
  Future<ShopProfile?> load(String userId);

  Future<void> save(String userId, ShopProfile profile);
}

class PreferencesProfileStore implements ProfileStore {
  static String _key(String userId) => 'karat.profile.$userId';

  @override
  Future<ShopProfile?> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return ShopProfile.fromJson(decoded.cast<String, Object?>());
  }

  @override
  Future<void> save(String userId, ShopProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(profile.toJson()));
  }
}

ShopUser applyProfile(ShopUser google, ShopProfile? profile) {
  if (profile == null) return google;
  final name = profile.name.trim();
  final photo = profile.photoPath.trim();
  return ShopUser(
    id: google.id,
    email: google.email,
    name: name.isEmpty ? google.name : name,
    photoUrl: photo.isEmpty ? google.photoUrl : photo,
    shopName: profile.shopName.trim(),
  );
}
