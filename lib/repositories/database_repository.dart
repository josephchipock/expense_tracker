// lib/repositories/database_repository.dart
import '../config/supabase_config.dart';
import '../models/occasion.dart';
import '../models/summaries.dart';
import '../models/expense_category.dart';
import '../models/income.dart';
import '../models/expense.dart';

class DatabaseRepository {
  final _client = SupabaseConfig.client;

  // ==================== OCCASIONS ====================

  Future<List<OccasionSummary>> getOccasionsWithTotals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_occasions_with_totals', params: {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    });

    return (response as List)
        .map((json) => OccasionSummary.fromJson(json))
        .toList();
  }

  Future<Occasion> createOccasion(
      String name, String? description, DateTime? occasionDate) async {
    final response = await _client
        .from('occasions')
        .insert({
          'user_id': _client.auth.currentUser!.id,
          'name': name,
          'description': description,
          'occasion_date': occasionDate?.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    return Occasion.fromJson(response);
  }

  Future<Occasion> updateOccasion(
    String id,
    String name,
    String? description,
    DateTime? occasionDate,
  ) async {
    final response = await _client
        .from('occasions')
        .update({
          'name': name,
          'description': description,
          'occasion_date': occasionDate?.toIso8601String().split('T')[0],
        })
        .eq('id', id)
        .select()
        .single();

    return Occasion.fromJson(response);
  }

  Future<void> deleteOccasion(String id) async {
    await _client.from('occasions').delete().eq('id', id);
  }

  // ==================== CATEGORIES ====================

  Future<List<ExpenseCategory>> getCategories() async {
    final response = await _client
        .from('expense_categories')
        .select()
        .order('is_predefined', ascending: false)
        .order('name');

    return (response as List)
        .map((json) => ExpenseCategory.fromJson(json))
        .toList();
  }

  Future<ExpenseCategory> createCategory(
    String name, {
    bool isPredefined = false,
  }) async {
    final response = await _client
        .from('expense_categories')
        .insert({
          'user_id': _client.auth.currentUser!.id,
          'name': name,
          'is_predefined': isPredefined,
        })
        .select()
        .single();

    return ExpenseCategory.fromJson(response);
  }

  Future<void> initializePredefinedCategories() async {
    final predefinedCategories = [
      'Alimentación',
      'Transporte',
      'Servicios',
      'Entretenimiento',
      'Salud',
      'Educación',
      'Ropa',
      'Hogar',
      'Otros',
    ];

    for (final category in predefinedCategories) {
      try {
        await createCategory(category, isPredefined: true);
      } catch (e) {
        // Ignorar si ya existe
      }
    }
  }

  Future<void> deleteCategory(String id) async {
    await _client.from('expense_categories').delete().eq('id', id);
  }

  // ==================== INCOMES ====================

  Future<List<Income>> getIncomes(String occasionId) async {
    final response = await _client
        .from('incomes')
        .select()
        .eq('occasion_id', occasionId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Income.fromJson(json)).toList();
  }

  Future<Income> createIncome(
    String occasionId,
    double amount,
    String? description,
  ) async {
    final response = await _client
        .from('incomes')
        .insert({
          'occasion_id': occasionId,
          'amount': amount,
          'description': description,
        })
        .select()
        .single();

    return Income.fromJson(response);
  }

  Future<Income> updateIncome(
    String id,
    double amount,
    String? description,
  ) async {
    final response = await _client
        .from('incomes')
        .update({
          'amount': amount,
          'description': description,
        })
        .eq('id', id)
        .select()
        .single();

    return Income.fromJson(response);
  }

  Future<void> deleteIncome(String id) async {
    await _client.from('incomes').delete().eq('id', id);
  }

  // ==================== EXPENSES ====================

  Future<List<Expense>> getExpenses(String occasionId) async {
    final response = await _client
        .from('expenses')
        .select()
        .eq('occasion_id', occasionId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  Future<Expense> createExpense(
    String occasionId,
    double amount,
    String? categoryId,
    String? description,
  ) async {
    final response = await _client
        .from('expenses')
        .insert({
          'occasion_id': occasionId,
          'amount': amount,
          'category_id': categoryId,
          'description': description,
        })
        .select()
        .single();

    return Expense.fromJson(response);
  }

  Future<Expense> updateExpense(
    String id,
    double amount,
    String? categoryId,
    String? description,
  ) async {
    final response = await _client
        .from('expenses')
        .update({
          'amount': amount,
          'category_id': categoryId,
          'description': description,
        })
        .eq('id', id)
        .select()
        .single();

    return Expense.fromJson(response);
  }

  Future<void> deleteExpense(String id) async {
    await _client.from('expenses').delete().eq('id', id);
  }

  // ==================== SUMMARIES ====================

  Future<DetailSummary> getOccasionSummary(String occasionId) async {
    final response = await _client.rpc('get_occasion_summary', params: {
      'occasion_uuid': occasionId,
    });

    if (response == null || (response as List).isEmpty) {
      return const DetailSummary(
        totalIncome: 0.0,
        totalExpense: 0.0,
        profit: 0.0,
      );
    }

    final data = response[0];
    return DetailSummary(
      totalIncome: (data['total_income'] as num).toDouble(),
      totalExpense: (data['total_expense'] as num).toDouble(),
      profit: (data['profit'] as num).toDouble(),
    );
  }

  Future<GeneralSummary> getGeneralSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.rpc('get_general_summary', params: {
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    });

    if (response == null || (response as List).isEmpty) {
      return const GeneralSummary(
        totalIncome: 0.0,
        totalExpense: 0.0,
        profit: 0.0,
        occasionsCount: 0,
      );
    }

    return GeneralSummary.fromJson(response[0]);
  }
}
