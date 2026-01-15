// lib/models/income.dart
import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final String id;
  final String occasionId;
  final double amount;
  final String? description;
  final DateTime createdAt;

  const Income({
    required this.id,
    required this.occasionId,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      occasionId: json['occasion_id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'occasion_id': occasionId,
      'amount': amount,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, occasionId, amount, description, createdAt];
}
