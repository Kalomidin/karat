import 'package:flutter_test/flutter_test.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('stock can be narrowed by type and grams', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inventory = MemoryInventory()
      ..books['ada'] = [
        _piece(id: 'ring', name: 'Oval sapphire ring', grams: 4.2),
        _piece(
          id: 'chain',
          name: 'Trace chain',
          kind: PieceKind.necklace,
          grams: 9,
        ),
        _piece(id: 'band', name: 'Plain band', purity: '585', grams: 2),
        _piece(id: 'hoop', name: 'Small hoop', purity: '375', grams: 1.5),
        _piece(
          id: 'sold-band',
          name: 'Sold band',
          purity: '585',
          grams: 10,
          sold: true,
        ),
      ];
    final controller = KaratController(
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
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oval sapphire ring'), findsOneWidget);
    expect(find.text('Trace chain'), findsOneWidget);
    expect(find.text('750 13.2 g · 585 2 g · 375 1.5 g'), findsOneWidget);
    expect(find.byKey(const Key('stock-grams')), findsNothing);

    await tester.tap(find.byKey(const Key('stock-filter')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('stock-grams')), '9');
    await tester.tap(find.byKey(const Key('stock-filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Trace chain'), findsOneWidget);
    expect(find.text('Oval sapphire ring'), findsNothing);

    await tester.tap(find.byKey(const Key('stock-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stock-filter-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Oval sapphire ring'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stock-type-necklace')));
    await tester.tap(find.byKey(const Key('stock-filter-apply')));
    await tester.pumpAndSettle();

    expect(find.text('Trace chain'), findsOneWidget);
    expect(find.text('Oval sapphire ring'), findsNothing);
  });

  testWidgets('matching unsold pieces share one card', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inventory = MemoryInventory()
      ..books['ada'] = [
        _piece(
          id: 'band-a',
          name: 'Plain band',
          purity: '585',
          grams: 2,
          groupId: 'batch-bands',
        ),
        _piece(
          id: 'band-b',
          name: 'Plain band',
          purity: '585',
          grams: 2,
          groupId: 'batch-bands',
        ),
        _piece(
          id: 'band-sold',
          name: 'Plain band',
          purity: '585',
          grams: 2,
          sold: true,
        ),
        _piece(id: 'other', name: 'Other ring', purity: '585', grams: 3),
      ];
    final controller = KaratController(
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
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plain band'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.text('Other ring'), findsOneWidget);

    await tester.tap(find.text('Plain band'));
    await tester.pumpAndSettle();
    expect(find.text('2 in stock'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sold'));
    await tester.pumpAndSettle();
    expect(find.text('Plain band'), findsOneWidget);
    expect(find.text('× 2'), findsNothing);
  });

  testWidgets('pieces with an empty group id stay on their own cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final inventory = MemoryInventory()
      ..books['ada'] = [
        _piece(id: 'loose-a', name: 'Loose band', purity: '585', grams: 2),
        _piece(id: 'loose-b', name: 'Loose band', purity: '585', grams: 2),
      ];
    final controller = KaratController(
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
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loose band'), findsNWidgets(2));
    expect(find.text('× 2'), findsNothing);
  });
}

JewelleryItem _piece({
  required String id,
  required String name,
  PieceKind kind = PieceKind.ring,
  String purity = '750',
  required double grams,
  String groupId = '',
  bool sold = false,
}) {
  return JewelleryItem(
    id: id,
    name: name,
    kind: kind,
    metal: Metal.gold,
    purity: purity,
    weightGrams: grams,
    costCents: 5000,
    notes: '',
    groupId: groupId,
    createdOn: const Day(2026, 11, 2),
    soldOn: sold ? const Day(2026, 11, 10) : null,
    soldCents: sold ? 8000 : null,
  );
}
