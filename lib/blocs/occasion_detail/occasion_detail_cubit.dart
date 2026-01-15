// lib/blocs/occasion_detail/occasion_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/database_repository.dart';
import 'occasion_detail_state.dart';

class OccasionDetailCubit extends Cubit<OccasionDetailState> {
  final DatabaseRepository repository;
  final String occasionId;

  OccasionDetailCubit({
    required this.repository,
    required this.occasionId,
  }) : super(OccasionDetailInitial());

  Future<void> loadDetails() async {
    emit(OccasionDetailLoading());
    try {
      final incomes = await repository.getIncomes(occasionId);
      final expenses = await repository.getExpenses(occasionId);
      final summary = await repository.getOccasionSummary(occasionId);

      emit(OccasionDetailLoaded(
        incomes: incomes,
        expenses: expenses,
        summary: summary,
      ));
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> createIncome(double amount, String? description) async {
    try {
      await repository.createIncome(occasionId, amount, description);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> updateIncome(
      String id, double amount, String? description) async {
    try {
      await repository.updateIncome(id, amount, description);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await repository.deleteIncome(id);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> createExpense(
    double amount,
    String? categoryId,
    String? description,
  ) async {
    try {
      await repository.createExpense(
          occasionId, amount, categoryId, description);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> updateExpense(
    String id,
    double amount,
    String? categoryId,
    String? description,
  ) async {
    try {
      await repository.updateExpense(id, amount, categoryId, description);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await repository.deleteExpense(id);
      await loadDetails();
    } catch (e) {
      emit(OccasionDetailError(e.toString()));
    }
  }
}
