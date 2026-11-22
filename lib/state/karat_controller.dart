import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/currency_api.dart';
import 'package:karat/data/currency_store.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/data/item_api.dart';
import 'package:karat/data/profile_store.dart';
import 'package:karat/domain/book_notice.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/stock_query.dart';

class KaratController extends ChangeNotifier {
  KaratController({
    required this.inventory,
    required this.auth,
    this.profiles,
    this.itemsApi,
    this.currenciesApi,
    this.currencyStore,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final InventoryRepository inventory;
  final AuthClient auth;
  final ProfileStore? profiles;
  final ItemApi? itemsApi;
  final CurrencyApi? currenciesApi;
  final CurrencyStore? currencyStore;
  final DateTime Function() _now;

  ShopUser? _user;
  bool _ready = false;
  bool _signingIn = false;
  AuthProblem? _authProblem;
  String? _authDetail;
  BookNotice? _storageNotice;
  List<JewelleryItem> _items = [];
  List<ShopCurrency> _currencies = defaultCurrencies;
  String _shopCurrencyId = dollarCurrencyId;
  StreamSubscription<AuthEvent>? _eventsSub;
  Future<void>? _bootstrap;

  ShopUser? get user => _user;
  bool get ready => _ready;
  bool get signingIn => _signingIn;
  AuthProblem? get authProblem => _authProblem;
  String? get authDetail => _authDetail;
  BookNotice? get storageNotice => _storageNotice;
  List<JewelleryItem> get items => List.unmodifiable(_items);
  List<ShopCurrency> get currencies => List.unmodifiable(_currencies);
  String get shopCurrencyId => _shopCurrencyId;

  Future<void> chooseCurrency(String id) async {
    if (_currencies.isNotEmpty && !_currencies.any((item) => item.id == id)) {
      return;
    }
    _shopCurrencyId = id;
    notifyListeners();
    await currencyStore?.write(id);
  }

  Day get today => Day.fromDateTime(_now());
  bool get needsGoogleSetup => auth.needsConfiguration;

  Future<String?> idToken() => auth.idToken();

  Future<void> updateAccount({
    required String name,
    required String shopName,
    String? photoUrl,
  }) async {
    final current = _user;
    if (current == null) return;
    final trimmedName = name.trim();
    final trimmedShop = shopName.trim();
    final nextPhoto = photoUrl ?? current.photoUrl;
    _user = ShopUser(
      id: current.id,
      email: current.email,
      name: trimmedName.isEmpty ? null : trimmedName,
      photoUrl: nextPhoto,
      shopName: trimmedShop,
    );
    notifyListeners();
    final storedPhoto = nextPhoto ?? '';
    final localPhoto = storedPhoto.startsWith('http') ? '' : storedPhoto;
    await profiles?.save(
      current.id,
      ShopProfile(
        name: trimmedName,
        shopName: trimmedShop,
        photoPath: localPhoto,
      ),
    );
  }

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

  Future<BookNotice?> saveItem(JewelleryItem item, {int quantity = 1}) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      if (_items[index].isSold) return BookNotice.soldLocked;
      return _saveExisting(item, quantity);
    }
    if (quantity < 1 || quantity > maxPieceQuantity) {
      return BookNotice.updateFailed;
    }
    final stored = await _createRemote(_batched(item), quantity);
    if (stored == null) return BookNotice.updateFailed;
    return _commit([...stored, ..._items]);
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
    final sold = _items[index].markSold(on: soldOn, cents: soldCents);
    final stored = await _applyRemote(
      sold,
      (api, token) => api.sell(token, sold),
    );
    if (stored == null) return BookNotice.updateFailed;
    final next = [..._items];
    next[index] = stored;
    return _commit(next);
  }

