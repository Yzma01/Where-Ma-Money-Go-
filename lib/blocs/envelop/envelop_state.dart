import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/envelop.dart';

abstract class EnvelopState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EnvelopInitial extends EnvelopState {}

class EnvelopLoading extends EnvelopState {}

class EnvelopLoaded extends EnvelopState {
  final List<Envelop> envelops;
  EnvelopLoaded({required this.envelops});
  @override
  List<Object?> get props => [envelops];
}

class EnvelopError extends EnvelopState {
  final String message;
  EnvelopError({required this.message});
  @override
  List<Object?> get props => [message];
}
