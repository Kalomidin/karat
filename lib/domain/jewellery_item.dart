import 'dart:math';

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
    required this.stockNumber,
    required this.kind,
    required this.metal,
    required this.purity,
    required this.weightGrams,
    required this.costCents,
    required this.notes,
    required this.createdOn,
    this.soldOn,
    this.soldCents,
  }) : assert(
         (soldOn == null) == (soldCents == null),
         'A sale needs both a date and a price.',
       );

  final String id;
  final String name;
  final String stockNumber;
  final PieceKind kind;
  final Metal metal;
  final String purity;
  final double weightGrams;
  final int costCents;
  final String notes;
  final Day createdOn;
  final Day? soldOn;
  final int? soldCents;

  bool get isSold => soldOn != null && soldCents != null;

  int? get profitCents => isSold ? soldCents! - costCents : null;

  JewelleryItem markSold({required Day on, required int cents}) {
    return JewelleryItem(
      id: id,
      name: name,
      stockNumber: stockNumber,
      kind: kind,
      metal: metal,
      purity: purity,
      weightGrams: weightGrams,
      costCents: costCents,
      notes: notes,
      createdOn: createdOn,
      soldOn: on,
      soldCents: cents,
    );
  }

  JewelleryItem returnToStock() {
    return JewelleryItem(
      id: id,
      name: name,
      stockNumber: stockNumber,
      kind: kind,
      metal: metal,
      purity: purity,
      weightGrams: weightGrams,
      costCents: costCents,
      notes: notes,
      createdOn: createdOn,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'stockNumber': stockNumber,
      'kind': kind.name,
      'metal': metal.name,
      'purity': purity,
      'weightGrams': weightGrams,
      'costCents': costCents,
      'notes': notes,
      'createdOn': createdOn.iso,
      'soldOn': soldOn?.iso,
      'soldCents': soldCents,
    };
  }

  factory JewelleryItem.fromJson(Map<String, Object?> json) {
    final soldOnRaw = json['soldOn'];
    final soldCentsRaw = json['soldCents'];
    if ((soldOnRaw == null) != (soldCentsRaw == null)) {
      throw const FormatException('A sale needs both a date and a price.');
    }
    return JewelleryItem(
      id: _string(json, 'id'),
      name: _string(json, 'name'),
      stockNumber: _string(json, 'stockNumber'),
      kind: _byName(PieceKind.values, json['kind'], 'kind'),
      metal: _byName(Metal.values, json['metal'], 'metal'),
      purity: _string(json, 'purity'),
      weightGrams: _grams(json['weightGrams']),
      costCents: _cents(json['costCents']),
      notes: _string(json, 'notes'),
      createdOn: Day.parse(_string(json, 'createdOn')),
      soldOn: soldOnRaw == null ? null : Day.parse(soldOnRaw as String),
      soldCents: soldCentsRaw as int?,
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
    required this.stockNumber,
    required this.kind,
    required this.metal,
    required this.purity,
    required this.weightText,
    required this.costText,
    required this.notes,
  });

  factory ItemDraft.initial() {
    return const ItemDraft(
      name: '',
      stockNumber: '',
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
      stockNumber: item.stockNumber,
      kind: item.kind,
      metal: item.metal,
      purity: item.purity,
      weightText: gramsToInput(item.weightGrams),
      costText: centsToInput(item.costCents),
      notes: item.notes,
    );
  }

  final String name;
  final String stockNumber;
  final PieceKind kind;
  final Metal metal;
  final String purity;
  final String weightText;
  final String costText;
  final String notes;

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

  JewelleryItem toItem({required String id, required Day createdOn}) {
    return JewelleryItem(
      id: id,
      name: name.trim(),
      stockNumber: stockNumber.trim(),
      kind: kind,
      metal: metal,
      purity: purity.trim(),
      weightGrams: parseGrams(weightText)!,
      costCents: parseCents(costText)!,
      notes: notes.trim(),
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

int _cents(Object? value) {
  if (value is! int) throw const FormatException('Missing cost.');
  return value;
}
