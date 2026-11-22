import 'dart:io';

/// Google OAuth client ids for Karat.
///
/// The app targets Android and iOS only. Sign-in stays blocked until the
/// ids below are filled in from the same Google Cloud project.
///
/// 1. Create an OAuth project at https://console.cloud.google.com/apis/credentials
/// 2. Android client: package name `com.karat.karat`, plus the SHA-1 of the
///    keystore you sign with. Debug SHA-1:
///    `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android`
/// 3. Web client: create one in that project and paste its id into
///    [serverClientId]. Android sign-in uses the web client id, not the
///    Android client id.
/// 4. iOS client: bundle id `com.karat.karat`. Paste its id into [iosClientId].
///    Also set `GIDClientID` in `ios/Runner/Info.plist`, and set the URL
///    scheme to the reversed client id. For
///    `123-abc.apps.googleusercontent.com` the scheme is
///    `com.googleusercontent.apps.123-abc`.
abstract final class GoogleAuthConfig {
  static const iosClientId =
      '942973487076-75esdqolvo0ropi4hjq23rcr8mvdnu3b.apps.googleusercontent.com';
  static const serverClientId = '';

  static bool get needsClientId {
    if (Platform.isAndroid && serverClientId.trim().isEmpty) return true;
    if (Platform.isIOS && iosClientId.trim().isEmpty) return true;
    return false;
  }
}
