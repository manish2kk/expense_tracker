import 'package:expense_tracker/data/memory_expense_repository.dart';
import 'package:expense_tracker/models/bank_transaction.dart';
import 'package:expense_tracker/services/ledger.dart';
import 'package:expense_tracker/services/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmsParser', () {
    test('parses debit SMS', () {
      final tx = SmsParser.parse(
        body: 'Rs.1,250.00 debited from a/c XX1234 on 18-08-26. Avl Bal Rs.8,000.00',
        date: DateTime(2026, 8, 18),
        sender: 'VK-HSBCIN',
      );
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.debit);
      expect(tx.amount, 1250);
    });

    test('parses credit SMS', () {
      final tx = SmsParser.parse(
        body: 'INR 2,000 credited to your A/c XX99. Available balance INR 12,000',
        date: DateTime(2026, 8, 18),
        sender: 'AX-INDBNK',
      );
      expect(tx, isNotNull);
      expect(tx!.type, TransactionType.credit);
      expect(tx.amount, 2000);
    });

    test('ignores OTP messages', () {
      final tx = SmsParser.parse(
        body: 'Your OTP is 482913. Do not share with anyone.',
        date: DateTime(2026, 8, 18),
        sender: 'VK-HSBCIN',
      );
      expect(tx, isNull);
    });

    test('ignores senders that are not HSBCIN or INDBNK', () {
      final tx = SmsParser.parse(
        body: 'Rs.1,250.00 debited from a/c XX1234',
        date: DateTime(2026, 8, 18),
        sender: 'VM-HDFCBK',
      );
      expect(tx, isNull);
    });

    test('accepts senders that contain HSBCIN or INDBNK', () {
      expect(SmsParser.isAllowedSender('AD-HSBCIN'), isTrue);
      expect(SmsParser.isAllowedSender('VM-INDBNK'), isTrue);
      expect(SmsParser.isAllowedSender('HDFCBK'), isFalse);
    });
  });

  group('Ledger', () {
    test('reconstructs monthly balance from current bank balance', () {
      final now = DateTime(2026, 8, 18, 12);
      final ledger = Ledger(
        snapshotBalance: 10000,
        snapshotAt: now,
        transactions: [
          BankTransaction(
            amount: 500,
            type: TransactionType.debit,
            date: DateTime(2026, 8, 10),
            body: 'debited',
          ),
          BankTransaction(
            amount: 2000,
            type: TransactionType.credit,
            date: DateTime(2026, 8, 5),
            body: 'credited',
          ),
        ],
      );

      expect(ledger.monthlyBalance(DateTime(2026, 8), now), 10000);
      expect(ledger.openingBalance(DateTime(2026, 8)), 8500);
      expect(ledger.totalDebits(ledger.inMonth(DateTime(2026, 8))), 500);
      expect(ledger.totalCredits(ledger.inMonth(DateTime(2026, 8))), 2000);
      final dayTotals = ledger.dailyTotals(DateTime(2026, 8));
      expect(dayTotals[DateTime(2026, 8, 10)]!.debit, 500);
      expect(dayTotals[DateTime(2026, 8, 5)]!.credit, 2000);
      expect(dayTotals[DateTime(2026, 8, 5)]!.net, 2000);
      expect(dayTotals[DateTime(2026, 8, 10)]!.net, -500);
    });
  });

  group('ExpenseRepository', () {
    test('keeps month data after later SMS sync is empty', () async {
      final repo = MemoryExpenseRepository();
      final augustDebit = BankTransaction(
        amount: 500,
        type: TransactionType.debit,
        date: DateTime(2026, 8, 10),
        body: 'Rs.500 debited',
      );
      await repo.upsertTransactions([augustDebit]);
      await repo.saveSnapshot(10000, asOf: DateTime(2026, 8, 18));
      await repo.rebuildSummaries(now: DateTime(2026, 8, 18));

      await repo.upsertTransactions([]);
      await repo.rebuildSummaries(now: DateTime(2026, 9, 1));

      final saved = await repo.loadTransactions();
      expect(saved, hasLength(1));
      expect(saved.first.amount, 500);

      final summary = await repo.loadSummary(DateTime(2026, 8));
      expect(summary, isNotNull);
      expect(summary!.totalDebits, 500);
      expect(summary.transactionCount, 1);
    });
  });
}
