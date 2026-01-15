// lib/blocs/occasion_detail/occasion_detail_state.dart
import 'package:equatable/equatable.dart';
import '../../models/income.dart';
import '../../models/expense.dart';
import '../../models/summaries.dart';

abstract class OccasionDetailState extends Equatable {
  const OccasionDetailState();

  @override
  List<Object?> get props => [];
}

class OccasionDetailInitial extends OccasionDetailState {}

class OccasionDetailLoading extends OccasionDetailState {}

class OccasionDetailLoaded extends OccasionDetailState {
  final List<Income> incomes;
  final List<Expense> expenses;
  final DetailSummary summary;

  const OccasionDetailLoaded({
    required this.incomes,
    required this.expenses,
    required this.summary,
  });

  @override
  List<Object?> get props => [incomes, expenses, summary];
}

class OccasionDetailError extends OccasionDetailState {
  final String message;

  const OccasionDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
