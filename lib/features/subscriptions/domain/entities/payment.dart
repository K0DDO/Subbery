import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.amountInCents,
    required this.date,
  });

  final String id;
  final String subscriptionId;
  final int amountInCents;
  final DateTime date;

  double get amount => amountInCents / 100;

  @override
  List<Object> get props => <Object>[id, subscriptionId, amountInCents, date];
}
