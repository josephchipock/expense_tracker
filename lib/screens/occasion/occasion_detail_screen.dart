import 'package:expense_tracker/models/expense.dart'; // Ensure this matches your project structure
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../repositories/database_repository.dart';
import '../../blocs/occasion_detail/occasion_detail_cubit.dart';
import '../../blocs/occasion_detail/occasion_detail_state.dart';
import '../../blocs/categories/categories_cubit.dart';
import '../../blocs/categories/categories_state.dart';

class OccasionDetailScreen extends StatelessWidget {
  final String occasionId;
  final String occasionName;

  const OccasionDetailScreen({
    super.key,
    required this.occasionId,
    required this.occasionName,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => OccasionDetailCubit(
            repository: context.read<DatabaseRepository>(),
            occasionId: occasionId,
          )..loadDetails(),
        ),
        BlocProvider(
          create: (context) => CategoriesCubit(
            repository: context.read<DatabaseRepository>(),
          )..loadCategories(),
        ),
      ],
      child: _OccasionDetailContent(occasionName: occasionName),
    );
  }
}

class _OccasionDetailContent extends StatefulWidget {
  final String occasionName;

  const _OccasionDetailContent({required this.occasionName});

  @override
  State<_OccasionDetailContent> createState() => _OccasionDetailContentState();
}

