// lib/models/expense.dart
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String occasionId;
  final String? categoryId;
  final double amount;
  final String? description;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.occasionId,
    this.categoryId,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      occasionId: json['occasion_id'],
      categoryId: json['category_id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'occasion_id': occasionId,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
    };
  }

  @override
  List<Object?> get props =>
      [id, occasionId, categoryId, amount, description, createdAt];
}
