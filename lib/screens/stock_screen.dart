import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/stock_query.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/screens/item_detail_screen.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final visible = stockView(
          widget.controller.items,
          sold: _sold,
          query: _query,
        );
        final text = AppText.of(context);
        final language = Localizations.localeOf(context).languageCode;
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
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: text.searchPieces,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyStock(
                      sold: _sold,
                      searching: _query.trim().isNotEmpty,
                      text: text,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return _PieceCard(
                          item: item,
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
    required this.onTap,
    required this.text,
    required this.languageCode,
  });

  final JewelleryItem item;
  final VoidCallback onTap;
  final AppText text;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final profit = item.profitCents;
    final detail = [
      text.kind(item.kind),
      text.metalName(item.metal),
      item.purity,
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
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (profit != null)
                    Text(
                      formatCents(profit, signed: true),
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
                        formatCents(item.soldCents!),
                      )
                    : text.costLine(formatCents(item.costCents)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.stockNumber.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.stockNumber,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: KaratColors.ink.withValues(alpha: 0.6)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
