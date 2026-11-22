import 'package:karat/domain/book_notice.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/screens/item_form_screen.dart';
import 'package:karat/screens/mark_sold_sheet.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    super.key,
    required this.controller,
    required this.itemId,
  });

  final KaratController controller;
  final String itemId;

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required bool closeAfter,
    required Future<BookNotice?> Function() run,
  }) async {
    final keep = AppText.of(context).keep;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(keep),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    if (proceed != true || !context.mounted) return;
    final error = await run();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context).notice(error))),
      );
      return;
    }
    if (closeAfter) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final item = controller.find(itemId);
        final text = AppText.of(context);
        final language = Localizations.localeOf(context).languageCode;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(text.pieceRemoved)),
          );
        }
        final profit = item.profitCents;
        return Scaffold(
          appBar: AppBar(
            title: Text(item.name),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ItemFormScreen(
                            controller: controller,
                            existing: item,
                          ),
                        ),
                      );
                    case 'return':
                      _confirm(
                        context,
                        title: text.returnToStockTitle,
                        body: text.returnToStockBody,
                        action: text.returnAction,
                        closeAfter: false,
                        run: () => controller.returnToStock(item.id),
                      );
                    case 'remove':
                      _confirm(
                        context,
                        title: text.removeTitle,
                        body: item.isSold
                            ? text.removeSoldBody
                            : text.removeStockBody,
                        action: text.remove,
                        closeAfter: true,
                        run: () => controller.deleteItem(item.id),
                      );
                  }
                },
                itemBuilder: (context) => [
                  if (!item.isSold)
                    PopupMenuItem(value: 'edit', child: Text(text.edit)),
                  if (item.isSold)
                    PopupMenuItem(
                      value: 'return',
                      child: Text(text.returnToStock),
                    ),
                  PopupMenuItem(value: 'remove', child: Text(text.remove)),
                ],
              ),
            ],
          ),
          body: ShopWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  '${text.kind(item.kind)} · ${text.metalName(item.metal)} · ${item.purity}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: KaratColors.goldDeep),
                ),
                const SizedBox(height: 16),
                _Fact(
                  label: text.weight,
                  value: formatGrams(item.weightGrams, languageCode: language),
                ),
                _Fact(label: text.cost, value: formatCents(item.costCents)),
                if (item.stockNumber.isNotEmpty)
                  _Fact(label: text.stockNumber, value: item.stockNumber),
                _Fact(
                  label: text.registered,
                  value: formatDay(item.createdOn, languageCode: language),
                ),
                if (item.isSold) ...[
                  _Fact(
                    label: text.sold,
                    value: formatDay(item.soldOn!, languageCode: language),
                  ),
                  _Fact(
                    label: text.salePrice,
                    value: formatCents(item.soldCents!),
                  ),
                  _Fact(
                    label: text.profit,
                    value: formatCents(profit ?? 0, signed: true),
                    valueColor: (profit ?? 0) < 0
                        ? KaratColors.loss
                        : KaratColors.goldDeep,
                  ),
                ],
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    text.notes,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(item.notes),
                ],
              ],
            ),
          ),
          bottomNavigationBar: item.isSold
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: FilledButton(
                      key: const Key('mark-sold'),
                      onPressed: () => showMarkSoldSheet(
                        context,
                        controller: controller,
                        item: item,
                      ),
                      child: Text(text.markSold),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: KaratColors.ink.withValues(alpha: 0.65)),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
