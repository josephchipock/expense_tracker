// lib/screens/occasion/occasion_detail_screen.dart
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddIncomeDialog(BuildContext ctx) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Nuevo Ingreso'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final amount = double.parse(amountController.text);
                await ctx.read<OccasionDetailCubit>().createIncome(
                      amount,
                      descriptionController.text.isEmpty
                          ? null
                          : descriptionController.text,
                    );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Ingreso agregado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext ctx) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId;
    final newCategoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CategoriesCubit>(),
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                const SizedBox(width: 12),
                const Text('Nuevo Gasto'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixText: '\$ ',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un monto';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Monto inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        if (state is CategoriesLoaded) {
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: [
                              ...state.categories.map((cat) => DropdownMenuItem(
                                    value: cat.id,
                                    child: Text(cat.name),
                                  )),
                              const DropdownMenuItem(
                                value: 'new',
                                child: Row(
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 18),
                                    SizedBox(width: 8),
                                    Text('Nueva categoría'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedCategoryId = value);
                            },
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                    if (selectedCategoryId == 'new') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de nueva categoría',
                          prefixIcon: Icon(Icons.new_label_outlined),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (selectedCategoryId == 'new' &&
                              (value == null || value.isEmpty)) {
                            return 'Ingrese el nombre';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    final amount = double.parse(amountController.text);
                    String? categoryId = selectedCategoryId;

                    if (selectedCategoryId == 'new') {
                      final newCat = await context
                          .read<DatabaseRepository>()
                          .createCategory(newCategoryController.text);
                      categoryId = newCat.id;
                      ctx.read<CategoriesCubit>().loadCategories();
                    }

                    await ctx.read<OccasionDetailCubit>().createExpense(
                          amount,
                          categoryId,
                          descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                        );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gasto agregado'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.large(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.occasionName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              tabs: const [
                Tab(icon: Icon(Icons.arrow_upward), text: 'Ingresos'),
                Tab(icon: Icon(Icons.arrow_downward), text: 'Gastos'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
              builder: (context, state) {
                if (state is OccasionDetailLoaded) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Ingresos',
                          value:
                              _currencyFormat.format(state.summary.totalIncome),
                          color: Colors.green,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _StatItem(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Gastos',
                          value: _currencyFormat
                              .format(state.summary.totalExpense),
                          color: Colors.red,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _StatItem(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Balance',
                          value: _currencyFormat.format(state.summary.profit),
                          color: state.summary.profit >= 0
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0);
                }
                return const SizedBox();
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _IncomesTab(currencyFormat: _currencyFormat),
                  _ExpensesTab(currencyFormat: _currencyFormat),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddIncomeDialog(context);
          } else {
            _showAddExpenseDialog(context);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'Ingreso' : 'Gasto'),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _IncomesTab extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _IncomesTab({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
      builder: (context, state) {
        if (state is OccasionDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OccasionDetailLoaded) {
          if (state.incomes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ingresos registrados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.incomes.length,
            itemBuilder: (context, index) {
              final income = state.incomes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle, color: Colors.green),
                  ),
                  title: Text(
                    currencyFormat.format(income.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: income.description != null
                      ? Text(income.description!)
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd/MM/yy').format(income.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(income.createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn()
                  .slideX(begin: -0.2, end: 0);
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _ExpensesTab({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OccasionDetailCubit, OccasionDetailState>(
      builder: (context, state) {
        if (state is OccasionDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OccasionDetailLoaded) {
          if (state.expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay gastos registrados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.expenses.length,
            itemBuilder: (context, index) {
              final expense = state.expenses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove_circle, color: Colors.red),
                  ),
                  title: Text(
                    currencyFormat.format(expense.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: expense.description != null
                      ? Text(expense.description!)
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd/MM/yy').format(expense.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(expense.createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: (index * 50).ms)
                  .fadeIn()
                  .slideX(begin: -0.2, end: 0);
            },
          );
        }

        return const SizedBox();
      },
    );
  }
}
