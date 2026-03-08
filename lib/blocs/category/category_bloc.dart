import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:where_ma_money_go/blocs/category/category_event.dart';
import 'package:where_ma_money_go/blocs/category/category_state.dart';
import 'package:where_ma_money_go/repositories/category_repository.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository categoryRepository;

  CategoryBloc({required this.categoryRepository}) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await categoryRepository.getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.addCategory(event.category);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.updateCategory(event.category);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await categoryRepository.deleteCategory(event.id);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }
}
