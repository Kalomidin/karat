import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google OAuth client ids from `.env`.
///
/// Android sign-in uses [serverClientId], the Web client id.
/// The Android client (package `com.karat.karat` plus the debug SHA-1)
/// stays in Google Cloud and is not pasted here.
/// iOS also needs the same [iosClientId] in `ios/Runner/Info.plist`.
abstract final class GoogleAuthConfig {
  static String get iosClientId => _env('GOOGLE_IOS_CLIENT_ID');

  static String get serverClientId => _env('GOOGLE_SERVER_CLIENT_ID');

  static bool get needsClientId {
    if (Platform.isAndroid && serverClientId.isEmpty) return true;
    if (Platform.isIOS && iosClientId.isEmpty) return true;
    return false;
  }
}

String _env(String key) {
  if (!dotenv.isInitialized) return '';
  return dotenv.maybeGet(key)?.trim() ?? '';
}
