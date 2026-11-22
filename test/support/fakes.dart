import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/domain/jewellery_item.dart';

class MemoryInventory implements InventoryRepository {
  final Map<String, List<JewelleryItem>> books = {};

  @override
  Future<List<JewelleryItem>> load(String userId) async {
    return List<JewelleryItem>.of(books[userId] ?? const []);
  }

  @override
  Future<void> save(String userId, List<JewelleryItem> items) async {
    books[userId] = List<JewelleryItem>.of(items);
  }
}

class FakeAuth implements AuthClient {
  FakeAuth({this.restored, this.token});

  ShopUser? restored;
  String? token;

  @override
  bool get needsConfiguration => false;

  @override
  Stream<AuthEvent> get events => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<ShopUser?> restore() async => restored;

  @override
  Future<ShopUser> signIn() async {
    final user = restored;
    if (user == null) throw const AuthFailure(AuthProblem.failed);
    return user;
  }

  @override
  Future<String?> idToken() async => token;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> close() async {}
}
