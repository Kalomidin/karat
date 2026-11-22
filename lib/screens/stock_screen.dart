import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/stock_query.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/screens/item_detail_screen.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/piece_photo.dart';
import 'package:material_ui/material_ui.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.controller});

  final KaratController controller;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _sold = false;
  String _query = '';
  PieceKind? _kind;
  String _grams = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final groups = stockGroups(
          stockView(
            widget.controller.items,
            sold: _sold,
            query: _query,
            kind: _kind,
            grams: _grams,
          ),
        );
        final text = AppText.of(context);
        final language = Localizations.localeOf(context).languageCode;
        final goldTotals = goldGramsByPurity(widget.controller.items);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: false, label: Text(text.inStock)),
                      ButtonSegment(value: true, label: Text(text.sold)),
                    ],
                    selected: {_sold},
                    onSelectionChanged: (value) {
                      setState(() => _sold = value.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: text.searchPieces,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterButton(
                        active: _kind != null || _grams.trim().isNotEmpty,
                        tooltip: text.filters,
                        onPressed: () => _openFilter(context),
                      ),
                    ],
                  ),
                  if (goldTotals.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        goldTotals
                            .map(
                              (total) =>
                                  '${total.$1} ${formatGrams(total.$2, languageCode: language)}',
                            )
                            .join(' · '),
                        key: const Key('stock-gold-totals'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: KaratColors.ink.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: groups.isEmpty
                  ? _EmptyStock(
                      sold: _sold,
                      searching:
                          _query.trim().isNotEmpty ||
                          _kind != null ||
                          _grams.trim().isNotEmpty,
                      text: text,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: groups.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final group = groups[index];
                        final item = group.item;
                        return _PieceCard(
                          item: item,
                          count: group.count,
                          text: text,
                          languageCode: language,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ItemDetailScreen(
                                  controller: widget.controller,
                                  itemId: item.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFilter(BuildContext context) async {
    final result = await showModalBottomSheet<_StockFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: KaratColors.paper,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _StockFilterSheet(kind: _kind, grams: _grams),
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _kind = result.kind;
      _grams = result.grams;
    });
  }
}

class _StockFilter {
  const _StockFilter({this.kind, this.grams = ''});

  final PieceKind? kind;
  final String grams;
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.active,
    required this.tooltip,
    required this.onPressed,
  });

  final bool active;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        key: const Key('stock-filter'),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: active
              ? KaratColors.gold.withValues(alpha: 0.35)
              : KaratColors.paper,
          foregroundColor: KaratColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: KaratColors.line),
          ),
        ),
        icon: const Icon(Icons.tune),
      ),
    );
  }
}

class _StockFilterSheet extends StatefulWidget {
  const _StockFilterSheet({required this.kind, required this.grams});

  final PieceKind? kind;
  final String grams;

  @override
  State<_StockFilterSheet> createState() => _StockFilterSheetState();
}

class _StockFilterSheetState extends State<_StockFilterSheet> {
  late PieceKind? _kind = widget.kind;
  late final TextEditingController _grams = TextEditingController(
    text: widget.grams,
  );

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text.filters, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(text.pieceType, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(text.anyType),
                showCheckmark: false,
                selected: _kind == null,
                onSelected: (_) => setState(() => _kind = null),
              ),
              for (final kind in PieceKind.values)
                ChoiceChip(
                  key: Key('stock-type-${kind.name}'),
                  label: Text(text.kind(kind)),
                  showCheckmark: false,
                  selected: _kind == kind,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('stock-grams'),
            controller: _grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: text.weight,
              suffixText: text.grams,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                key: const Key('stock-filter-clear'),
                onPressed: () {
                  Navigator.pop(context, const _StockFilter());
                },
                child: Text(text.clearFilters),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('stock-filter-apply'),
                onPressed: () {
                  Navigator.pop(
                    context,
                    _StockFilter(kind: _kind, grams: _grams.text),
                  );
                },
                child: Text(text.applyFilters),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyStock extends StatelessWidget {
  const _EmptyStock({
    required this.sold,
    required this.searching,
    required this.text,
  });

  final bool sold;
  final bool searching;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final message = searching
        ? text.noSearchMatches
        : sold
        ? text.noSoldPieces
        : text.nothingInStock;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: KaratColors.ink.withValues(alpha: 0.72)),
        ),
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.item,
    required this.count,
    required this.onTap,
    required this.text,
    required this.languageCode,
  });

  final JewelleryItem item;
  final int count;
  final VoidCallback onTap;
  final AppText text;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final profit = item.profitCents;
    final detail = [
      text.kind(item.kind),
      '${text.purity} ${item.purity}',
      formatGrams(item.weightGrams, languageCode: languageCode),
    ].join(' · ');
    return Material(
      color: KaratColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: KaratColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.imageUrl.isNotEmpty) ...[
                    PiecePhoto(
                      imageUrl: item.imageUrl,
                      height: 56,
                      width: 56,
                      radius: 12,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (count > 1)
                    Text(
                      '× $count',
                      key: Key('stock-count-${item.id}'),
                      style: const TextStyle(
                        color: KaratColors.goldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (profit != null)
                    Text(
                      formatCents(
                        profit,
                        signed: true,
                        currencyId: item.currencyId,
                      ),
                      style: TextStyle(
                        color: profit < 0
                            ? KaratColors.loss
                            : KaratColors.goldDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: KaratColors.ink.withValues(alpha: 0.72)),
              ),
              const SizedBox(height: 8),
              Text(
                item.isSold
                    ? text.soldLine(
                        formatDay(item.soldOn!, languageCode: languageCode),
                        formatCents(
                          item.soldCents!,
                          currencyId: item.currencyId,
                        ),
                      )
                    : count > 1
                    ? text.costEachLine(
                        formatCents(
                          item.costCents,
                          currencyId: item.currencyId,
                        ),
                      )
                    : text.costLine(
                        formatCents(
                          item.costCents,
                          currencyId: item.currencyId,
                        ),
                      ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
