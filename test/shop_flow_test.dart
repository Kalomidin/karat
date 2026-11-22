import 'package:flutter_test/flutter_test.dart';
import 'package:karat/app.dart';
import 'package:karat/auth/auth_client.dart';
import 'package:karat/data/item_api.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
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
    await tester.tap(find.byKey(const Key('open-account')));
    await tester.pumpAndSettle();
    expect(find.text('ada@atelier.test'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('account-shop')), 'Atelier');
    await tester.tap(find.byKey(const Key('save-account')));
    await tester.pumpAndSettle();
    expect(find.text('Atelier'), findsOneWidget);

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

    expect(find.text('+\$100'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gains'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('week-profit')), findsOneWidget);
    expect(find.text('+\$100'), findsWidgets);
    expect(find.text('Oval sapphire ring'), findsOneWidget);
    expect(find.text('No sales in this period.'), findsNothing);
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
    await tester.tap(find.byKey(const Key('open-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lang-ru')));
    await tester.pumpAndSettle();

    expect(find.text('Новое изделие'), findsOneWidget);
    expect(find.text('Наличие'), findsOneWidget);
    expect(find.text('Прибыль'), findsOneWidget);
  });

  testWidgets('the header shows one currency and a tap changes it', (
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

    expect(find.text('USD'), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-currency')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('currency-TJS')));
    await tester.pumpAndSettle();

    expect(find.text('TJS'), findsOneWidget);
    await tester.tap(find.text('New piece'));
    await tester.pumpAndSettle();
    expect(find.text('Somoni'), findsOneWidget);
    expect(find.text('TJS '), findsOneWidget);
  });

  testWidgets('a rejected sale says the update failed', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = KaratController(
      inventory: MemoryInventory(),
      itemsApi: _RejectingItems(),
      auth: FakeAuth(
        restored: const ShopUser(id: 'ada', email: 'ada@atelier.test'),
        token: 'token',
      ),
      now: () => DateTime(2026, 11, 21),
    );
    await tester.pumpWidget(
      KaratApp(controller: controller, locales: LocaleController()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Server ring'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mark-sold')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sale-price')), '150');
    await tester.tap(find.byKey(const Key('record-sale')));
    await tester.pumpAndSettle();

    expect(find.text('Update failed'), findsOneWidget);
    expect(find.byKey(const Key('record-sale')), findsOneWidget);
  });

  testWidgets('a quantity of matching pieces shows as one card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
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

    await tester.tap(find.text('New piece'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('piece-name')), 'Plain band');
    await tester.ensureVisible(find.byKey(const Key('piece-quantity')));
    await tester.enterText(find.byKey(const Key('piece-quantity')), '4');
    await tester.pump();
    expect(find.text('Weight each'), findsOneWidget);
    expect(find.text('Cost each'), findsOneWidget);
    expect(find.text('Save 4 pieces'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('piece-weight')));
    await tester.enterText(find.byKey(const Key('piece-weight')), '2');
    await tester.ensureVisible(find.byKey(const Key('piece-cost')));
    await tester.enterText(find.byKey(const Key('piece-cost')), '40');
    await tester.tap(find.byKey(const Key('save-piece')));
    await tester.pumpAndSettle();

    expect(controller.items, hasLength(4));
    expect(find.text('Plain band'), findsOneWidget);
    expect(find.text('× 4'), findsOneWidget);
    await tester.tap(find.text('Plain band'));
    await tester.pumpAndSettle();
    expect(find.text('4 in stock'), findsOneWidget);
  });
}

class _RejectingItems extends ItemApi {
  _RejectingItems() : super(apiBase: 'http://127.0.0.1');

  @override
  Future<List<JewelleryItem>> list(String idToken) async {
    return [
      JewelleryItem(
        id: 'ring',
        name: 'Server ring',
        kind: PieceKind.ring,
        metal: Metal.gold,
        purity: '18K',
        weightGrams: 3,
        currencyId: dollarCurrencyId,
        costCents: 5000,
        notes: '',
        createdOn: const Day(2026, 11, 2),
      ),
    ];
  }

  @override
  Future<JewelleryItem> sell(String idToken, JewelleryItem item) {
    throw const ItemApiException();
  }
}
