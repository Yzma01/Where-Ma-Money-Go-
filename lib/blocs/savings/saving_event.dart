import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/saving.dart';

abstract class SavingEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadSavings extends SavingEvent {}

class AddSaving extends SavingEvent {
  final Saving saving;

  AddSaving({required this.saving});

  @override
  List<Object?> get props => [saving];
}

class UpdateSaving extends SavingEvent {
  final Saving saving;
  UpdateSaving({required this.saving});

  @override
  List<Object?> get props => [saving];
}

class DeleteSaving extends SavingEvent {
  final String id;

  DeleteSaving({required this.id});

  @override
  List<Object?> get props => [id];

  get savingId => null;
}