  Future<BookNotice?> returnToStock(String id) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return BookNotice.missing;
    if (!_items[index].isSold) return BookNotice.stillInStock;
    final returned = _items[index].returnToStock();
    final stored = await _applyRemote(
      returned,
      (api, token) => api.returnToStock(token, id),
    );
    if (stored == null) return BookNotice.updateFailed;
    final next = [..._items];
    next[index] = stored;
    return _commit(next);
  }

  Future<BookNotice?> deleteItem(String id) async {
    final blocked = _writable();
    if (blocked != null) return blocked;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return BookNotice.missing;
    final removed = await _deleteRemote(id);
    if (!removed) return BookNotice.updateFailed;
    final next = [..._items]..removeAt(index);
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
      final saved = await currencyStore?.read();
      if (saved != null && saved.isNotEmpty) _shopCurrencyId = saved;
      await _loadCurrencies();
      _keepKnownCurrency();
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
    final saved = await profiles?.load(next.id);
    _user = applyProfile(next, saved);
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
    final remote = await _fetchRemote();
    if (_user?.id != userId) return;
    if (remote != null) {
      _items = remote;
      _storageNotice = null;
      try {
        await inventory.save(userId, remote);
      } catch (_) {
        // The screen can still show the server book if the cache write fails.
      }
      notifyListeners();
      return;
    }
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

  Future<void> _loadCurrencies() async {
    final api = currenciesApi;
    if (api == null) return;
    try {
      final rows = await api.list();
      if (rows.isEmpty) return;
      _currencies = rows;
    } catch (_) {
      _currencies = defaultCurrencies;
    }
  }

  void _keepKnownCurrency() {
    if (_currencies.any((item) => item.id == _shopCurrencyId)) return;
    for (final currency in _currencies) {
      if (currency.code == 'USD') {
        _shopCurrencyId = currency.id;
        return;
      }
    }
    if (_currencies.isNotEmpty) _shopCurrencyId = _currencies.first.id;
  }

  Future<BookNotice?> _saveExisting(JewelleryItem edited, int quantity) async {
    if (quantity < 1 || quantity > maxPieceQuantity) {
      return BookNotice.updateFailed;
    }
    final original = _items.firstWhere((item) => item.id == edited.id);
    final mates = original.groupId.trim().isEmpty
        ? [original]
        : [
            for (final item in _items)
              if (!item.isSold && sameBatch(item, original)) item,
          ];
    final others =
        [
          for (final item in mates)
            if (item.id != edited.id) item,
        ]..sort((a, b) {
          final byDay = a.createdOn.compareTo(b.createdOn);
          if (byDay != 0) return byDay;
          return a.id.compareTo(b.id);
        });
    final grouped = _batched(edited);
    final keep = [
      grouped,
      for (final item in others.take(quantity - 1)) item.withDetails(grouped),
    ];
    final drop = others.skip(quantity - 1).toList();
    final storedKept = <JewelleryItem>[];
    for (final item in keep) {
      final stored = await _storeRemote(item);
      if (stored == null) return BookNotice.updateFailed;
      storedKept.add(stored);
    }
    for (final item in drop) {
      final removed = await _deleteRemote(item.id);
      if (!removed) return BookNotice.updateFailed;
    }
    final extra = quantity - mates.length;
    final created = extra <= 0
        ? <JewelleryItem>[]
        : await _createRemote(
            grouped.asNew(id: newItemId(), createdOn: today),
            extra,
          );
    if (created == null) return BookNotice.updateFailed;
    final keptById = {for (final item in storedKept) item.id: item};
    final dropped = {for (final item in drop) item.id};
    return _commit([
      ...created,
      for (final item in _items)
        if (!dropped.contains(item.id)) keptById[item.id] ?? item,
    ]);
  }

  Future<JewelleryItem?> _storeRemote(JewelleryItem item) async {
    final api = itemsApi;
    if (api == null) return item;
    try {
      final token = await auth.idToken();
      if (token == null || token.isEmpty) return null;
      return item.withServerIdentity(await api.update(token, item));
    } catch (_) {
      return null;
    }
  }

  JewelleryItem _batched(JewelleryItem item) {
    if (item.groupId.isNotEmpty) return item;
    return item.withGroup(newGroupId());
  }

  Future<List<JewelleryItem>?> _createRemote(
    JewelleryItem item,
    int quantity,
  ) async {
    final api = itemsApi;
    if (api == null) {
      return [
        for (var i = 0; i < quantity; i++)
          i == 0 ? item : item.withId(newItemId()),
      ];
    }
    try {
      final token = await auth.idToken();
      if (token == null || token.isEmpty) return null;
      final remote = await api.create(token, item, quantity: quantity);
      if (remote.isEmpty) return null;
      return [for (final row in remote) item.withServerIdentity(row)];
    } catch (_) {
      return null;
    }
  }

  Future<JewelleryItem?> _applyRemote(
    JewelleryItem item,
    Future<JewelleryItem> Function(ItemApi api, String token) call,
  ) async {
    final api = itemsApi;
    if (api == null) return item;
    try {
      final token = await auth.idToken();
      if (token == null || token.isEmpty) return null;
      return item.withServerIdentity(await call(api, token));
    } catch (_) {
      return null;
    }
  }

  Future<bool> _deleteRemote(String id) async {
    final api = itemsApi;
    if (api == null) return true;
    try {
      final token = await auth.idToken();
      if (token == null || token.isEmpty) return false;
      await api.delete(token, id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<JewelleryItem>?> _fetchRemote() async {
    final api = itemsApi;
    if (api == null) return null;
    try {
      final token = await auth.idToken();
      if (token == null || token.isEmpty) return null;
      return await api.list(token);
    } catch (_) {
      return null;
    }
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
