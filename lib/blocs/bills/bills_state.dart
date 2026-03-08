import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/bill.dart';

class BillsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BillsInitial extends BillsState {}

class BillsLoading extends BillsState {}

class BillsLoaded extends BillsState {
  final List<Bill> bills;

  BillsLoaded({required this.bills});

  @override
  List<Object?> get props => [bills];
}

class BillsError extends BillsState {
  final String message;

  BillsError({required this.message});

  @override
  List<Object?> get props => [message];
}
