import 'package:equatable/equatable.dart';

enum HomeElementType { occasion, generalExpense }

class HomeListElement extends Equatable {
  final HomeElementType type;
  final String id;
  final DateTime createdAt;
  final String? name;
  final String? description;
  final DateTime? occasionDate;
  final double? amount;
  final String? categoryId;
  final String? categoryName;

  const HomeListElement({
    required this.type,
    required this.id,
    required this.createdAt,
    this.name,
    this.description,
    this.occasionDate,
    this.amount,
    this.categoryId,
    this.categoryName,
  });

  factory HomeListElement.fromJson(Map<String, dynamic> json) {
    final t = (json['type'] as String).toLowerCase();
    final mappedType = t == 'occasion'
        ? HomeElementType.occasion
        : HomeElementType.generalExpense;
    return HomeListElement(
      type: mappedType,
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      description: json['description'],
      occasionDate: json['occasion_date'] != null
          ? DateTime.parse(json['occasion_date'])
          : null,
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }

  @override
  List<Object?> get props => [
        type,
        id,
        createdAt,
        name,
        description,
        occasionDate,
        amount,
        categoryId,
        categoryName,
      ];
}
