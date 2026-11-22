import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:karat/domain/book_notice.dart';
import 'package:karat/domain/currency.dart';
import 'package:karat/data/piece_photo_file.dart';
import 'package:karat/widgets/currency_menu.dart';
import 'package:karat/data/piece_photo_upload.dart';
import 'package:karat/domain/jewellery_item.dart';
import 'package:karat/domain/stock_query.dart';
import 'package:karat/l10n/app_text.dart';
import 'package:karat/state/karat_controller.dart';
import 'package:karat/theme/karat_theme.dart';
import 'package:karat/widgets/piece_photo.dart';
import 'package:karat/widgets/update_failed_dialog.dart';
import 'package:karat/widgets/shop_width.dart';
import 'package:material_ui/material_ui.dart';

const _purities = ['750', '585', '375'];

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({
    super.key,
    required this.controller,
    this.existing,
    this.uploader,
  });

  final KaratController controller;
  final JewelleryItem? existing;
  final PiecePhotoUploader? uploader;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _purity;
  late final TextEditingController _weight;
  late final TextEditingController _cost;
  late final TextEditingController _notes;
  late PieceKind _kind;
  late Metal _metal;
  late String _currencyId;
  late String _imageUrl;
  late String _imageKey;
  Uint8List? _pendingBytes;
  var _pendingType = 'image/jpeg';
  var _attempted = false;
  var _saving = false;
  var _quantity = 1;

  @override
  void initState() {
    super.initState();
    final draft = widget.existing == null
        ? ItemDraft.initial()
        : ItemDraft.fromItem(widget.existing!);
    _name = TextEditingController(text: draft.name);
    _purity = TextEditingController(text: draft.purity);
    _weight = TextEditingController(text: draft.weightText);
    _cost = TextEditingController(text: draft.costText);
    _notes = TextEditingController(text: draft.notes);
    _kind = draft.kind;
    _metal = draft.metal;
    _currencyId = widget.existing == null
        ? widget.controller.shopCurrencyId
        : draft.currencyId;
    _imageUrl = widget.existing?.imageUrl ?? '';
    _imageKey = widget.existing?.imageKey ?? '';
    final existing = widget.existing;
    if (existing != null && !existing.isSold) {
      _quantity = matchingStockCount(widget.controller.items, existing);
    }
    for (final controller in [_name, _purity, _weight, _cost, _notes]) {
      controller.addListener(_rebuild);
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_name, _purity, _weight, _cost, _notes]) {
      controller
        ..removeListener(_rebuild)
        ..dispose();
    }
    super.dispose();
  }

  ItemDraft get _draft {
    return ItemDraft(
      name: _name.text,
      kind: _kind,
      metal: _metal,
      purity: _purity.text,
      weightText: _weight.text,
      costText: _cost.text,
      notes: _notes.text,
      currencyId: _currencyId,
    );
  }

  Future<void> _pickPhoto() async {
    final text = AppText.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('photo-library'),
                title: Text(text.photoLibrary),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                key: const Key('photo-camera'),
                title: Text(text.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 8 * 1024 * 1024) {
        _photoFailed();
        return;
      }
      setState(() {
        _pendingBytes = bytes;
        _pendingType = contentTypeForPhoto(file.name, file.mimeType);
      });
    } catch (_) {
      if (mounted) _photoFailed();
    }
  }

  void _photoFailed() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppText.of(context).photoFailed)));
  }

  Future<void> _save() async {
    setState(() => _attempted = true);
    final draft = _draft;
    if (!draft.isValid || _saving) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    final id = existing?.id ?? newItemId();
    var imageUrl = _imageUrl;
    var imageKey = _imageKey;
    final pending = _pendingBytes;
    if (pending != null) {
      try {
        final token = await widget.controller.idToken();
        if (token == null || token.isEmpty) {
          throw const PiecePhotoUploadException();
        }
        final uploaded = await (widget.uploader ?? PiecePhotoUploader()).upload(
          idToken: token,
          bytes: pending,
          contentType: _pendingType,
        );
        imageKey = uploaded.imageKey;
        imageUrl = await savePiecePhoto(
          id,
          pending,
          extensionForPhoto(_pendingType),
        );
      } on PiecePhotoUploadException {
        if (!mounted) return;
        setState(() => _saving = false);
        _photoFailed();
        return;
      }
    }
    final item = draft.toItem(
      id: id,
      createdOn: existing?.createdOn ?? widget.controller.today,
      imageUrl: imageUrl,
      imageKey: imageKey,
    );
    final error = await widget.controller.saveItem(
      item,
      quantity: existing != null && existing.isSold ? 1 : _quantity,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      if (error == BookNotice.updateFailed) {
        await showUpdateFailed(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.of(context).notice(error))),
        );
      }
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
              PiecePhoto(
                imageUrl: _imageUrl,
                bytes: _pendingBytes,
                height: _pendingBytes == null && _imageUrl.isEmpty ? 0 : 180,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('add-photo'),
                  onPressed: _saving ? null : _pickPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(
                    _pendingBytes == null && _imageUrl.isEmpty
                        ? text.addPhoto
                        : text.changePhoto,
                  ),
                ),
              ),
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
              _ChoiceRow<PieceKind>(
                options: PieceKind.values,
                selected: _kind,
                label: text.kind,
                onSelected: (kind) => setState(() => _kind = kind),
              ),
              _SectionLabel(text.purity),
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
                  errorText: errorFor(
                    draft.purityError == null ? null : text.purityRequired,
                  ),
                ),
              ),
              if (!editing || !widget.existing!.isSold) ...[
                const SizedBox(height: 12),
                _QuantityStepper(
                  quantity: _quantity,
                  enabled: !_saving,
                  label: text.quantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('piece-weight'),
                controller: _weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _quantity == 1 ? text.weight : text.weightEach,
                  suffixText: text.grams,
                  errorText: errorFor(
                    draft.weightError == null ? null : text.weightRequired,
                  ),
                ),
              ),
              _SectionLabel(text.money),
              CurrencyMenuButton(
                currencies: widget.controller.currencies,
                selectedId: _currencyId,
                compact: false,
                onSelected: (id) => setState(() => _currencyId = id),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('piece-cost'),
                controller: _cost,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _quantity == 1 ? text.cost : text.costEach,
                  prefixText: '${currencySymbolFor(_currencyId)} ',
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
            child: Text(
              _saving
                  ? text.saving
                  : _quantity > 1
                  ? text.savePieces(_quantity)
                  : text.savePiece,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatefulWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  final int quantity;
  final bool enabled;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<_QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<_QuantityStepper> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: '${widget.quantity}');
  }

  @override
  void didUpdateWidget(covariant _QuantityStepper old) {
    super.didUpdateWidget(old);
    if (int.tryParse(_text.text.trim()) != widget.quantity) {
      final next = '${widget.quantity}';
      _text.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _typed(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    final next = parsed.clamp(1, maxPieceQuantity);
    if (next != parsed) {
      final shown = '$next';
      _text.value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
    }
    if (next != widget.quantity) widget.onChanged(next);
  }

  void _finish() {
    final parsed = int.tryParse(_text.text.trim());
    final next = (parsed ?? widget.quantity).clamp(1, maxPieceQuantity);
    final shown = '$next';
    if (_text.text != shown) {
      _text.value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
    }
    if (next != widget.quantity) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('piece-quantity-dec'),
          onPressed: widget.enabled && widget.quantity > 1
              ? () => widget.onChanged(widget.quantity - 1)
              : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            key: const Key('piece-quantity'),
            controller: _text,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: _typed,
            onEditingComplete: _finish,
            onTapOutside: (_) => _finish(),
          ),
        ),
        IconButton(
          key: const Key('piece-quantity-inc'),
          onPressed: widget.enabled && widget.quantity < maxPieceQuantity
              ? () => widget.onChanged(widget.quantity + 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
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
