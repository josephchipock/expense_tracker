import 'package:equatable/equatable.dart';

class Occasion extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime? occasionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Occasion({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.occasionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Occasion.fromJson(Map<String, dynamic> json) {
    return Occasion(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      occasionDate: json['occasion_date'] != null
          ? DateTime.parse(json['occasion_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'occasion_date': occasionDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, name, description, occasionDate, createdAt, updatedAt];
}
