// lib/blocs/general_expenses/general_expenses_cubit.dart
import 'package:expense_tracker/blocs/general_expenses/general_expenses_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/database_repository.dart';

class GeneralExpensesCubit extends Cubit<GeneralExpensesState> {
  final DatabaseRepository repository;

  GeneralExpensesCubit({required this.repository})
      : super(GeneralExpensesInitial());

  Future<void> loadGeneralExpenses(
      {DateTime? startDate, DateTime? endDate}) async {
    emit(GeneralExpensesLoading());
    try {
      final expenses = await repository.getGeneralExpenses(
          startDate: startDate, endDate: endDate);
      emit(GeneralExpensesLoaded(expenses));
    } catch (e) {
      emit(GeneralExpensesError(e.toString()));
    }
  }

  Future<void> createGeneralExpense(
      double amount, String? categoryId, String? description,
      {DateTime? createdAt}) async {
    try {
      await repository.createGeneralExpense(amount, categoryId, description,
          createdAt: createdAt);
      await loadGeneralExpenses(startDate: createdAt, endDate: createdAt);
    } catch (e) {
      emit(GeneralExpensesError(e.toString()));
    }
  }

  Future<void> updateGeneralExpense(
      String id, double amount, String? categoryId, String? description,
      {DateTime? createdAt}) async {
    try {
      await repository.updateGeneralExpense(id, amount, categoryId, description,
          createdAt: createdAt);
      await loadGeneralExpenses(startDate: createdAt, endDate: createdAt);
    } catch (e) {
      emit(GeneralExpensesError(e.toString()));
    }
  }

  Future<void> deleteGeneralExpense(String id) async {
    try {
      await repository.deleteGeneralExpense(id);
      await loadGeneralExpenses();
    } catch (e) {
      emit(GeneralExpensesError(e.toString()));
    }
  }
}
