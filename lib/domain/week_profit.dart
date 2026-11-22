import 'package:karat/domain/day.dart';
import 'package:karat/domain/jewellery_item.dart';

enum GainSpan { day, week, month, custom }

/// Inclusive range of sale days for a gains report.
class GainPeriod {
  const GainPeriod(this.start, this.end);

  factory GainPeriod.around(GainSpan span, Day day) {
    return switch (span) {
      GainSpan.day => GainPeriod(day, day),
      GainSpan.week => GainPeriod(day.weekStart, day.weekStart.addDays(6)),
      GainSpan.month => GainPeriod(day.monthStart, day.monthEnd),
      GainSpan.custom => GainPeriod(day, day),
    };
  }

  final Day start;
  final Day end;

  bool contains(Day day) => day >= start && day <= end;

  GainPeriod shift(int direction, GainSpan span) {
    return switch (span) {
      GainSpan.day => GainPeriod.around(span, start.addDays(direction)),
      GainSpan.week => GainPeriod.around(span, start.addDays(7 * direction)),
      GainSpan.month => GainPeriod.around(span, _shiftMonth(start, direction)),
      GainSpan.custom => this,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is GainPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

Day _shiftMonth(Day monthStart, int direction) {
  var month = monthStart.month + direction;
  var year = monthStart.year;
  while (month < 1) {
    month += 12;
    year -= 1;
  }
  while (month > 12) {
    month -= 12;
    year += 1;
  }
  return Day(year, month, 1);
}

/// Profit for pieces sold during one period.
///
/// Profit is the sale price minus the recorded cost. Pieces still in stock
/// are left out, as are sales outside the period.
class PeriodProfit {
  PeriodProfit({required this.period, required List<JewelleryItem> items})
    : sales = _salesIn(period, items);

  final GainPeriod period;
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

List<JewelleryItem> _salesIn(GainPeriod period, List<JewelleryItem> items) {
  final sales = items.where((item) {
    final soldOn = item.soldOn;
    return item.isSold && soldOn != null && period.contains(soldOn);
  }).toList();
  sales.sort((a, b) {
    final byDay = b.soldOn!.compareTo(a.soldOn!);
    if (byDay != 0) return byDay;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return sales;
}
