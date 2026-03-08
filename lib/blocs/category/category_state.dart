import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/category.dart';

class CategoryState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<Categories> categories;
  CategoryLoaded({required this.categories});
  @override
  List<Object?> get props => [categories];
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError({required this.message});
  @override
  List<Object?> get props => [message];
}
