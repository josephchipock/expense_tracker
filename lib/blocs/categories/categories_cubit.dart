// lib/blocs/categories/categories_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/database_repository.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final DatabaseRepository repository;

  CategoriesCubit({required this.repository}) : super(CategoriesInitial());

  Future<void> loadCategories() async {
    emit(CategoriesLoading());
    try {
      final categories = await repository.getCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> createCategory(String name) async {
    try {
      await repository.createCategory(name);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
