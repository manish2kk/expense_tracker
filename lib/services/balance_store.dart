import 'package:shared_preferences/shared_preferences.dart';

class BalanceSnapshot {
  const BalanceSnapshot({required this.amount, required this.asOf});

  final double amount;
  final DateTime asOf;
}

class BalanceStore {
  static const _amountKey = 'current_bank_balance';
  static const _asOfKey = 'current_bank_balance_as_of';

  Future<BalanceSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final amount = prefs.getDouble(_amountKey);
    final asOfMs = prefs.getInt(_asOfKey);
    if (amount == null || asOfMs == null) {
      return null;
    }
    return BalanceSnapshot(
      amount: amount,
      asOf: DateTime.fromMillisecondsSinceEpoch(asOfMs),
    );
  }

  Future<void> save(double amount, {DateTime? asOf}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_amountKey, amount);
    await prefs.setInt(
      _asOfKey,
      (asOf ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }
}
