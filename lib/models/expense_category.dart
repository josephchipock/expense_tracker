// lib/models/expense_category.dart
import 'package:equatable/equatable.dart';

class ExpenseCategory extends Equatable {
  final String id;
  final String userId;
  final String name;
  final bool isPredefined;
  final DateTime createdAt;

  const ExpenseCategory({
    required this.id,
    required this.userId,
    required this.name,
    required this.isPredefined,
    required this.createdAt,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      isPredefined: json['is_predefined'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_predefined': isPredefined,
    };
  }

  @override
  List<Object?> get props => [id, userId, name, isPredefined, createdAt];
}
