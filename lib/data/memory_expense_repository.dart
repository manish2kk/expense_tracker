import '../models/bank_transaction.dart';
import '../models/monthly_summary.dart';
import '../services/balance_store.dart';
import 'expense_repository.dart';

class MemoryExpenseRepository extends ExpenseRepository {
  final Map<String, BankTransaction> _transactions = {};
  final Map<String, MonthlySummary> _summaries = {};
  BalanceSnapshot? _snapshot;

  @override
  Future<void> upsertTransactions(List<BankTransaction> transactions) async {
    for (final tx in transactions) {
      _transactions.putIfAbsent(tx.fingerprint, () => tx);
    }
  }

  @override
  Future<List<BankTransaction>> loadTransactions() async {
    return _transactions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> saveSnapshot(double amount, {DateTime? asOf}) async {
    _snapshot = BalanceSnapshot(amount: amount, asOf: asOf ?? DateTime.now());
  }

  @override
  Future<BalanceSnapshot?> loadSnapshot() async => _snapshot;

  @override
  Future<void> saveSummaries(List<MonthlySummary> summaries) async {
    for (final summary in summaries) {
      _summaries['${summary.year}-${summary.month}'] = summary;
    }
  }

  @override
  Future<MonthlySummary?> loadSummary(DateTime month) async {
    return _summaries['${month.year}-${month.month}'];
  }
}
