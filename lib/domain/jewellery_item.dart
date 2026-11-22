import 'dart:math';

import 'package:karat/domain/currency.dart';
import 'package:karat/domain/day.dart';
import 'package:karat/domain/money.dart';

enum PieceKind {
  ring('Ring'),
  necklace('Necklace'),
  bracelet('Bracelet'),
  earrings('Earrings'),
  pendant('Pendant'),
  brooch('Brooch'),
  other('Other');

  const PieceKind(this.label);
  final String label;
}

enum Metal {
  gold('Gold'),
  silver('Silver'),
  platinum('Platinum'),
  mixed('Mixed');

  const Metal(this.label);
  final String label;
}

/// One piece in the stock book.
///
/// A sale is recorded only when both [soldOn] and [soldCents] are set.
class JewelleryItem {
  const JewelleryItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.metal,
    required this.purity,
    required this.weightGrams,
    required this.costCents,
    required this.notes,
    required this.createdOn,
    this.currencyId = dollarCurrencyId,
    this.imageUrl = '',
    this.imageKey = '',
    this.soldOn,
    this.soldCents,
  }) : assert(
         (soldOn == null) == (soldCents == null),
         'A sale needs both a date and a price.',
       );

  final String id;
  final String name;
  final PieceKind kind;
  final Metal metal;
  final String purity;
  final double weightGrams;
  final String currencyId;
  final int costCents;
  final String notes;
  final String imageUrl;
  final String imageKey;
  final Day createdOn;
  final Day? soldOn;
  final int? soldCents;

  bool get isSold => soldOn != null && soldCents != null;

  int? get profitCents => isSold ? soldCents! - costCents : null;

  JewelleryItem markSold({required Day on, required int cents}) {
    return JewelleryItem(
      id: id,
      name: name,
      kind: kind,
      metal: metal,
      purity: purity,
      weightGrams: weightGrams,
      currencyId: currencyId,
      costCents: costCents,
      notes: notes,
      imageUrl: imageUrl,
      imageKey: imageKey,
      createdOn: createdOn,
      soldOn: on,
      soldCents: cents,
    );
  }

  /// Keeps the photo file on this phone when the server assigns its own id.
  JewelleryItem withServerIdentity(JewelleryItem server) {
    return JewelleryItem(
      id: server.id,
      name: server.name,
      kind: server.kind,
      metal: server.metal,
      purity: server.purity,
      weightGrams: server.weightGrams,
      currencyId: server.currencyId,
      costCents: server.costCents,
      notes: server.notes,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : server.imageUrl,
      imageKey: server.imageKey.isNotEmpty ? server.imageKey : imageKey,
      createdOn: server.createdOn,
      soldOn: server.soldOn,
      soldCents: server.soldCents,
    );
  }

  JewelleryItem returnToStock() {
    return JewelleryItem(
      id: id,
      name: name,
      kind: kind,
      metal: metal,
      purity: purity,
      weightGrams: weightGrams,
      currencyId: currencyId,
      costCents: costCents,
      notes: notes,
      imageUrl: imageUrl,
      imageKey: imageKey,
      createdOn: createdOn,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'metal': metal.name,
      'purity': purity,
      'weightGrams': weightGrams,
      'currencyId': currencyId,
      'costCents': costCents,
      'notes': notes,
      'imageUrl': imageUrl,
      'imageKey': imageKey,
      'createdOn': createdOn.iso,
      'soldOn': soldOn?.iso,
      'soldCents': soldCents,
    };
  }

  factory JewelleryItem.fromJson(Map<String, Object?> json) {
    final soldOnRaw = json['soldOn'];
    final soldCents = _soldCents(json);
    if ((soldOnRaw == null) != (soldCents == null)) {
      throw const FormatException('A sale needs both a date and a price.');
    }
    return JewelleryItem(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      kind: _byName(PieceKind.values, json['kind'], 'kind'),
      metal: _byName(Metal.values, json['metal'], 'metal'),
      purity: _string(json, 'purity'),
      weightGrams: _grams(json['weightGrams']),
      currencyId: _currencyId(json['currencyId']),
      costCents: _costCents(json),
      notes: json['notes'] is String ? json['notes'] as String : '',
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : '',
      imageKey: json['imageKey'] is String ? json['imageKey'] as String : '',
      createdOn: Day.parse(_string(json, 'createdOn')),
      soldOn: soldOnRaw == null ? null : Day.parse(soldOnRaw as String),
      soldCents: soldCents,
    );
  }
}

