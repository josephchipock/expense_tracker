// lib/models/summaries.dart
import 'package:equatable/equatable.dart';

class OccasionSummary extends Equatable {
  final String id;
  final String name;
  final String? description;
  final DateTime? occasionDate;
  final DateTime createdAt;
  final double totalIncome;
  final double totalExpense;
  final double profit;

  const OccasionSummary({
    required this.id,
    required this.name,
    this.description,
    this.occasionDate,
    required this.createdAt,
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
  });

  factory OccasionSummary.fromJson(Map<String, dynamic> json) {
    return OccasionSummary(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      occasionDate: json['occasion_date'] != null
          ? DateTime.parse(json['occasion_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        occasionDate,
        createdAt,
        totalIncome,
        totalExpense,
        profit
      ];
}

class GeneralSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double profit;
  final int occasionsCount;

  const GeneralSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
    required this.occasionsCount,
  });

  factory GeneralSummary.fromJson(Map<String, dynamic> json) {
    return GeneralSummary(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
      occasionsCount: json['occasions_count'] as int,
    );
  }

  @override
  List<Object?> get props =>
      [totalIncome, totalExpense, profit, occasionsCount];
}

class DetailSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double profit;

  const DetailSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.profit,
  });

  @override
  List<Object?> get props => [totalIncome, totalExpense, profit];
}
