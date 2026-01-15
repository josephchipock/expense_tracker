// lib/blocs/occasions/occasions_state.dart
import 'package:equatable/equatable.dart';
import '../../models/summaries.dart';

abstract class OccasionsState extends Equatable {
  const OccasionsState();

  @override
  List<Object?> get props => [];
}

class OccasionsInitial extends OccasionsState {}

class OccasionsLoading extends OccasionsState {}

class OccasionsLoaded extends OccasionsState {
  final List<OccasionSummary> occasions;
  final GeneralSummary generalSummary;
  final DateTime? startDate;
  final DateTime? endDate;

  const OccasionsLoaded({
    required this.occasions,
    required this.generalSummary,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [occasions, generalSummary, startDate, endDate];
}

class OccasionsError extends OccasionsState {
  final String message;

  const OccasionsError(this.message);

  @override
  List<Object?> get props => [message];
}
