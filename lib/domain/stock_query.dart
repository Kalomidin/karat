import 'package:karat/domain/jewellery_item.dart';

List<JewelleryItem> stockView(
  List<JewelleryItem> items, {
  required bool sold,
  String query = '',
  PieceKind? kind,
  String grams = '',
}) {
  final needle = query.trim().toLowerCase();
  final gramNeedle = grams.trim().replaceAll(',', '.');
  final matched = items.where((item) {
    if (item.isSold != sold) return false;
    if (kind != null && item.kind != kind) return false;
    if (!_gramsMatch(item.weightGrams, gramNeedle)) return false;
    if (needle.isEmpty) return true;
    final haystack = [
      item.name,
      item.kind.name,
      item.kind.label,
      _kindRu[item.kind],
      item.metal.label,
      _metalRu[item.metal],
      item.purity,
      _gramsText(item.weightGrams),
    ].join(' ').toLowerCase();
    return haystack.contains(needle);
  }).toList();
  matched.sort((a, b) {
    final byDay = sold
        ? b.soldOn!.compareTo(a.soldOn!)
        : b.createdOn.compareTo(a.createdOn);
    if (byDay != 0) return byDay;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return matched;
}

/// One card on the stock list. Unsold pieces that share a group id share a card.
class StockGroup {
  StockGroup(this.pieces);

  final List<JewelleryItem> pieces;

  JewelleryItem get item => pieces.first;

  int get count => pieces.length;
}

List<StockGroup> stockGroups(List<JewelleryItem> visible) {
  final groups = <StockGroup>[];
  for (final item in visible) {
    if (!item.isSold) {
      final index = groups.indexWhere((group) => sameBatch(group.item, item));
      if (index >= 0) {
        groups[index].pieces.add(item);
        continue;
      }
    }
    groups.add(StockGroup([item]));
  }
  return groups;
}

int matchingStockCount(List<JewelleryItem> items, JewelleryItem item) {
  if (item.isSold || item.groupId.trim().isEmpty) return 1;
  var count = 0;
  for (final other in items) {
    if (!other.isSold && sameBatch(other, item)) count++;
  }
  return count;
}

/// True when both pieces belong to one saved batch.
///
/// An empty group id never matches, so older pieces stay on their own cards.
bool sameBatch(JewelleryItem a, JewelleryItem b) {
  final group = a.groupId.trim();
  return group.isNotEmpty && group == b.groupId.trim();
}

/// Grams of unsold gold, one total per purity stamp.
///
/// Known stamps stay in shop order. Any other stamp follows them.
List<(String, double)> goldGramsByPurity(List<JewelleryItem> items) {
  final totals = <String, double>{};
  for (final item in items) {
    if (item.isSold || item.metal != Metal.gold) continue;
    final stamp = item.purity.trim();
    if (stamp.isEmpty) continue;
    totals[stamp] = (totals[stamp] ?? 0) + item.weightGrams;
  }
  final stamps = totals.keys.toList()..sort(_purityOrder);
  return [for (final stamp in stamps) (stamp, totals[stamp]!)];
}

const _purityRank = ['750', '585', '375'];

int _purityOrder(String a, String b) {
  final ai = _purityRank.indexOf(a);
  final bi = _purityRank.indexOf(b);
  if (ai != -1 || bi != -1) {
    if (ai == -1) return 1;
    if (bi == -1) return -1;
    return ai.compareTo(bi);
  }
  return a.compareTo(b);
}

const _kindRu = {
  PieceKind.ring: 'кольцо',
  PieceKind.necklace: 'колье',
  PieceKind.bracelet: 'браслет',
  PieceKind.earrings: 'серьги',
  PieceKind.pendant: 'подвеска',
  PieceKind.brooch: 'брошь',
  PieceKind.other: 'другое',
};

bool _gramsMatch(double grams, String needle) {
  if (needle.isEmpty) return true;
  final display = _gramsText(grams);
  if (display.startsWith(needle)) return true;
  final parsed = double.tryParse(needle);
  if (parsed == null) return false;
  return (parsed - grams).abs() < 0.0005;
}

String _gramsText(double grams) {
  var text = grams.toStringAsFixed(3);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text;
}

const _metalRu = {
  Metal.gold: 'золото',
  Metal.silver: 'серебро',
  Metal.platinum: 'платина',
  Metal.mixed: 'смешанный',
};
