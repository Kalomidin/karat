import 'package:karat/domain/currency.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

class CurrencyMenuButton extends StatelessWidget {
  const CurrencyMenuButton({
    super.key,
    required this.currencies,
    required this.selectedId,
    required this.onSelected,
    this.compact = true,
  });

  final List<ShopCurrency> currencies;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final options = currencies.isEmpty ? defaultCurrencies : currencies;
    final selected = _selected(options);
    final closed = compact ? selected.code : text.currencyName(selected.code);
    return PopupMenuButton<String>(
      key: Key(compact ? 'open-currency' : 'piece-currency'),
      tooltip: text.currencyLabel,
      initialValue: selected.id,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          for (final currency in options)
            PopupMenuItem(
              key: Key('currency-${currency.code}'),
              value: currency.id,
              child: Text(text.currencyName(currency.code)),
            ),
        ];
      },
      child: compact ? _CompactChoice(closed) : _FieldChoice(closed),
    );
  }

  ShopCurrency _selected(List<ShopCurrency> options) {
    for (final currency in options) {
      if (currency.id == selectedId) return currency;
    }
    return options.first;
  }
}

class _CompactChoice extends StatelessWidget {
  const _CompactChoice(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: KaratColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _FieldChoice extends StatelessWidget {
  const _FieldChoice(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
