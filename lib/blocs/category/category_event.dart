import 'package:equatable/equatable.dart';
import 'package:where_ma_money_go/models/category.dart';

abstract class CategoryEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final Categories category;

  AddCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

class UpdateCategory extends CategoryEvent {
  final Categories category;
  UpdateCategory({required this.category});

  @override
  List<Object?> get props => [category];
}

class DeleteCategory extends CategoryEvent {
  final String id;
  DeleteCategory({required this.id});
  @override
  List<Object?> get props => [id];
}
