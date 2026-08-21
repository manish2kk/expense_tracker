import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'expense_tracker.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            fingerprint TEXT PRIMARY KEY,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            date_ms INTEGER NOT NULL,
            body TEXT NOT NULL,
            sender TEXT,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_transactions_month ON transactions(year, month)',
        );
        await db.execute('''
          CREATE TABLE monthly_summaries (
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            total_credits REAL NOT NULL,
            total_debits REAL NOT NULL,
            opening_balance REAL,
            closing_balance REAL,
            transaction_count INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            PRIMARY KEY (year, month)
          )
        ''');
        await db.execute('''
          CREATE TABLE balance_snapshots (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            amount REAL NOT NULL,
            as_of_ms INTEGER NOT NULL
          )
        ''');
      },
    );
  }
}
