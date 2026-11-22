import 'package:karat/domain/jewellery_item.dart';

List<JewelleryItem> stockView(
  List<JewelleryItem> items, {
  required bool sold,
  String query = '',
}) {
  final needle = query.trim().toLowerCase();
  final matched = items.where((item) {
    if (item.isSold != sold) return false;
    if (needle.isEmpty) return true;
    final haystack = [
      item.name,
      item.kind.label,
      _kindRu[item.kind],
      item.metal.label,
      _metalRu[item.metal],
      item.purity,
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

const _kindRu = {
  PieceKind.ring: 'кольцо',
  PieceKind.necklace: 'колье',
  PieceKind.bracelet: 'браслет',
  PieceKind.earrings: 'серьги',
  PieceKind.pendant: 'подвеска',
  PieceKind.brooch: 'брошь',
  PieceKind.other: 'другое',
};

const _metalRu = {
  Metal.gold: 'золото',
  Metal.silver: 'серебро',
  Metal.platinum: 'платина',
  Metal.mixed: 'смешанный',
};
