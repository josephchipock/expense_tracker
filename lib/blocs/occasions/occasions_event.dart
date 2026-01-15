// lib/blocs/occasions/occasions_event.dart
import 'package:equatable/equatable.dart';

abstract class OccasionsEvent extends Equatable {
  const OccasionsEvent();

  @override
  List<Object?> get props => [];
}

class LoadOccasions extends OccasionsEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadOccasions({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class CreateOccasion extends OccasionsEvent {
  final String name;
  final String? description;
  final DateTime? occasionDate;

  const CreateOccasion({
    required this.name,
    this.description,
    this.occasionDate,
  });

  @override
  List<Object?> get props => [name, description, occasionDate];
}

class UpdateOccasion extends OccasionsEvent {
  final String id;
  final String name;
  final String? description;
  final DateTime? occasionDate;

  const UpdateOccasion({
    required this.id,
    required this.name,
    this.description,
    this.occasionDate,
  });

  @override
  List<Object?> get props => [id, name, description, occasionDate];
}

class DeleteOccasion extends OccasionsEvent {
  final String id;

  const DeleteOccasion(this.id);

  @override
  List<Object?> get props => [id];
}

class FilterOccasionsByDate extends OccasionsEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterOccasionsByDate({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
