class ShopCurrency {
  const ShopCurrency({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code;
  final String name;
}

const dollarCurrencyId = '11111111-1111-4111-8111-111111111111';
const rubleCurrencyId = '22222222-2222-4222-8222-222222222222';
const somoniCurrencyId = '33333333-3333-4333-8333-333333333333';

const defaultCurrencies = [
  ShopCurrency(id: dollarCurrencyId, code: 'USD', name: 'Dollar'),
  ShopCurrency(id: rubleCurrencyId, code: 'RUB', name: 'Ruble'),
  ShopCurrency(id: somoniCurrencyId, code: 'TJS', name: 'Somoni'),
];

String currencyCode(String id) {
  for (final currency in defaultCurrencies) {
    if (currency.id == id) return currency.code;
  }
  return 'USD';
}

String currencySymbol(String code) {
  return switch (code) {
    'USD' => r'$',
    'RUB' => '₽',
    'TJS' => 'TJS',
    _ => code,
  };
}

String currencySymbolFor(String currencyId) =>
    currencySymbol(currencyCode(currencyId));
