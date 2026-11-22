import 'package:flutter_test/flutter_test.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/l10n/locale_controller.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('a registered piece can be marked sold and counted this week', (
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
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing in stock yet.'), findsOneWidget);
    await tester.tap(find.text('New piece'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('piece-name')),
      'Oval sapphire ring',
    );
    await tester.ensureVisible(find.byKey(const Key('piece-weight')));
    await tester.enterText(find.byKey(const Key('piece-weight')), '4.2');
    await tester.ensureVisible(find.byKey(const Key('piece-cost')));
    await tester.enterText(find.byKey(const Key('piece-cost')), '50');
    await tester.tap(find.byKey(const Key('save-piece')));
    await tester.pumpAndSettle();

    expect(find.text('Oval sapphire ring'), findsOneWidget);
    await tester.tap(find.text('Oval sapphire ring'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mark-sold')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sale-price')), '150');
    await tester.tap(find.byKey(const Key('record-sale')));
    await tester.pumpAndSettle();

    expect(find.text('+\$100.00'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('week-profit')), findsOneWidget);
    expect(find.text('+\$100.00'), findsWidgets);
    expect(find.text('Oval sapphire ring'), findsOneWidget);
    expect(find.text('No sales this week.'), findsNothing);
  });

  testWidgets('the language switch changes the stock book into Russian', (
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
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    expect(find.text('New piece'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lang-ru')));
    await tester.pumpAndSettle();

    expect(find.text('Новое изделие'), findsOneWidget);
    expect(find.text('Наличие'), findsOneWidget);
    expect(find.text('Неделя'), findsOneWidget);
  });
}
