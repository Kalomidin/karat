import 'package:flutter_svg/flutter_svg.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/week_profit.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/screens/item_detail_screen.dart';
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
  bool? _goldFocus;

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
      _goldFocus = null;
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
      _goldFocus = null;
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
        final currencyItems = items
            .where((item) => item.currencyId == detailId)
            .toList();
        final profit = PeriodProfit(period: _period, items: currencyItems);
        final moves = _moves(currencyItems, profit);
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
              onSelected: (id) => setState(() {
                _detailCurrencyId = id;
                _goldFocus = null;
              }),
            ),
            const SizedBox(height: 12),
            _PeriodCard(
              period: _period,
              span: _span,
              profit: profit,
              goldAddedGrams: profit.goldAddedGrams,
              goldSoldGrams: profit.goldSoldGrams,
              currencyId: detailId,
              goldFocus: _goldFocus,
              onGold: (added) => setState(() {
                _goldFocus = _goldFocus == added ? null : added;
              }),
              isCurrent: onCurrent,
              text: text,
              languageCode: language,
              onPrevious: custom
                  ? null
                  : () => setState(() {
                      _goldFocus = null;
                      _period = _period.shift(-1, _span);
                    }),
              onNext: custom || onCurrent
                  ? null
                  : () => setState(() {
                      _goldFocus = null;
                      _period = _period.shift(1, _span);
                    }),
              onChoose: custom ? _pickCustom : null,
            ),
            const SizedBox(height: 18),
            if (moves.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _goldFocus == null
                      ? text.noMovesInPeriod
                      : text.goldMovesEmpty(_goldFocus!),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: KaratColors.ink.withValues(alpha: 0.72),
                  ),
                ),
              )
            else
              ...moves.map(
                (move) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MoveRow(
                    item: move.item,
                    added: move.added,
                    count: move.count,
                    totalCents: move.totalCents,
                    totalGrams: move.totalGrams,
                    text: text,
                    languageCode: language,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ItemDetailScreen(
                            controller: widget.controller,
                            itemId: move.item.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<_GainMove> _moves(List<JewelleryItem> items, PeriodProfit profit) {
    final focus = _goldFocus;
    final soldIds = {for (final item in profit.sales) item.id};
    final rows = focus == null
        ? <_GainMove>[
            for (final item in items)
              if (_period.contains(item.createdOn) &&
                  !soldIds.contains(item.id))
                _GainMove(item, true),
            for (final item in profit.sales) _GainMove(item, false),
          ]
        : <_GainMove>[
            for (final item in focus ? profit.goldAdded : profit.goldSold)
              _GainMove(item, focus),
          ];
    rows.sort((a, b) {
      final byDay = b.day.compareTo(a.day);
      if (byDay != 0) return byDay;
      return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
    });
    final arrivals = focus == true
        ? profit.goldAdded
        : focus == false
        ? const <JewelleryItem>[]
        : [
            for (final item in items)
              if (_period.contains(item.createdOn)) item,
          ];
    return _squeezeAdded(rows, arrivals);
  }
}

List<_GainMove> _squeezeAdded(
  List<_GainMove> rows,
  List<JewelleryItem> arrivals,
) {
  final batches = <String, List<JewelleryItem>>{};
  for (final item in arrivals) {
    final group = item.groupId.trim();
    if (group.isEmpty) continue;
    batches.putIfAbsent(group, () => []).add(item);
  }
  final out = <_GainMove>[];
  final seen = <String>{};
  for (final row in rows) {
    final group = row.item.groupId.trim();
    if (!row.added || group.isEmpty) {
      out.add(row);
      continue;
    }
    if (!seen.add(group)) continue;
    final members = batches[group] ?? [row.item];
    out.add(
      _GainMove(
        row.item,
        true,
        count: members.length,
        totalCents: members.fold(0, (sum, item) => sum + item.costCents),
        totalGrams: members.fold(0.0, (sum, item) => sum + item.weightGrams),
      ),
    );
  }
  return out;
}

class _GainMove {
  const _GainMove(
    this.item,
    this.added, {
    this.count = 1,
    this.totalCents = 0,
    this.totalGrams = 0,
  });

  final JewelleryItem item;
  final bool added;
  final int count;
  final int totalCents;
  final double totalGrams;

  Day get day => added ? item.createdOn : item.soldOn!;
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
    return Row(
      children: [
        for (final choice in GainSpan.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                key: Key('gain-span-${choice.name}'),
                label: Text(
                  _label(text, choice),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: span == choice,
                onSelected: (_) => onSelected(choice),
              ),
            ),
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
      color: selected
          ? KaratColors.gold.withValues(alpha: 0.22)
          : KaratColors.paper,
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amount,
                  key: Key('week-gain-${currency.code}'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: profitCents < 0 ? KaratColors.loss : KaratColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
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
    required this.goldAddedGrams,
    required this.goldSoldGrams,
    required this.currencyId,
    required this.goldFocus,
    required this.isCurrent,
    required this.onPrevious,
    required this.onNext,
    required this.onChoose,
    required this.onGold,
    required this.text,
    required this.languageCode,
  });

  final GainPeriod period;
  final GainSpan span;
  final PeriodProfit profit;
  final double goldAddedGrams;
  final double goldSoldGrams;
  final String currencyId;
  final bool? goldFocus;
  final bool isCurrent;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onChoose;
  final ValueChanged<bool> onGold;
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
    final focused = goldFocus != null;
    final headlineCents = switch (goldFocus) {
      true => profit.goldAdded.fold(0, (sum, item) => sum + item.costCents),
      false => profit.goldSold.fold(
        0,
        (sum, item) => sum + (item.soldCents ?? 0),
      ),
      null => profit.profitCents,
    };
    final headlineLabel = switch (goldFocus) {
      true => text.spent,
      false => text.earned,
      null => text.profit,
    };
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
                        headlineCents,
                        signed: !focused,
                        currencyId: currencyId,
                      ),
                      key: const Key('week-profit'),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: focused || headlineCents == 0
                            ? KaratColors.cream
                            : ink,
                      ),
                    ),
                  ),
                  Text(
                    headlineLabel,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: KaratColors.cream),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _SignedGrams(
                        grams: goldAddedGrams,
                        added: true,
                        selected: goldFocus == true,
                        languageCode: languageCode,
                        valueKey: const Key('gold-added'),
                        onTap: () => onGold(true),
                      ),
                      _SignedGrams(
                        grams: goldSoldGrams,
                        added: false,
                        selected: goldFocus == false,
                        languageCode: languageCode,
                        valueKey: const Key('gold-sold'),
                        onTap: () => onGold(false),
                      ),
                    ],
                  ),
                  if (!focused) ...[
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: KaratColors.cream.withValues(alpha: 0.18),
                    ),
                    const SizedBox(height: 14),
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
                        _Stat(
                          label: text.pieces,
                          value: '${profit.pieceCount}',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedGrams extends StatelessWidget {
  const _SignedGrams({
    required this.grams,
    required this.added,
    required this.selected,
    required this.languageCode,
    required this.onTap,
    this.valueKey,
  });

  final double grams;
  final bool added;
  final bool selected;
  final String languageCode;
  final VoidCallback onTap;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final quiet = grams == 0;
    final color = quiet
        ? KaratColors.cream.withValues(alpha: 0.7)
        : added
        ? KaratColors.profit
        : KaratColors.cream;
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: selected ? Key(added ? 'gold-added-on' : 'gold-sold-on') : null,
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? KaratColors.cream.withValues(alpha: 0.14)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _GoldMark(added: added, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      formatGrams(grams, languageCode: languageCode),
                      key: valueKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: color, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldMark extends StatelessWidget {
  const _GoldMark({required this.added, required this.color, this.size = 22});

  final bool added;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      added ? 'assets/icons/shop_add.svg' : 'assets/icons/shop_remove.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
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

class _MoveRow extends StatelessWidget {
  const _MoveRow({
    required this.item,
    required this.added,
    required this.count,
    required this.totalCents,
    required this.totalGrams,
    required this.text,
    required this.languageCode,
    required this.onTap,
  });

  final JewelleryItem item;
  final bool added;
  final int count;
  final int totalCents;
  final double totalGrams;
  final AppText text;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final profit = item.profitCents ?? 0;
    final grams = count > 1 ? totalGrams : item.weightGrams;
    final detail = added
        ? '${formatDay(item.createdOn, languageCode: languageCode)} · ${text.purity} ${item.purity} · ${formatGrams(grams, languageCode: languageCode)}'
        : '${text.soldLine(formatDay(item.soldOn!, languageCode: languageCode), formatCents(item.soldCents!, currencyId: item.currencyId))} · ${formatGrams(item.weightGrams, languageCode: languageCode)}';
    return Material(
      color: KaratColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: KaratColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _GoldMark(
                  added: added,
                  color: KaratColors.goldDeep,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      key: Key('gain-move-${item.id}-${added ? 'in' : 'out'}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: KaratColors.ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 1) ...[
                const SizedBox(width: 8),
                Text(
                  '× $count',
                  key: Key('gain-count-${item.groupId}'),
                  style: const TextStyle(
                    color: KaratColors.goldDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Text(
                formatCents(
                  added ? (count > 1 ? totalCents : item.costCents) : profit,
                  signed: !added,
                  currencyId: item.currencyId,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: !added && profit < 0
                      ? KaratColors.loss
                      : KaratColors.goldDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
