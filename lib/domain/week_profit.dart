import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';

/// A Monday–Sunday shop week.
class Week {
  Week._(this.start);

  factory Week.of(Day day) => Week._(day.weekStart);

  final Day start;

  Day get lastDay => start.addDays(6);

  bool contains(Day day) {
    return day >= start && day < start.addDays(7);
  }

  Week previous() => Week._(start.addDays(-7));

  Week next() => Week._(start.addDays(7));

  @override
  bool operator ==(Object other) => other is Week && other.start == start;

  @override
  int get hashCode => start.hashCode;
}

/// Profit for pieces sold during one week.
///
/// Profit is the sale price minus the recorded cost. Pieces still in stock
/// are left out, as are sales from any other week.
class WeekProfit {
  WeekProfit({required this.week, required List<JewelleryItem> items})
    : sales = _salesIn(week, items);

  final Week week;
  final List<JewelleryItem> sales;

  int get revenueCents =>
      sales.fold(0, (sum, item) => sum + (item.soldCents ?? 0));

  int get costCents => sales.fold(0, (sum, item) => sum + item.costCents);

  int get profitCents => revenueCents - costCents;

  int get pieceCount => sales.length;

  CurrencyTotal totalFor(String currencyId) {
    for (final total in totals) {
      if (total.currencyId == currencyId) return total;
    }
    return CurrencyTotal(
      currencyId: currencyId,
      revenueCents: 0,
      costCents: 0,
      profitCents: 0,
    );
  }

  List<CurrencyTotal> get totals {
    final order = <String>[];
    final revenue = <String, int>{};
    final cost = <String, int>{};
    for (final item in sales) {
      final id = item.currencyId;
      if (!revenue.containsKey(id)) order.add(id);
      revenue[id] = (revenue[id] ?? 0) + (item.soldCents ?? 0);
      cost[id] = (cost[id] ?? 0) + item.costCents;
    }
    return [
      for (final id in order)
        CurrencyTotal(
          currencyId: id,
          revenueCents: revenue[id]!,
          costCents: cost[id]!,
          profitCents: revenue[id]! - cost[id]!,
        ),
    ];
  }
}

class CurrencyTotal {
  const CurrencyTotal({
    required this.currencyId,
    required this.revenueCents,
    required this.costCents,
    required this.profitCents,
  });

  final String currencyId;
  final int revenueCents;
  final int costCents;
  final int profitCents;
}

List<JewelleryItem> _salesIn(Week week, List<JewelleryItem> items) {
  final sales = items.where((item) {
    final soldOn = item.soldOn;
    return item.isSold && soldOn != null && week.contains(soldOn);
  }).toList();
  sales.sort((a, b) {
    final byDay = b.soldOn!.compareTo(a.soldOn!);
    if (byDay != 0) return byDay;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sales;
}
