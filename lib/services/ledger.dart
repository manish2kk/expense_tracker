import '../models/bank_transaction.dart';

class Ledger {
  const Ledger({
    required this.transactions,
    this.snapshotBalance,
    this.snapshotAt,
  });

  final List<BankTransaction> transactions;
  final double? snapshotBalance;
  final DateTime? snapshotAt;

  bool get hasSnapshot => snapshotBalance != null && snapshotAt != null;

  List<BankTransaction> inMonth(DateTime month) {
    return transactions.where((tx) {
      return tx.date.year == month.year && tx.date.month == month.month;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double totalCredits(Iterable<BankTransaction> txs) {
    return txs.where((tx) => tx.isCredit).fold(0, (sum, tx) => sum + tx.amount);
  }

  double totalDebits(Iterable<BankTransaction> txs) {
    return txs.where((tx) => tx.isDebit).fold(0, (sum, tx) => sum + tx.amount);
  }

  Map<DateTime, DailyTotals> dailyTotals(DateTime month) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final totals = <DateTime, DailyTotals>{
      for (var day = 1; day <= days; day++)
        DateTime(month.year, month.month, day): const DailyTotals(),
    };
    for (final tx in inMonth(month)) {
      final key = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final current = totals[key] ?? const DailyTotals();
      totals[key] = tx.isCredit
          ? current.addCredit(tx.amount)
          : current.addDebit(tx.amount);
    }
    return totals;
  }

  /// Balance at [when], reconstructed from the user-entered snapshot.
  double? balanceAt(DateTime when) {
    if (!hasSnapshot) {
      return null;
    }

    var balance = snapshotBalance!;
    final snapshot = snapshotAt!;

    for (final tx in transactions) {
      if (when.isBefore(snapshot)) {
        if (tx.date.isAfter(when) && !tx.date.isAfter(snapshot)) {
          balance += tx.isDebit ? tx.amount : -tx.amount;
        }
      } else if (tx.date.isAfter(snapshot) && !tx.date.isAfter(when)) {
        balance += tx.signedAmount;
      }
    }
    return balance;
  }

  DateTime _startOfMonth(DateTime month) => DateTime(month.year, month.month);

  DateTime _endOfMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
  }

  double? openingBalance(DateTime month) {
    final start = _startOfMonth(month);
    return balanceAt(start.subtract(const Duration(milliseconds: 1)));
  }

  double? monthlyBalance(DateTime month, DateTime now) {
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    return balanceAt(isCurrentMonth ? now : _endOfMonth(month));
  }
}

class DailyTotals {
  const DailyTotals({this.credit = 0, this.debit = 0});

  final double credit;
  final double debit;

  double get net => credit - debit;

  DailyTotals addCredit(double amount) => DailyTotals(credit: credit + amount, debit: debit);

  DailyTotals addDebit(double amount) => DailyTotals(credit: credit, debit: debit + amount);
}
