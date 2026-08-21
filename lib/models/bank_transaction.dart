enum TransactionType { credit, debit }

class BankTransaction {
  const BankTransaction({
    required this.amount,
    required this.type,
    required this.date,
    required this.body,
    this.sender,
  });

  final double amount;
  final TransactionType type;
  final DateTime date;
  final String body;
  final String? sender;

  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;

  double get signedAmount => isCredit ? amount : -amount;

  String get fingerprint =>
      '${date.millisecondsSinceEpoch}|$amount|${type.name}|${sender ?? ''}|$body';
}