String newItemId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = Random().nextInt(0x7fffffff).toRadixString(36);
  return '$now$salt';
}

class ItemDraft {
  const ItemDraft({
    required this.name,
    required this.kind,
    required this.metal,
    required this.purity,
    required this.weightText,
    required this.costText,
    required this.notes,
    this.currencyId = dollarCurrencyId,
  });

  factory ItemDraft.initial() {
    return const ItemDraft(
      name: '',
      kind: PieceKind.ring,
      metal: Metal.gold,
      purity: '18K',
      weightText: '',
      costText: '',
      notes: '',
    );
  }

  factory ItemDraft.fromItem(JewelleryItem item) {
    return ItemDraft(
      name: item.name,
      kind: item.kind,
      metal: item.metal,
      purity: item.purity,
      weightText: gramsToInput(item.weightGrams),
      costText: centsToInput(item.costCents),
      notes: item.notes,
      currencyId: item.currencyId,
    );
  }

  final String name;
  final PieceKind kind;
  final Metal metal;
  final String purity;
  final String weightText;
  final String costText;
  final String notes;
  final String currencyId;

  String? get nameError =>
      name.trim().isEmpty ? 'Give the piece a name.' : null;

  String? get purityError =>
      purity.trim().isEmpty ? 'Add the purity, such as 18K or 925.' : null;

  String? get weightError =>
      parseGrams(weightText) == null ? 'Enter the weight in grams.' : null;

  String? get costError =>
      parseCents(costText) == null ? 'Enter the cost of the piece.' : null;

  bool get isValid =>
      nameError == null &&
      purityError == null &&
      weightError == null &&
      costError == null;

  JewelleryItem toItem({
    required String id,
    required Day createdOn,
    String imageUrl = '',
    String imageKey = '',
  }) {
    return JewelleryItem(
      id: id,
      name: name.trim(),
      kind: kind,
      metal: metal,
      purity: purity.trim(),
      weightGrams: parseGrams(weightText)!,
      currencyId: currencyId,
      costCents: parseCents(costText)!,
      notes: notes.trim(),
      imageUrl: imageUrl,
      imageKey: imageKey,
      createdOn: createdOn,
    );
  }
}

T _byName<T extends Enum>(List<T> values, Object? raw, String field) {
  if (raw is! String) throw FormatException('Missing $field.');
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unknown $field.');
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('Missing $field.');
  return value;
}

double _grams(Object? value) {
  if (value is! num) throw const FormatException('Missing weight.');
  return value.toDouble();
}

String _currencyId(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return dollarCurrencyId;
}

/// Server prices are whole units. Older books on the phone stored cents.
int _costCents(Map<String, Object?> json) {
  final whole = json['cost'];
  if (whole is num) return whole.round() * 100;
  final cents = json['costCents'];
  if (cents is int) return cents;
  throw const FormatException('Missing cost.');
}

int? _soldCents(Map<String, Object?> json) {
  if (json.containsKey('soldAmount')) {
    final whole = json['soldAmount'];
    if (whole == null) return null;
    if (whole is! num) throw const FormatException('Missing sale price.');
    return whole.round() * 100;
  }
  final cents = json['soldCents'];
  if (cents == null) return null;
  if (cents is! int) throw const FormatException('Missing sale price.');
  return cents;
}
