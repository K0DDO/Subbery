class MonthlySpendPoint {
  const MonthlySpendPoint({
    required this.month,
    required this.amountInCents,
    this.plannedAmountInCents = 0,
  });

  final DateTime month;

  /// Actual payments recorded during the month.
  final int amountInCents;

  /// Expected charges generated from active subscription schedules.
  final int plannedAmountInCents;
}
