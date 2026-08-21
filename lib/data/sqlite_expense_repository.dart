import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bank_transaction.dart';
import '../models/monthly_summary.dart';
import '../services/balance_store.dart';
import 'app_database.dart';
import 'expense_repository.dart';

class SqliteExpenseRepository extends ExpenseRepository {
  SqliteExpenseRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  bool _migratedPrefs = false;

  Future<Database> get _db => _database.database;

  @override
  Future<void> ensureReady() async {
    await _db;
    if (_migratedPrefs) {
      return;
    }
    _migratedPrefs = true;
    final existing = await loadSnapshot();
    if (existing != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final amount = prefs.getDouble('current_bank_balance');
    final asOfMs = prefs.getInt('current_bank_balance_as_of');
    if (amount == null || asOfMs == null) {
      return;
    }
    await saveSnapshot(
      amount,
      asOf: DateTime.fromMillisecondsSinceEpoch(asOfMs),
    );
  }

  @override
  Future<void> upsertTransactions(List<BankTransaction> transactions) async {
    final db = await _db;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        {
          'fingerprint': tx.fingerprint,
          'amount': tx.amount,
          'type': tx.type.name,
          'date_ms': tx.date.millisecondsSinceEpoch,
          'body': tx.body,
          'sender': tx.sender,
          'year': tx.date.year,
          'month': tx.date.month,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<BankTransaction>> loadTransactions() async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'date_ms DESC');
    return rows.map(_transactionFromRow).toList();
  }

  @override
  Future<void> saveSnapshot(double amount, {DateTime? asOf}) async {
    final db = await _db;
    await db.insert('balance_snapshots', {
      'id': 1,
      'amount': amount,
      'as_of_ms': (asOf ?? DateTime.now()).millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<BalanceSnapshot?> loadSnapshot() async {
    final db = await _db;
    final rows = await db.query('balance_snapshots', where: 'id = 1');
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return BalanceSnapshot(
      amount: (row['amount'] as num).toDouble(),
      asOf: DateTime.fromMillisecondsSinceEpoch(row['as_of_ms']! as int),
    );
  }

  @override
  Future<void> saveSummaries(List<MonthlySummary> summaries) async {
    final db = await _db;
    final batch = db.batch();
    for (final summary in summaries) {
      batch.insert('monthly_summaries', {
        'year': summary.year,
        'month': summary.month,
        'total_credits': summary.totalCredits,
        'total_debits': summary.totalDebits,
        'opening_balance': summary.openingBalance,
        'closing_balance': summary.closingBalance,
        'transaction_count': summary.transactionCount,
        'updated_at_ms': summary.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<MonthlySummary?> loadSummary(DateTime month) async {
    final db = await _db;
    final rows = await db.query(
      'monthly_summaries',
      where: 'year = ? AND month = ?',
      whereArgs: [month.year, month.month],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _summaryFromRow(rows.first);
  }

  BankTransaction _transactionFromRow(Map<String, Object?> row) {
    return BankTransaction(
      amount: (row['amount'] as num).toDouble(),
      type: TransactionType.values.byName(row['type']! as String),
      date: DateTime.fromMillisecondsSinceEpoch(row['date_ms']! as int),
      body: row['body']! as String,
      sender: row['sender'] as String?,
    );
  }

  MonthlySummary _summaryFromRow(Map<String, Object?> row) {
    return MonthlySummary(
      year: row['year']! as int,
      month: row['month']! as int,
      totalCredits: (row['total_credits'] as num).toDouble(),
      totalDebits: (row['total_debits'] as num).toDouble(),
      openingBalance: (row['opening_balance'] as num?)?.toDouble(),
      closingBalance: (row['closing_balance'] as num?)?.toDouble(),
      transactionCount: row['transaction_count']! as int,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row['updated_at_ms']! as int,
      ),
    );
  }
}
