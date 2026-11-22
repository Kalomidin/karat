/// The Google account that owns the stock book on this device.
class ShopUser {
  const ShopUser({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.shopName = '',
  });

  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String shopName;

  String get label {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? email : trimmed;
  }

  /// Shop name when the account has one, otherwise the person's name or email.
  String get headerTitle {
    final shop = shopName.trim();
    return shop.isEmpty ? label : shop;
  }
}

sealed class AuthEvent {
  const AuthEvent();
}

class AuthSignedIn extends AuthEvent {
  const AuthSignedIn(this.user);

  final ShopUser user;
}

class AuthSignedOut extends AuthEvent {
  const AuthSignedOut();
}

class AuthFailed extends AuthEvent {
  const AuthFailed(this.problem, {this.detail});

  final AuthProblem problem;
  final String? detail;
}

enum AuthProblem { notConfigured, userMismatch, interrupted, failed }

class AuthCancelled implements Exception {
  const AuthCancelled();
}

class AuthFailure implements Exception {
  const AuthFailure(this.problem, {this.detail});

  final AuthProblem problem;
  final String? detail;
}

abstract class AuthClient {
  /// True when this build has no Google client id for the current platform.
  bool get needsConfiguration;

  Future<void> initialize();

  Stream<AuthEvent> get events;

  Future<ShopUser?> restore();

  Future<ShopUser> signIn();

  /// The Google ID token for the signed-in account, when one is available.
  Future<String?> idToken();

  Future<void> signOut();

  Future<void> close();
}
