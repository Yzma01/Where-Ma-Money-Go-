import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/bill.dart';

abstract class BillsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBills extends BillsEvent {}

class AddBill extends BillsEvent {
  final Bill bill;

  AddBill({required this.bill});

  @override
  List<Object?> get props => [bill];
}

class UpdateBill extends BillsEvent {
  final Bill bill;
  UpdateBill({required this.bill});

  @override
  List<Object?> get props => [bill];
}

class DeleteBill extends BillsEvent {
  final String id;

  DeleteBill({required this.id});

  @override
  List<Object?> get props => [id];
}
