import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/money.dart';
import 'package:karat/format.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showMarkSoldSheet(
  BuildContext context, {
  required KaratController controller,
  required JewelleryItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: KaratColors.paper,
    builder: (context) => MarkSoldSheet(controller: controller, item: item),
  );
}

class MarkSoldSheet extends StatefulWidget {
  const MarkSoldSheet({
    super.key,
    required this.controller,
    required this.item,
  });

  final KaratController controller;
  final JewelleryItem item;

  @override
  State<MarkSoldSheet> createState() => _MarkSoldSheetState();
}

class _MarkSoldSheetState extends State<MarkSoldSheet> {
  final TextEditingController _price = TextEditingController();
  late Day _soldOn = widget.controller.today;
  var _attempted = false;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _soldOn.date,
      firstDate: DateTime(2000),
      lastDate: widget.controller.today.date,
    );
    if (picked == null || !mounted) return;
    setState(() => _soldOn = Day.fromDateTime(picked));
  }

  Future<void> _record() async {
    setState(() {
      _attempted = true;
      _error = null;
    });
    final cents = parseCents(_price.text);
    if (cents == null || _saving) return;
    setState(() => _saving = true);
    final error = await widget.controller.markSold(
      widget.item.id,
      soldCents: cents,
      soldOn: _soldOn,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = AppText.of(context).notice(error);
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cents = parseCents(_price.text);
    final preview = cents == null ? null : cents - widget.item.costCents;
    final text = AppText.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.markSold, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            widget.item.name,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: KaratColors.ink.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('sale-price'),
            controller: _price,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: text.salePrice,
              prefixText: '\$ ',
              errorText: _attempted && cents == null
                  ? text.priceRequired
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickDate,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                text.soldOn(formatDay(_soldOn, languageCode: language)),
              ),
            ),
          ),
          if (preview != null) ...[
            const SizedBox(height: 12),
            Text(
              text.profitLine(formatCents(preview, signed: true)),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: preview < 0 ? KaratColors.loss : KaratColors.goldDeep,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: KaratColors.loss)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('record-sale'),
            onPressed: _saving ? null : _record,
            child: Text(_saving ? text.saving : text.recordSale),
          ),
        ],
      ),
    );
  }
}
