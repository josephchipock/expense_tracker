// lib/blocs/general_expenses/general_expenses_state.dart
import 'package:equatable/equatable.dart';

abstract class GeneralExpensesState extends Equatable {
  const GeneralExpensesState();

  @override
  List<Object?> get props => [];
}

class GeneralExpensesInitial extends GeneralExpensesState {}

class GeneralExpensesLoading extends GeneralExpensesState {}

class GeneralExpensesLoaded extends GeneralExpensesState {
  final List<dynamic> expenses;

  const GeneralExpensesLoaded(this.expenses);

  @override
  List<Object?> get props => [expenses];
}

class GeneralExpensesError extends GeneralExpensesState {
  final String message;

  const GeneralExpensesError(this.message);

  @override
  List<Object?> get props => [message];
}
