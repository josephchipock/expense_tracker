// lib/blocs/occasions/occasions_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/database_repository.dart';
import 'occasions_event.dart';
import 'occasions_state.dart';

class OccasionsBloc extends Bloc<OccasionsEvent, OccasionsState> {
  final DatabaseRepository repository;

  OccasionsBloc({required this.repository}) : super(OccasionsInitial()) {
    on<LoadOccasions>(_onLoadOccasions);
    on<CreateOccasion>(_onCreateOccasion);
    on<UpdateOccasion>(_onUpdateOccasion);
    on<DeleteOccasion>(_onDeleteOccasion);
    on<FilterOccasionsByDate>(_onFilterOccasionsByDate);
  }

  Future<void> _onLoadOccasions(
    LoadOccasions event,
    Emitter<OccasionsState> emit,
  ) async {
    emit(OccasionsLoading());
    try {
      final occasions = await repository.getOccasionsWithTotals(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final summary = await repository.getGeneralSummary(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final homeElements = await repository.getHomeListElements(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(OccasionsLoaded(
        occasions: occasions,
        generalSummary: summary,
        homeElements: homeElements,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
    } catch (e) {
      emit(OccasionsError(e.toString()));
    }
  }

  Future<void> _onCreateOccasion(
    CreateOccasion event,
    Emitter<OccasionsState> emit,
  ) async {
    try {
      await repository.createOccasion(
          event.name, event.description, event.occasionDate);
      add(const LoadOccasions());
    } catch (e) {
      emit(OccasionsError(e.toString()));
    }
  }

  Future<void> _onUpdateOccasion(
    UpdateOccasion event,
    Emitter<OccasionsState> emit,
  ) async {
    try {
      await repository.updateOccasion(
          event.id, event.name, event.description, event.occasionDate);
      add(const LoadOccasions());
    } catch (e) {
      emit(OccasionsError(e.toString()));
    }
  }

  Future<void> _onDeleteOccasion(
    DeleteOccasion event,
    Emitter<OccasionsState> emit,
  ) async {
    try {
      await repository.deleteOccasion(event.id);
      add(const LoadOccasions());
    } catch (e) {
      emit(OccasionsError(e.toString()));
    }
  }

  Future<void> _onFilterOccasionsByDate(
    FilterOccasionsByDate event,
    Emitter<OccasionsState> emit,
  ) async {
    add(LoadOccasions(startDate: event.startDate, endDate: event.endDate));
  }
}