class _OccasionDetailContentState extends State<_OccasionDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Update UI when tab changes (drag or tap)
      if (_tabController.index != _currentTabIndex &&
          !_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
      // Handle animation value for immediate feedback
      if (_tabController.animation!.value.round() != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.animation!.value.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- MODAL SHEETS (Creation & Editing) ---

  void _showTransactionSheet(BuildContext ctx, {required bool isExpense}) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final newCategoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId;

    final themeColor = isExpense ? Colors.redAccent : Colors.green;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: ctx.read<CategoriesCubit>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isExpense ? 'Nuevo Gasto' : 'Nuevo Ingreso',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: amountController,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: themeColor.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.attach_money, color: themeColor),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (double.tryParse(value) == null) return 'Inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isExpense)
                    BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        return StatefulBuilder(
                          builder: (context, setStateDropdown) {
                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'Categoría',
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon:
                                        const Icon(Icons.category_outlined),
                                  ),
                                  items: [
                                    if (state is CategoriesLoaded)
                                      ...state.categories
                                          .map((cat) => DropdownMenuItem(
                                                value: cat.id,
                                                child: Text(cat.name),
                                              )),
                                    const DropdownMenuItem(
                                      value: 'new',
                                      child: Text('+ Crear nueva categoría'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStateDropdown(
                                        () => selectedCategoryId = value);
                                  },
                                ),
                                if (selectedCategoryId == 'new') ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: newCategoryController,
                                    decoration: InputDecoration(
                                      labelText: 'Nombre de la categoría',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      prefixIcon:
                                          const Icon(Icons.label_outline),
                                    ),
                                    validator: (val) =>
                                        val!.isEmpty ? 'Requerido' : null,
                                  ),
                                ],
                              ],
                            );
                          },
                        );
                      },
                    ),
                  if (isExpense) const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final amount = double.parse(amountController.text);
                          final desc = descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text;

                          if (isExpense) {
                            String? categoryId = selectedCategoryId;
                            if (selectedCategoryId == 'new') {
                              final newCat = await ctx
                                  .read<DatabaseRepository>()
                                  .createCategory(newCategoryController.text);
                              categoryId = newCat.id;
                              ctx.read<CategoriesCubit>().loadCategories();
                            }
                            await ctx
                                .read<OccasionDetailCubit>()
                                .createExpense(amount, categoryId, desc);
                          } else {
                            await ctx
                                .read<OccasionDetailCubit>()
                                .createIncome(amount, desc);
                          }

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(isExpense
                                    ? 'Gasto agregado'
                                    : 'Ingreso agregado'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: themeColor,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        }
                      },
                      child:
                          const Text('Guardar', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditExpenseSheet(BuildContext ctx, dynamic expense) {
    final amountController =
        TextEditingController(text: expense.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: expense.description ?? '');
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId = expense.categoryId;
    final newCategoryController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: ctx.read<CategoriesCubit>(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Editar Gasto',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: amountController,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: Colors.redAccent.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: Colors.redAccent),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requerido';
                      if (double.tryParse(value) == null) return 'Inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                      return StatefulBuilder(
                        builder: (context, setStateDropdown) {
                          return Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: (state is CategoriesLoaded &&
                                        (selectedCategoryId == null ||
                                            selectedCategoryId == 'new' ||
                                            state.categories.any((c) =>
                                                c.id == selectedCategoryId)))
                                    ? selectedCategoryId
                                    : null,
                                decoration: InputDecoration(
                                  labelText: 'Categoría',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.category_outlined),
                                ),
                                items: [
                                  if (state is CategoriesLoaded)
                                    ...state.categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat.id,
                                              child: Text(cat.name),
                                            )),
                                  const DropdownMenuItem(
                                    value: 'new',
                                    child: Text('+ Crear nueva categoría'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setStateDropdown(
                                      () => selectedCategoryId = value);
                                },
                              ),
                              if (selectedCategoryId == 'new') ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: newCategoryController,
                                  decoration: InputDecoration(
                                    labelText: 'Nombre de la categoría',
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    prefixIcon: const Icon(Icons.label_outline),
                                  ),
                                  validator: (val) =>
                                      val!.isEmpty ? 'Requerido' : null,
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción (Opcional)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.notes),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          var categoryId = selectedCategoryId;
                          if (selectedCategoryId == 'new') {
                            final newCat = await ctx
                                .read<DatabaseRepository>()
                                .createCategory(newCategoryController.text);
                            categoryId = newCat.id;
                            ctx.read<CategoriesCubit>().loadCategories();
                          }
                          final amount = double.parse(amountController.text);
                          final desc = descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text;
                          await ctx.read<OccasionDetailCubit>().updateExpense(
                              expense.id, amount, categoryId, desc);
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Gasto actualizado'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Guardar cambios',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditIncomeSheet(BuildContext ctx, dynamic income) {
    final amountController =
        TextEditingController(text: income.amount.toStringAsFixed(2));
    final descriptionController =
        TextEditingController(text: income.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Editar Ingreso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: Colors.green.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon:
                        const Icon(Icons.attach_money, color: Colors.green),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Requerido';
                    if (double.tryParse(value) == null) return 'Inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (Opcional)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final amount = double.parse(amountController.text);
                        final desc = descriptionController.text.isEmpty
                            ? null
                            : descriptionController.text;
                        await ctx
                            .read<OccasionDetailCubit>()
                            .updateIncome(income.id, amount, desc);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Ingreso actualizado'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Guardar cambios',
                        style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            expandedHeight: 200, // Reduced height (No bottom TabBar)
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.8),
                          Colors.purple.shade400,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child:
                          BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
                        builder: (context, state) {
                          double balance = 0;
                          if (state is OccasionDetailLoaded) {
                            balance = state.summary.profit;
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Balance Total",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currencyFormat.format(balance),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().scale(
                                  duration: 400.ms, curve: Curves.easeOutBack),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
              title: Text(
                widget.occasionName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            // Removed bottom: TabBar(...)
          ),
        ],
        body: Column(
          children: [
            // --- CUSTOM TAB CARDS AREA ---
            // These Cards act as the TabBar
            BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
              builder: (context, state) {
                double income = 0;
                double expense = 0;
                if (state is OccasionDetailLoaded) {
                  income = state.summary.totalIncome;
                  expense = state.summary.totalExpense;
                }

                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Income Tab Card
                      Expanded(
                        child: _CustomTabCard(
                          title: 'Ingresos',
                          amount: income,
                          icon: Icons.arrow_upward,
                          color: Colors.green,
                          isSelected: _currentTabIndex == 0,
                          onTap: () {
                            _tabController.animateTo(0);
                            setState(() => _currentTabIndex = 0);
                          },
                          format: _currencyFormat,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Expense Tab Card
                      Expanded(
                        child: _CustomTabCard(
                          title: 'Gastos',
                          amount: expense,
                          icon: Icons.arrow_downward,
                          color: Colors.redAccent,
                          isSelected: _currentTabIndex == 1,
                          onTap: () {
                            _tabController.animateTo(1);
                            setState(() => _currentTabIndex = 1);
                          },
                          format: _currencyFormat,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // --- LIST CONTENT ---
            Expanded(
              child: BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
                builder: (context, state) {
                  if (state is OccasionDetailLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is OccasionDetailLoaded) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _TransactionList(
                          items: state.incomes,
                          currencyFormat: _currencyFormat,
                          isExpense: false,
                          onEditIncome: (income) {
                            _showEditIncomeSheet(context, income);
                          },
                        ),
                        _TransactionList(
                          items: state.expenses,
                          currencyFormat: _currencyFormat,
                          isExpense: true,
                          onEditExpense: (expense) {
                            _showEditExpenseSheet(context, expense);
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isExpenseTab = _currentTabIndex == 1;
          final color = isExpenseTab ? Colors.redAccent : Colors.green;

          return FloatingActionButton.extended(
            onPressed: () {
              _showTransactionSheet(context, isExpense: isExpenseTab);
            },
            backgroundColor: color,
            elevation: 4,
            icon: Icon(
              isExpenseTab
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: Colors.white,
            ),
            label: Text(
              isExpenseTab ? 'Nuevo Gasto' : 'Nuevo Ingreso',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ).animate(target: isExpenseTab ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1, 1),
                duration: 200.ms,
              );
        },
      ),
    );
  }
}

// --- CUSTOM TAB CARD WIDGET ---
class _CustomTabCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final NumberFormat format;

  const _CustomTabCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              format.format(amount),
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Active Indicator Line
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 40 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TRANSACTION LIST (With Edit Callbacks) ---
class _TransactionList extends StatelessWidget {
  final List<dynamic> items; // List of Income or Expense objects
  final NumberFormat currencyFormat;
  final bool isExpense;
  final void Function(dynamic expense)? onEditExpense;
  final void Function(dynamic income)? onEditIncome;

  const _TransactionList({
    required this.items,
    required this.currencyFormat,
    required this.isExpense,
    this.onEditExpense,
    this.onEditIncome,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense
                    ? Icons.money_off_csred_rounded
                    : Icons.savings_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isExpense ? 'Sin gastos registrados' : 'Sin ingresos registrados',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ).animate().fadeIn();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Top padding reduced
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        final double amount = item.amount;
        final String? description = item.description;
        final DateTime date = item.createdAt;
        final String id = item.id;

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                const Icon(Icons.delete_outline, color: Colors.red, size: 30),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('¿Eliminar?'),
                content: const Text('Esta acción no se puede deshacer.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Eliminar',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            if (isExpense) {
              context.read<OccasionDetailCubit>().deleteExpense(id);
            } else {
              context.read<OccasionDetailCubit>().deleteIncome(id);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Eliminado'), duration: Duration(seconds: 1)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isExpense ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExpense
                      ? Icons.shopping_bag_outlined
                      : Icons.monetization_on_outlined,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              title: Text(
                currencyFormat.format(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isExpense ? Colors.red[700] : Colors.green[700],
                ),
              ),
              subtitle: description != null && description.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        description,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : null,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(date),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: isExpense
                  ? (onEditExpense != null ? () => onEditExpense!(item) : null)
                  : (onEditIncome != null ? () => onEditIncome!(item) : null),
            ),
          ).animate(delay: (20).ms).fadeIn().slideX(begin: 0.1, end: 0),
        );
      },
    );
  }
}
