import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/saving.dart';

class SavingState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavingInitial extends SavingState {}

class SavingLoading extends SavingState {}

class SavingLoaded extends SavingState {
  final List<Saving> savings;

  SavingLoaded({required this.savings});

  @override
  List<Object?> get props => [savings];
}

class SavingError extends SavingState {
  final String message;

  SavingError({required this.message});

  @override
  List<Object?> get props => [message];
}
