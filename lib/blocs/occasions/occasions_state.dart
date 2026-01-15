// lib/blocs/occasions/occasions_state.dart
import 'package:equatable/equatable.dart';
import '../../models/summaries.dart';
import '../../models/home_list_element.dart';

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
  final List<HomeListElement> homeElements;

  const OccasionsLoaded({
    required this.occasions,
    required this.generalSummary,
    required this.homeElements,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [occasions, generalSummary, startDate, endDate, homeElements];
}

class OccasionsError extends OccasionsState {
  final String message;

  const OccasionsError(this.message);

  @override
  List<Object?> get props => [message];
}
