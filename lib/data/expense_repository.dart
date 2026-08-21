import '../models/bank_transaction.dart';
import '../models/monthly_summary.dart';
import '../services/balance_store.dart';
import '../services/ledger.dart';

abstract class ExpenseRepository {
  Future<void> ensureReady() async {}

  Future<void> upsertTransactions(List<BankTransaction> transactions);

  Future<List<BankTransaction>> loadTransactions();

  Future<void> saveSnapshot(double amount, {DateTime? asOf});

  Future<BalanceSnapshot?> loadSnapshot();

  Future<void> saveSummaries(List<MonthlySummary> summaries);

  Future<MonthlySummary?> loadSummary(DateTime month);

  Future<void> rebuildSummaries({DateTime? now}) async {
    final transactions = await loadTransactions();
    final snapshot = await loadSnapshot();
    final ledger = Ledger(
      transactions: transactions,
      snapshotBalance: snapshot?.amount,
      snapshotAt: snapshot?.asOf,
    );

    final months = <DateTime>{
      for (final tx in transactions) DateTime(tx.date.year, tx.date.month),
    };
    final current = now ?? DateTime.now();
    months.add(DateTime(current.year, current.month));

    final summaries = months.map((month) {
      final monthTxs = ledger.inMonth(month);
      return MonthlySummary(
        year: month.year,
        month: month.month,
        totalCredits: ledger.totalCredits(monthTxs),
        totalDebits: ledger.totalDebits(monthTxs),
        openingBalance: ledger.openingBalance(month),
        closingBalance: ledger.monthlyBalance(month, current),
        transactionCount: monthTxs.length,
        updatedAt: current,
      );
    }).toList();

    await saveSummaries(summaries);
  }
}
