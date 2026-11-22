import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/inventory_repository.dart';
import 'package:karat/domain/book_notice.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/money.dart';
import 'package:karat/domain/stock_query.dart';
import 'package:karat/domain/week_profit.dart';
import 'package:karat/format.dart';
import 'package:karat/state/karat_controller.dart';

import 'support/fakes.dart';

void main() {
  test('money is a whole number of the currency', () {
    expect(parseCents('50'), 5000);
    expect(parseCents('1,200'), 120000);
    expect(parseCents('\$80'), 8000);
    expect(parseCents(''), isNull);
    expect(parseCents('-1'), isNull);
    expect(parseCents('50.5'), isNull);
    expect(parseCents('12.00'), isNull);
    expect(formatCents(10000, signed: true), '+\$100');
    expect(formatCents(-2000, signed: true), '-\$20');
    expect(formatCents(5000, currencyId: somoniCurrencyId), 'TJS50');
  });

  test('weeks run Monday through Sunday', () {
    expect(Day(2026, 11, 21).weekStart, const Day(2026, 11, 16));
    expect(Day(2026, 11, 22).weekStart, const Day(2026, 11, 16));
    expect(Day(2026, 11, 23).weekStart, const Day(2026, 11, 23));
    expect(
      Week.of(const Day(2026, 11, 21)).contains(const Day(2026, 11, 16)),
      isTrue,
    );
    expect(
      Week.of(const Day(2026, 11, 21)).contains(const Day(2026, 11, 23)),
      isFalse,
    );
  });

  test('weekly profit counts only sales in that week', () {
    final week = Week.of(const Day(2026, 11, 21));
    final items = [
      _piece(id: 'sold', soldOn: const Day(2026, 11, 18), soldCents: 15000),
      _piece(
        id: 'loss',
        costCents: 8000,
        soldOn: const Day(2026, 11, 22),
        soldCents: 5000,
      ),
      _piece(
        id: 'other-week',
        soldOn: const Day(2026, 11, 10),
        soldCents: 9000,
      ),
      _piece(id: 'stock'),
    ];
    final profit = WeekProfit(week: week, items: items);
    expect(profit.pieceCount, 2);
    expect(profit.revenueCents, 20000);
    expect(profit.costCents, 13000);
    expect(profit.profitCents, 7000);
    expect(profit.sales.map((item) => item.id), ['loss', 'sold']);
  });

  test('stock view filters by sale state and search', () {
    final items = [
      _piece(id: 'ring', name: 'Oval sapphire ring'),
      _piece(
        id: 'chain',
        name: 'Trace chain',
        soldOn: const Day(2026, 11, 18),
        soldCents: 4000,
      ),
    ];
    expect(stockView(items, sold: false).map((item) => item.id), ['ring']);
    expect(stockView(items, sold: true).map((item) => item.id), ['chain']);
    expect(stockView(items, sold: false, query: 'sapphire').single.id, 'ring');
  });

  test('a piece survives a json round trip', () {
    final item = _piece(
      id: 'ring',
      soldOn: const Day(2026, 11, 18),
      soldCents: 15000,
    );
    final decoded = JewelleryItem.fromJson(
      (jsonDecode(jsonEncode(item.toJson())) as Map).cast<String, Object?>(),
    );
    expect(decoded.profitCents, 10000);
    expect(decoded.soldOn, const Day(2026, 11, 18));
  });

  test('marking a piece sold updates that week and the saved book', () async {
    final inventory = MemoryInventory();
    final first = _controller(inventory);
    await first.bootstrap();
    final item = _piece(id: 'ring');
    expect(await first.saveItem(item), isNull);
    expect(
      await first.markSold(
        'ring',
        soldCents: 15000,
        soldOn: const Day(2026, 11, 21),
      ),
      isNull,
    );
    expect(
      await first.markSold(
        'ring',
        soldCents: 16000,
        soldOn: const Day(2026, 11, 21),
      ),
      BookNotice.alreadySold,
    );
    expect(
      await first.markSold(
        'other',
        soldCents: 100,
        soldOn: const Day(2026, 11, 22),
      ),
      BookNotice.futureSale,
    );

    final reopened = _controller(inventory);
    await reopened.bootstrap();
    final stored = reopened.find('ring');
    expect(stored?.isSold, isTrue);
    expect(
      WeekProfit(
        week: Week.of(reopened.today),
        items: reopened.items,
      ).profitCents,
      10000,
    );

    expect(await reopened.returnToStock('ring'), isNull);
    expect(reopened.find('ring')?.isSold, isFalse);
    expect(await reopened.deleteItem('ring'), isNull);
    expect(reopened.items, isEmpty);
  });

  test('a failed save leaves the book unchanged', () async {
    final controller = KaratController(
      inventory: _FailingInventory(),
      auth: FakeAuth(
        restored: const ShopUser(id: 'ada', email: 'ada@atelier.test'),
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await controller.bootstrap();
    final error = await controller.saveItem(_piece(id: 'ring'));
    expect(error, BookNotice.unsaved);
    expect(controller.items, isEmpty);
  });
}

KaratController _controller(InventoryRepository inventory) {
  return KaratController(
    inventory: inventory,
    auth: FakeAuth(
      restored: const ShopUser(
        id: 'ada',
        email: 'ada@atelier.test',
        name: 'Ada',
      ),
    ),
    now: () => DateTime(2026, 11, 21),
  );
}

class _FailingInventory implements InventoryRepository {
  @override
  Future<List<JewelleryItem>> load(String userId) async => [];

  @override
  Future<void> save(String userId, List<JewelleryItem> items) async {
    throw StateError('disk');
  }
}

JewelleryItem _piece({
  required String id,
  String name = 'Oval sapphire ring',
  int costCents = 5000,
  Day? soldOn,
  int? soldCents,
}) {
  return JewelleryItem(
    id: id,
    name: name,
    kind: PieceKind.ring,
    metal: Metal.gold,
    purity: '18K',
    weightGrams: 4.2,
    costCents: costCents,
    notes: '',
    createdOn: const Day(2026, 11, 2),
    soldOn: soldOn,
    soldCents: soldCents,
  );
}
