import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/week_profit.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

class GainsScreen extends StatefulWidget {
  const GainsScreen({super.key, required this.controller});

  final KaratController controller;

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen> {
  GainSpan _span = GainSpan.week;
  late GainPeriod _period = GainPeriod.around(
    GainSpan.week,
    widget.controller.today,
  );
  String? _detailCurrencyId;

  String _detailId(List<ShopCurrency> currencies) {
    final chosen = _detailCurrencyId;
    if (chosen != null && currencies.any((item) => item.id == chosen)) {
      return chosen;
    }
    if (currencies.isNotEmpty) return currencies.first.id;
    return dollarCurrencyId;
  }

  void _chooseSpan(GainSpan span) {
    final today = widget.controller.today;
    setState(() {
      _span = span;
      if (span == GainSpan.custom) {
        _period = GainPeriod(
          _period.start,
          today < _period.end ? today : _period.end,
        );
      } else {
        _period = GainPeriod.around(span, today);
      }
    });
  }

  Future<void> _pickCustom() async {
    final today = widget.controller.today;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today.date,
      initialDateRange: DateTimeRange(
        start: _period.start.date,
        end: _period.end.date.isAfter(today.date)
            ? today.date
            : _period.end.date,
      ),
    );
    if (range == null || !mounted) return;
    setState(() {
      _span = GainSpan.custom;
      _period = GainPeriod(
        Day.fromDateTime(range.start),
        Day.fromDateTime(range.end),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final today = widget.controller.today;
        final onCurrent = _period.contains(today);
        final items = widget.controller.items;
        final text = AppText.of(context);
        final language = Localizations.localeOf(context).languageCode;
        final currencies = widget.controller.currencies.isEmpty
            ? defaultCurrencies
            : widget.controller.currencies;
        final detailId = _detailId(currencies);
        final gains = PeriodProfit(period: _period, items: items);
        final profit = PeriodProfit(
          period: _period,
          items: items.where((item) => item.currencyId == detailId).toList(),
        );
        final custom = _span == GainSpan.custom;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _SpanPicker(span: _span, text: text, onSelected: _chooseSpan),
            const SizedBox(height: 12),
            _CurrencyGains(
              currencies: currencies,
              gains: gains,
              selectedId: detailId,
              onSelected: (id) => setState(() => _detailCurrencyId = id),
            ),
            const SizedBox(height: 12),
            _PeriodCard(
              period: _period,
              span: _span,
              profit: profit,
              currencyId: detailId,
              isCurrent: onCurrent,
              text: text,
              languageCode: language,
              onPrevious: custom
                  ? null
                  : () => setState(() => _period = _period.shift(-1, _span)),
              onNext: custom || onCurrent
                  ? null
                  : () => setState(() => _period = _period.shift(1, _span)),
              onChoose: custom ? _pickCustom : null,
            ),
            const SizedBox(height: 18),
            if (profit.sales.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  text.noSalesInPeriod,
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

class _SpanPicker extends StatelessWidget {
  const _SpanPicker({
    required this.span,
    required this.text,
    required this.onSelected,
  });

  final GainSpan span;
  final AppText text;
  final ValueChanged<GainSpan> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final choice in GainSpan.values)
          ChoiceChip(
            key: Key('gain-span-${choice.name}'),
            label: Text(_label(text, choice)),
            selected: span == choice,
            onSelected: (_) => onSelected(choice),
          ),
      ],
    );
  }

  String _label(AppText text, GainSpan choice) {
    return switch (choice) {
      GainSpan.day => text.daySpan,
      GainSpan.week => text.weekSpan,
      GainSpan.month => text.monthSpan,
      GainSpan.custom => text.customSpan,
    };
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
  final PeriodProfit gains;
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

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.span,
    required this.profit,
    required this.currencyId,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onChoose,
    required this.text,
    required this.languageCode,
  });

  final GainPeriod period;
  final GainSpan span;
  final PeriodProfit profit;
  final String currencyId;
  final bool isCurrent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onChoose;
  final AppText text;
  final String languageCode;

  String get _title {
    return switch (span) {
      GainSpan.day => isCurrent ? text.todayLabel : text.daySpan,
      GainSpan.week => isCurrent ? text.thisWeek : text.weekSpan,
      GainSpan.month => isCurrent ? text.thisMonth : text.monthSpan,
      GainSpan.custom => text.customSpan,
    };
  }

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
                  tooltip: text.previousPeriod,
                  onPressed: onPrevious,
                  color: KaratColors.cream,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: KaratColors.gold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPeriod(
                          period.start,
                          period.end,
                          languageCode: languageCode,
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: KaratColors.cream),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: onChoose == null
                      ? text.nextPeriod
                      : text.chooseDates,
                  onPressed: onChoose ?? onNext,
                  color: KaratColors.cream,
                  icon: Icon(
                    onChoose == null ? Icons.chevron_right : Icons.date_range,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (span == GainSpan.week)
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
