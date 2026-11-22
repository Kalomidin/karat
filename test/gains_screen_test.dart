import 'package:flutter_test/flutter_test.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('week lists each currency gain, then the selected card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = KaratController(
      inventory: MemoryInventory(),
      auth: FakeAuth(
        restored: const ShopUser(
          id: 'ada',
          email: 'ada@atelier.test',
          name: 'Ada',
        ),
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await controller.bootstrap();
    await controller.saveItem(
      _piece(
        'dollar',
        'Dollar ring',
        dollarCurrencyId,
        5000,
        createdOn: const Day(2026, 11, 18),
      ),
    );
    await controller.markSold(
      'dollar',
      soldCents: 15000,
      soldOn: const Day(2026, 11, 18),
    );
    await controller.saveItem(
      _piece(
        'fresh',
        'Fresh band',
        dollarCurrencyId,
        1000,
        createdOn: const Day(2026, 11, 20),
      ),
    );
    await controller.saveItem(
      _piece('somoni', 'Somoni ring', somoniCurrencyId, 2000),
    );
    await controller.markSold(
      'somoni',
      soldCents: 5000,
      soldOn: const Day(2026, 11, 18),
    );

    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gains'));
    await tester.pumpAndSettle();

    expect(_amount(tester, 'week-gain-USD'), '+\$100');
    expect(_amount(tester, 'week-gain-TJS'), '+TJS30');
    expect(_amount(tester, 'week-gain-RUB'), '₽0');
    expect(_amount(tester, 'week-profit'), '+\$100');
    expect(_amount(tester, 'gold-sold'), '4 g');
    expect(find.byKey(const Key('gain-move-dollar-out')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-dollar-in')), findsNothing);
    expect(find.byKey(const Key('gain-move-fresh-in')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-somoni-out')), findsNothing);

    await tester.tap(find.byKey(const Key('gold-added')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gold-added-on')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-fresh-in')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-dollar-in')), findsOneWidget);
    expect(find.text('\$10'), findsOneWidget);
    expect(find.text('\$50'), findsOneWidget);
    expect(_amount(tester, 'week-profit'), '\$60');
    expect(find.text('Revenue'), findsNothing);
    expect(find.byKey(const Key('gain-move-dollar-out')), findsNothing);

    await tester.tap(find.byKey(const Key('gain-move-fresh-in')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mark-sold')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gold-sold')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gold-sold-on')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-dollar-out')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-dollar-in')), findsNothing);
    expect(find.byKey(const Key('gain-move-fresh-in')), findsNothing);
    expect(_amount(tester, 'week-profit'), '\$150');

    await tester.tap(find.byKey(const Key('week-gain-TJS')));
    await tester.pumpAndSettle();

    expect(_amount(tester, 'week-profit'), '+TJS30');
    expect(_amount(tester, 'gold-sold'), '4 g');
    expect(find.byKey(const Key('gold-sold-on')), findsNothing);
    expect(find.byKey(const Key('gain-move-somoni-out')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-dollar-out')), findsNothing);

    await tester.tap(find.byKey(const Key('gold-sold')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gain-move-somoni-out')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-fresh-in')), findsNothing);

    await tester.tap(find.byKey(const Key('gain-span-day')));
    await tester.pumpAndSettle();

    expect(_amount(tester, 'week-profit'), 'TJS0');
    expect(find.byKey(const Key('gain-move-somoni-out')), findsNothing);
    expect(
      find.text('Nothing came in or left in this period.'),
      findsOneWidget,
    );
  });

  testWidgets('a batch of added pieces is one row', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = KaratController(
      inventory: MemoryInventory(),
      auth: FakeAuth(
        restored: const ShopUser(
          id: 'ada',
          email: 'ada@atelier.test',
          name: 'Ada',
        ),
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await controller.bootstrap();
    await controller.saveItem(
      _piece(
        'band',
        'Batch band',
        dollarCurrencyId,
        1000,
        createdOn: const Day(2026, 11, 20),
      ),
      quantity: 2,
    );

    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gains'));
    await tester.pumpAndSettle();

    final group = controller.items.first.groupId;
    expect(find.byKey(Key('gain-count-$group')), findsOneWidget);
    expect(find.text('\$20'), findsOneWidget);
    expect(find.byKey(const Key('gain-move-band-in')), findsOneWidget);
    expect(find.text('8 g'), findsOneWidget);
  });

  testWidgets('a sold piece stays in the added quantity', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = KaratController(
      inventory: MemoryInventory(),
      auth: FakeAuth(
        restored: const ShopUser(
          id: 'ada',
          email: 'ada@atelier.test',
          name: 'Ada',
        ),
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await controller.bootstrap();
    await controller.saveItem(
      _piece(
        'band',
        'Batch band',
        dollarCurrencyId,
        1000,
        createdOn: const Day(2026, 11, 20),
      ),
      quantity: 2,
    );
    final sold = controller.items.last;
    await controller.markSold(
      sold.id,
      soldCents: 1500,
      soldOn: const Day(2026, 11, 21),
    );

    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gains'));
    await tester.pumpAndSettle();

    final unsold = controller.items.firstWhere((item) => !item.isSold);
    expect(find.byKey(Key('gain-count-${unsold.groupId}')), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.text('\$20'), findsOneWidget);
    expect(find.byKey(Key('gain-move-${unsold.id}-in')), findsOneWidget);
    expect(find.byKey(Key('gain-move-${sold.id}-out')), findsOneWidget);
  });

  testWidgets('added pieces with an empty group id stay separate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = KaratController(
      inventory: MemoryInventory()
        ..books['ada'] = [
          _piece(
            'loose-a',
            'Loose band',
            dollarCurrencyId,
            1000,
            createdOn: const Day(2026, 11, 20),
          ),
          _piece(
            'loose-b',
            'Loose band',
            dollarCurrencyId,
            1000,
            createdOn: const Day(2026, 11, 20),
          ),
        ],
      auth: FakeAuth(
        restored: const ShopUser(
          id: 'ada',
          email: 'ada@atelier.test',
          name: 'Ada',
        ),
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await controller.bootstrap();

    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gains'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gain-move-loose-a-in')), findsOneWidget);
    expect(find.byKey(const Key('gain-move-loose-b-in')), findsOneWidget);
    expect(find.text('× 2'), findsNothing);
  });
}

String _amount(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

JewelleryItem _piece(
  String id,
  String name,
  String currencyId,
  int costCents, {
  Day createdOn = const Day(2026, 11, 2),
}) {
  return JewelleryItem(
    id: id,
    name: name,
    kind: PieceKind.ring,
    metal: Metal.gold,
    purity: '18K',
    weightGrams: 4,
    currencyId: currencyId,
    costCents: costCents,
    notes: '',
    createdOn: createdOn,
  );
}
