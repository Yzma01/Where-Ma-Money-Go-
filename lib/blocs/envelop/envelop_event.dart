import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/envelop.dart';

abstract class EnvelopEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadEnvelops extends EnvelopEvent {}

class CreateEnvelop extends EnvelopEvent {
  final Envelop envelop;
  CreateEnvelop({required this.envelop});
  @override
  List<Object?> get props => [envelop];
}

class UpdateEnvelop extends EnvelopEvent {
  final Envelop envelop;
  UpdateEnvelop({required this.envelop});
  @override
  List<Object?> get props => [envelop];
}

class DeleteEnvelop extends EnvelopEvent {
  final String envelopId;
  DeleteEnvelop({required this.envelopId});
  @override
  List<Object?> get props => [envelopId];
}

/// Depositar dinero al sobre (egreso de cuenta principal)
class DepositToEnvelop extends EnvelopEvent {
  final String envelopId;
  final double amount;
  final String note;
  DepositToEnvelop({
    required this.envelopId,
    required this.amount,
    this.note = '',
  });
  @override
  List<Object?> get props => [envelopId, amount, note];
}

/// Retirar dinero del sobre (ingreso a cuenta principal)
class WithdrawFromEnvelop extends EnvelopEvent {
  final String envelopId;
  final double amount;
  final String note;
  WithdrawFromEnvelop({
    required this.envelopId,
    required this.amount,
    this.note = '',
  });
  @override
  List<Object?> get props => [envelopId, amount, note];
}
