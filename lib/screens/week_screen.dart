import 'package:karat/domain/currency.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/week_profit.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key, required this.controller});

  final KaratController controller;

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late Week _week = Week.of(widget.controller.today);
  String? _detailCurrencyId;

  String _detailId(List<ShopCurrency> currencies) {
    final chosen = _detailCurrencyId;
    if (chosen != null && currencies.any((item) => item.id == chosen)) {
      return chosen;
    }
    if (currencies.isNotEmpty) return currencies.first.id;
    return dollarCurrencyId;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final current = Week.of(widget.controller.today);
        final onCurrent = _week == current;
        final weekItems = widget.controller.items;
        final text = AppText.of(context);
        final language = Localizations.localeOf(context).languageCode;
        final currencies = widget.controller.currencies.isEmpty
            ? defaultCurrencies
            : widget.controller.currencies;
        final detailId = _detailId(currencies);
        final gains = WeekProfit(week: _week, items: weekItems);
        final profit = WeekProfit(
          week: _week,
          items: weekItems
              .where((item) => item.currencyId == detailId)
              .toList(),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _CurrencyGains(
              currencies: currencies,
              gains: gains,
              selectedId: detailId,
              onSelected: (id) => setState(() => _detailCurrencyId = id),
            ),
            const SizedBox(height: 12),
            _WeekCard(
              week: _week,
              profit: profit,
              currencyId: detailId,
              isCurrent: onCurrent,
              text: text,
              languageCode: language,
              onPrevious: () => setState(() => _week = _week.previous()),
              onNext: onCurrent
                  ? null
                  : () => setState(() => _week = _week.next()),
            ),
            const SizedBox(height: 18),
            if (profit.sales.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  text.noSalesThisWeek,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: KaratColors.ink.withValues(alpha: 0.72),
                  ),
                ),
              )
            else
              ...profit.sales.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SaleRow(
                    item: item,
                    text: text,
                    languageCode: language,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CurrencyGains extends StatelessWidget {
  const _CurrencyGains({
    required this.currencies,
    required this.gains,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ShopCurrency> currencies;
  final WeekProfit gains;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < currencies.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _GainTile(
              currency: currencies[index],
              profitCents: gains.totalFor(currencies[index].id).profitCents,
              selected: currencies[index].id == selectedId,
              onTap: () => onSelected(currencies[index].id),
            ),
          ),
        ],
      ],
    );
  }
}

class _GainTile extends StatelessWidget {
  const _GainTile({
    required this.currency,
    required this.profitCents,
    required this.selected,
    required this.onTap,
  });

  final ShopCurrency currency;
  final int profitCents;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amount = formatCents(
      profitCents,
      signed: true,
      currencyId: currency.id,
    );
    return Material(
      color: KaratColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? KaratColors.goldDeep : KaratColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currency.code,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: KaratColors.goldDeep,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                key: Key('week-gain-${currency.code}'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: profitCents < 0 ? KaratColors.loss : KaratColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.profit,
    required this.currencyId,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.text,
    required this.languageCode,
  });

  final Week week;
  final WeekProfit profit;
  final String currencyId;
  final bool isCurrent;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final AppText text;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final ink = profit.profitCents < 0
        ? KaratColors.lossSoft
        : KaratColors.profit;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KaratColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: text.previousWeek,
                  onPressed: onPrevious,
                  color: KaratColors.cream,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isCurrent ? text.thisWeek : text.week,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: KaratColors.gold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatWeekRange(week.start, languageCode: languageCode),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: KaratColors.cream),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: text.nextWeek,
                  onPressed: onNext,
                  color: KaratColors.cream,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.mondayToSunday,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: KaratColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatCents(
                        profit.profitCents,
                        signed: true,
                        currencyId: currencyId,
                      ),
                      key: const Key('week-profit'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: profit.profitCents == 0
                            ? KaratColors.cream
                            : ink,
                      ),
                    ),
                  ),
                  Text(
                    text.profit,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: KaratColors.cream),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Stat(
                        label: text.revenue,
                        value: formatCents(
                          profit.revenueCents,
                          currencyId: currencyId,
                        ),
                      ),
                      _Stat(
                        label: text.cost,
                        value: formatCents(
                          profit.costCents,
                          currencyId: currencyId,
                        ),
                      ),
                      _Stat(label: text.pieces, value: '${profit.pieceCount}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: KaratColors.cream),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: KaratColors.cream.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({
    required this.item,
    required this.text,
    required this.languageCode,
  });

  final JewelleryItem item;
  final AppText text;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final profit = item.profitCents ?? 0;
    return Material(
      color: KaratColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KaratColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text.soldLine(
                      formatDay(item.soldOn!, languageCode: languageCode),
                      formatCents(item.soldCents!, currencyId: item.currencyId),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: KaratColors.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatCents(profit, signed: true, currencyId: item.currencyId),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: profit < 0 ? KaratColors.loss : KaratColors.goldDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
