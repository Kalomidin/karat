import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/domain/book_notice.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';

class KaratController extends ChangeNotifier {
  KaratController({
    required this.inventory,
    required this.auth,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final InventoryRepository inventory;
  final AuthClient auth;
  final DateTime Function() _now;

  ShopUser? _user;
  bool _ready = false;
  bool _signingIn = false;
  AuthProblem? _authProblem;
  String? _authDetail;
  BookNotice? _storageNotice;
  List<JewelleryItem> _items = [];
  StreamSubscription<AuthEvent>? _eventsSub;
  Future<void>? _bootstrap;

  ShopUser? get user => _user;
  bool get ready => _ready;
  bool get signingIn => _signingIn;
  AuthProblem? get authProblem => _authProblem;
  String? get authDetail => _authDetail;
  BookNotice? get storageNotice => _storageNotice;
  List<JewelleryItem> get items => List.unmodifiable(_items);
  Day get today => Day.fromDateTime(_now());
  bool get needsGoogleSetup => auth.needsConfiguration;

  JewelleryItem? find(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> bootstrap() {
    return _bootstrap ??= _start();
  }

  Future<void> signIn() async {
    final blocked = needsGoogleSetup;
    if (blocked) {
      _authProblem = AuthProblem.notConfigured;
      notifyListeners();
      return;
    }
    _authProblem = null;
    _authDetail = null;
    _signingIn = true;
    notifyListeners();
    try {
      final next = await auth.signIn();
      await _adopt(next);
    } on AuthCancelled {
      // The sheet was dismissed. Leave the sign-in screen as it was.
    } on AuthFailure catch (error) {
      _authProblem = error.problem;
      _authDetail = error.detail;
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } on AuthFailure catch (error) {
      _authProblem = error.problem;
      _authDetail = error.detail;
      notifyListeners();
      return;
    }
    _clearSession();
  }

  Future<BookNotice?> saveItem(JewelleryItem item) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0 && _items[index].isSold) return BookNotice.soldLocked;
    final next = [..._items];
    if (index < 0) {
      next.insert(0, item);
    } else {
      next[index] = item;
    }
    return _commit(next);
  }

  Future<BookNotice?> markSold(
    String id, {
    required int soldCents,
    required Day soldOn,
  }) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    if (soldCents < 0) return BookNotice.priceRequired;
    if (soldOn > today) return BookNotice.futureSale;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return BookNotice.missing;
    if (_items[index].isSold) return BookNotice.alreadySold;
    final next = [..._items];
    next[index] = _items[index].markSold(on: soldOn, cents: soldCents);
    return _commit(next);
  }

  Future<BookNotice?> returnToStock(String id) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return BookNotice.missing;
    if (!_items[index].isSold) return BookNotice.stillInStock;
    final next = [..._items];
    next[index] = _items[index].returnToStock();
    return _commit(next);
  }

  Future<BookNotice?> deleteItem(String id) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final next = _items.where((item) => item.id != id).toList();
    if (next.length == _items.length) return BookNotice.missing;
    return _commit(next);
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    unawaited(auth.close());
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await auth.initialize();
      _eventsSub = auth.events.listen(_onAuthEvent);
      final restored = await auth.restore();
      if (restored != null) await _adopt(restored);
    } on AuthFailure catch (error) {
      _authProblem = error.problem;
      _authDetail = error.detail;
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  void _onAuthEvent(AuthEvent event) {
    switch (event) {
      case AuthSignedIn(:final user):
        unawaited(_adopt(user));
      case AuthSignedOut():
        _clearSession();
      case AuthFailed(:final problem, :final detail):
        _authProblem = problem;
        _authDetail = detail;
        _signingIn = false;
        notifyListeners();
    }
  }

  Future<void> _adopt(ShopUser next) async {
    final changed = _user?.id != next.id;
    _user = next;
    _authProblem = null;
    _authDetail = null;
    _signingIn = false;
    notifyListeners();
    if (changed) {
      _items = [];
      await _load(next.id);
    }
  }

  Future<void> _load(String userId) async {
    try {
      final loaded = await inventory.load(userId);
      if (_user?.id != userId) return;
      _items = loaded;
      _storageNotice = null;
    } catch (_) {
      if (_user?.id != userId) return;
      _items = [];
      _storageNotice = BookNotice.unreadable;
    }
    notifyListeners();
  }

  void _clearSession() {
    _user = null;
    _items = [];
    _storageNotice = null;
    _signingIn = false;
    notifyListeners();
  }

  BookNotice? _writable() {
    if (_user == null) return BookNotice.signInAgain;
    if (_storageNotice != null) return BookNotice.unreadableNoChange;
    return null;
  }

  Future<BookNotice?> _commit(List<JewelleryItem> next) async {
    final previous = _items;
    _items = next;
    notifyListeners();
    try {
      await inventory.save(_user!.id, _items);
      return null;
    } catch (_) {
      _items = previous;
      notifyListeners();
      return BookNotice.unsaved;
    }
  }
}
