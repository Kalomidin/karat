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
      _piece('dollar', 'Dollar ring', dollarCurrencyId, 5000),
    );
    await controller.markSold(
      'dollar',
      soldCents: 15000,
      soldOn: const Day(2026, 11, 18),
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
    expect(find.text('Dollar ring'), findsOneWidget);
    expect(find.text('Somoni ring'), findsNothing);

    await tester.tap(find.byKey(const Key('week-gain-TJS')));
    await tester.pumpAndSettle();

    expect(_amount(tester, 'week-profit'), '+TJS30');
    expect(find.text('Somoni ring'), findsOneWidget);
    expect(find.text('Dollar ring'), findsNothing);

    await tester.tap(find.byKey(const Key('gain-span-day')));
    await tester.pumpAndSettle();

    expect(_amount(tester, 'week-profit'), 'TJS0');
    expect(find.text('Somoni ring'), findsNothing);
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}

String _amount(WidgetTester tester, String key) {
  return tester.widget<Text>(find.byKey(Key(key))).data!;
}

JewelleryItem _piece(String id, String name, String currencyId, int costCents) {
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
    createdOn: const Day(2026, 11, 2),
  );
}
