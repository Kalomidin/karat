import 'dart:async';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/config/google_auth.dart';

class GoogleAuthClient implements AuthClient {
  final StreamController<AuthEvent> _events =
      StreamController<AuthEvent>.broadcast();
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleSub;
  bool _ready = false;

  @override
  bool get needsConfiguration => GoogleAuthConfig.needsClientId;

  @override
  Stream<AuthEvent> get events => _events.stream;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS
          ? _blankToNull(GoogleAuthConfig.iosClientId)
          : null,
      serverClientId: _blankToNull(GoogleAuthConfig.serverClientId),
    );
    _googleSub = GoogleSignIn.instance.authenticationEvents.listen(
      _onEvent,
      onError: _onError,
    );
    _ready = true;
  }

  @override
  Future<ShopUser?> restore() async {
    try {
      final account = await GoogleSignIn.instance
          .attemptLightweightAuthentication();
      return account == null ? null : _userFrom(account);
    } on GoogleSignInException catch (error) {
      if (_isQuiet(error)) return null;
      throw _failure(error);
    }
  }

  @override
  Future<ShopUser> signIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return _userFrom(account);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw _failure(error);
    }
  }

  @override
  Future<void> signOut() {
    return GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> close() async {
    await _googleSub?.cancel();
    await _events.close();
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    if (_events.isClosed) return;
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        _events.add(AuthSignedIn(_userFrom(user)));
      case GoogleSignInAuthenticationEventSignOut():
        _events.add(const AuthSignedOut());
    }
  }

  void _onError(Object error) {
    if (_events.isClosed) return;
    if (error is GoogleSignInException && _isQuiet(error)) return;
    final failure = _failure(error);
    _events.add(AuthFailed(failure.problem, detail: failure.detail));
  }

  ShopUser _userFrom(GoogleSignInAccount account) {
    return ShopUser(
      id: account.id,
      email: account.email,
      name: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _isQuiet(GoogleSignInException error) {
  return error.code == GoogleSignInExceptionCode.canceled ||
      error.code == GoogleSignInExceptionCode.interrupted ||
      error.code == GoogleSignInExceptionCode.uiUnavailable;
}

AuthFailure _failure(Object error) {
  if (error is GoogleSignInException) {
    return switch (error.code) {
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
        AuthProblem.notConfigured,
      ),
      GoogleSignInExceptionCode.userMismatch => const AuthFailure(
        AuthProblem.userMismatch,
      ),
      GoogleSignInExceptionCode.canceled ||
      GoogleSignInExceptionCode.interrupted ||
      GoogleSignInExceptionCode.uiUnavailable => const AuthFailure(
        AuthProblem.interrupted,
      ),
      GoogleSignInExceptionCode.unknownError => AuthFailure(
        AuthProblem.failed,
        detail: error.description,
      ),
    };
  }
  return const AuthFailure(AuthProblem.failed);
}
