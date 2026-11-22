import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

const _purities = ['24K', '22K', '18K', '14K', '925', '999'];

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, required this.controller, this.existing});

  final KaratController controller;
  final JewelleryItem? existing;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _stockNumber;
  late final TextEditingController _purity;
  late final TextEditingController _weight;
  late final TextEditingController _cost;
  late final TextEditingController _notes;
  late PieceKind _kind;
  late Metal _metal;
  var _attempted = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.existing == null
        ? ItemDraft.initial()
        : ItemDraft.fromItem(widget.existing!);
    _name = TextEditingController(text: draft.name);
    _stockNumber = TextEditingController(text: draft.stockNumber);
    _purity = TextEditingController(text: draft.purity);
    _weight = TextEditingController(text: draft.weightText);
    _cost = TextEditingController(text: draft.costText);
    _notes = TextEditingController(text: draft.notes);
    _kind = draft.kind;
    _metal = draft.metal;
    for (final controller in [
      _name,
      _stockNumber,
      _purity,
      _weight,
      _cost,
      _notes,
    ]) {
      controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _stockNumber,
      _purity,
      _weight,
      _cost,
      _notes,
    ]) {
      controller
        ..removeListener(_rebuild)
        ..dispose();
    }
    super.dispose();
  }

  ItemDraft get _draft {
    return ItemDraft(
      name: _name.text,
      stockNumber: _stockNumber.text,
      kind: _kind,
      metal: _metal,
      purity: _purity.text,
      weightText: _weight.text,
      costText: _cost.text,
      notes: _notes.text,
    );
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    final draft = _draft;
    if (!draft.isValid || _saving) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    final item = draft.toItem(
      id: existing?.id ?? newItemId(),
      createdOn: existing?.createdOn ?? widget.controller.today,
    );
    final error = await widget.controller.saveItem(item);
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context).notice(error))),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final editing = widget.existing != null;
    final text = AppText.of(context);
    String? errorFor(String? message) => _attempted ? message : null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? text.editPiece : text.newPiece)),
      body: ShopWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(text.pieceSection),
              TextField(
                key: const Key('piece-name'),
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: text.name,
                  errorText: errorFor(
                    draft.nameError == null ? null : text.nameRequired,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _stockNumber,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: text.stockNumber),
              ),
              const SizedBox(height: 12),
              _ChoiceRow<PieceKind>(
                options: PieceKind.values,
                selected: _kind,
                label: text.kind,
                onSelected: (kind) => setState(() => _kind = kind),
              ),
              _SectionLabel(text.metal),
              _ChoiceRow<Metal>(
                options: Metal.values,
                selected: _metal,
                label: text.metalName,
                onSelected: (metal) => setState(() => _metal = metal),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final purity in _purities)
                    ChoiceChip(
                      label: Text(purity),
                      showCheckmark: false,
                      selected: _purity.text.trim() == purity,
                      onSelected: (_) => _purity.text = purity,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _purity,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: text.purity,
                  errorText: errorFor(
                    draft.purityError == null ? null : text.purityRequired,
                  ),
                ),
              ),
              _SectionLabel(text.money),
              TextField(
                key: const Key('piece-weight'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: text.weight,
                  suffixText: text.grams,
                  errorText: errorFor(
                    draft.weightError == null ? null : text.weightRequired,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('piece-cost'),
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: text.cost,
                  prefixText: '\$ ',
                  errorText: errorFor(
                    draft.costError == null ? null : text.costRequired,
                  ),
                ),
              ),
              _SectionLabel(text.notes),
              TextField(
                controller: _notes,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: text.notes,
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            key: const Key('save-piece'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? text.saving : text.savePiece),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.2,
          color: KaratColors.goldDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(label(option)),
            showCheckmark: false,
            selected: option == selected,
            onSelected: (_) => onSelected(option),
          ),
      ],
    );
  }
}
