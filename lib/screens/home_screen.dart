import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/expense_repository.dart';
import '../models/bank_transaction.dart';
import '../services/balance_store.dart';
import '../services/ledger.dart';
import '../services/sms_service.dart';
import '../widgets/balance_dialog.dart';
import '../widgets/daily_expense_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    this.smsService,
  });

  final ExpenseRepository repository;
  final SmsService? smsService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SmsService _smsService = widget.smsService ?? SmsService();
  final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _monthFormat = DateFormat.yMMMM();

  bool _loading = true;
  SmsAccessState _access = SmsAccessState.denied;
  List<BankTransaction> _transactions = [];
  BalanceSnapshot? _snapshot;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  ExpenseRepository get _repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _repository.ensureReady();
    final sms = await _smsService.readBankSms();
    if (sms.transactions.isNotEmpty) {
      await _repository.upsertTransactions(sms.transactions);
    }
    await _repository.rebuildSummaries();
    final snapshot = await _repository.loadSnapshot();
    final transactions = await _repository.loadTransactions();
    if (!mounted) {
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _access = sms.state;
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _editBalance() async {
    final amount = await showSetBalanceDialog(
      context,
      current: _snapshot?.amount,
    );
    if (amount == null) {
      return;
    }
    await _repository.saveSnapshot(amount);
    await _repository.rebuildSummaries();
    final snapshot = await _repository.loadSnapshot();
    if (!mounted) {
      return;
    }
    setState(() => _snapshot = snapshot);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ledger = Ledger(
      transactions: _transactions,
      snapshotBalance: _snapshot?.amount,
      snapshotAt: _snapshot?.asOf,
    );
    final monthTxs = ledger.inMonth(_month);
    final credits = ledger.totalCredits(monthTxs);
    final debits = ledger.totalDebits(monthTxs);
    final monthlyBalance = ledger.monthlyBalance(_month, DateTime.now());
    final opening = ledger.openingBalance(_month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            tooltip: 'Set bank balance',
            onPressed: _editBalance,
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            tooltip: 'Refresh SMS',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _AccessBanner(state: _access),
                  _MonthHeader(
                    label: _monthFormat.format(_month),
                    onPrev: () => _shiftMonth(-1),
                    onNext: () => _shiftMonth(1),
                  ),
                  const SizedBox(height: 8),
                  _BalanceCard(
                    money: _money,
                    current: _snapshot?.amount,
                    monthly: monthlyBalance,
                    opening: opening,
                    onSetBalance: _editBalance,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Credited',
                          value: _money.format(credits),
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Debited',
                          value: _money.format(debits),
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daily credit & expense',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: DailyExpenseChart(
                        dailyTotals: ledger.dailyTotals(_month),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (monthTxs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('No credited or debited amounts found for this month.'),
                    )
                  else
                    ...monthTxs.map(
                      (tx) => _TransactionTile(transaction: tx, money: _money),
                    ),
                ],
              ),
            ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.state});

  final SmsAccessState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case SmsAccessState.granted:
        return const SizedBox.shrink();
      case SmsAccessState.unsupported:
        return const _InfoBanner(
          text: 'SMS inbox access is available on Android phones only.',
        );
      case SmsAccessState.denied:
        return _InfoBanner(
          text: 'Allow SMS permission so bank messages can be read.',
          actionLabel: 'Open settings',
          onAction: openAppSettings,
        );
    }
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: Text(text)),
            if (actionLabel != null)
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.money,
    required this.current,
    required this.monthly,
    required this.opening,
    required this.onSetBalance,
  });

  final NumberFormat money;
  final double? current;
  final double? monthly;
  final double? opening;
  final VoidCallback onSetBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly balance', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              monthly == null ? 'Set current bank balance' : money.format(monthly),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (current != null)
              Text('Entered bank balance: ${money.format(current)}'),
            if (opening != null)
              Text('Month opening: ${money.format(opening)}'),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onSetBalance,
                child: Text(current == null ? 'Enter bank balance' : 'Update bank balance'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.money,
  });

  final BankTransaction transaction;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? Colors.green.shade50 : Colors.red.shade50,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
        title: Text(
          '${isCredit ? 'Credited' : 'Debited'} ${money.format(transaction.amount)}',
        ),
        subtitle: Text(
          [
            DateFormat.MMMd().add_jm().format(transaction.date),
            if (transaction.sender != null) transaction.sender!,
          ].join(' · '),
        ),
      ),
    );
  }
}
