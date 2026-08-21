class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.totalCredits,
    required this.totalDebits,
    required this.transactionCount,
    required this.updatedAt,
    this.openingBalance,
    this.closingBalance,
  });

  final int year;
  final int month;
  final double totalCredits;
  final double totalDebits;
  final int transactionCount;
  final DateTime updatedAt;
  final double? openingBalance;
  final double? closingBalance;

  DateTime get monthDate => DateTime(year, month);
}
