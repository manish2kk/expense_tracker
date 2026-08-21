import '../models/bank_transaction.dart';

class SmsParser {
  static const allowedSenderTokens = ['HSBCIN', 'INDBNK'];
  static final _otpPattern = RegExp(
    r'\b(otp|one[ -]?time password|verification code)\b',
    caseSensitive: false,
  );

  static final _debitPattern = RegExp(
    r'\b(debited|debit|withdrawn|spent|paid|sent|purchase|purchased|deducted|dr)\b',
    caseSensitive: false,
  );

  static final _creditPattern = RegExp(
    r'\b(credited|credit|deposited|received|refund(?:ed)?|cr)\b',
    caseSensitive: false,
  );

  static final _balanceContext = RegExp(
    r'\b(avl(?:\.|ailable)?\s*bal(?:ance)?|available balance|acc(?:ount)?\s*bal(?:ance)?|a/c\s*bal)\b',
    caseSensitive: false,
  );

  static final _keywordAmount = RegExp(
    r'(?:(?:credited|debited|withdrawn|spent|paid|sent|purchase[d]?|deducted|deposited|received|refund(?:ed)?)\s+(?:by|with|for|of|to|from)?\s*)(?:(?:rs\.?|inr|₹)\s*)?([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static final _currencyAmount = RegExp(
    r'(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)',
    caseSensitive: false,
  );

  static BankTransaction? parse({
    required String body,
    required DateTime date,
    String? sender,
  }) {
    if (!isAllowedSender(sender)) {
      return null;
    }
    final text = body.trim();
    if (text.isEmpty || _otpPattern.hasMatch(text)) {
      return null;
    }

    final type = _detectType(text);
    if (type == null) {
      return null;
    }

    final amount = _extractAmount(text);
    if (amount == null || amount <= 0) {
      return null;
    }

    return BankTransaction(
      amount: amount,
      type: type,
      date: date,
      body: text,
      sender: sender,
    );
  }

  static bool isAllowedSender(String? sender) {
    if (sender == null || sender.trim().isEmpty) {
      return false;
    }
    final name = sender.toUpperCase();
    return allowedSenderTokens.any(name.contains);
  }

  static TransactionType? _detectType(String text) {
    final debitMatch = _debitPattern.firstMatch(text);
    final creditMatch = _creditPattern.firstMatch(text);

    if (debitMatch == null && creditMatch == null) {
      return null;
    }
    if (debitMatch == null) {
      return TransactionType.credit;
    }
    if (creditMatch == null) {
      return TransactionType.debit;
    }
    return debitMatch.start <= creditMatch.start
        ? TransactionType.debit
        : TransactionType.credit;
  }

  static double? _extractAmount(String text) {
    final keywordMatch = _keywordAmount.firstMatch(text);
    if (keywordMatch != null) {
      return _toAmount(keywordMatch.group(1)!);
    }

    for (final match in _currencyAmount.allMatches(text)) {
      final start = match.start;
      final prefix = text.substring(0, start);
      if (_balanceContext.hasMatch(prefix.substring(
        prefix.length > 40 ? prefix.length - 40 : 0,
      ))) {
        continue;
      }
      return _toAmount(match.group(1)!);
    }
    return null;
  }

  static double? _toAmount(String raw) {
    return double.tryParse(raw.replaceAll(',', ''));
  }
}
