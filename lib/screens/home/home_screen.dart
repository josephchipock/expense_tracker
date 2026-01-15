// lib/screens/home/home_screen.dart
import 'package:expense_tracker/models/home_list_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../repositories/database_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/occasions/occasions_bloc.dart';
import '../../blocs/occasions/occasions_event.dart';
import '../../blocs/occasions/occasions_state.dart';
import '../../blocs/categories/categories_cubit.dart';
import '../../blocs/general_expenses/general_expenses_cubit.dart';
import '../../blocs/categories/categories_state.dart';
import '../occasion/occasion_detail_screen.dart';
import '../occasion/add_occasion_screen.dart';
import '../occasion/calendar_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => OccasionsBloc(
            repository: context.read<DatabaseRepository>(),
          )..add(const LoadOccasions()),
        ),
        BlocProvider(
          create: (context) => GeneralExpensesCubit(
            repository: context.read<DatabaseRepository>(),
          )..loadGeneralExpenses(),
        ),
        BlocProvider(
          create: (context) => CategoriesCubit(
            repository: context.read<DatabaseRepository>(),
          )..loadCategories(),
        ),
      ],
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  void _showAddGeneralExpenseDialog(BuildContext ctx) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedCategoryId;
    final newCategoryController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: ctx,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: ctx.read<CategoriesCubit>()),
          BlocProvider.value(value: ctx.read<GeneralExpensesCubit>()),
          BlocProvider.value(value: ctx.read<OccasionsBloc>()),
        ],
        child: StatefulBuilder(
          builder: (dialogContext, setState) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text('Gasto General'),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime(selectedDate.year, selectedDate.month, selectedDate.day))}',
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('Elegir fecha'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                  if (formKey.currentState!.validate()) {
                    try {
                      final amount = double.parse(amountController.text);
                      String? categoryId = selectedCategoryId;

                      if (selectedCategoryId == 'new') {
                        final newCat = await ctx
                            .read<DatabaseRepository>()
                            .createCategory(newCategoryController.text);
                        categoryId = newCat.id;
                        ctx.read<CategoriesCubit>().loadCategories();
                      }

                      await ctx
                          .read<GeneralExpensesCubit>()
                          .createGeneralExpense(
                            amount,
                            categoryId,
                            descriptionController.text.isEmpty
                                ? null
                                : descriptionController.text,
                            createdAt: DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              DateTime.now().hour,
                              DateTime.now().minute,
                              DateTime.now().second,
                            ),
                          );

                      // Refrescar el resumen general
                      ctx.read<OccasionsBloc>().add(const LoadOccasions());

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Gasto general agregado'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar gasto: $e'),
                          backgroundColor: Colors.red,
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

  void _showFilterDialog(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Filtrar por fecha',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _FilterOption(
              icon: Icons.today_rounded,
              title: 'Hoy',
              onTap: () {
                final today = DateTime.now();
                ctx.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(today.year, today.month, today.day),
                        endDate: DateTime(
                            today.year, today.month, today.day, 23, 59, 59),
                      ),
                    );
                ctx.read<GeneralExpensesCubit>().loadGeneralExpenses(
                      startDate: DateTime(today.year, today.month, today.day),
                      endDate: DateTime(
                          today.year, today.month, today.day, 23, 59, 59),
                    );
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon: Icons.view_week_rounded,
              title: 'Esta semana',
              onTap: () {
                final now = DateTime.now();
                final startOfWeek =
                    now.subtract(Duration(days: now.weekday - 1));
                ctx.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(startOfWeek.year, startOfWeek.month,
                            startOfWeek.day),
                        endDate: now,
                      ),
                    );
                ctx.read<GeneralExpensesCubit>().loadGeneralExpenses(
                      startDate: DateTime(
                          startOfWeek.year, startOfWeek.month, startOfWeek.day),
                      endDate: now,
                    );
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon: Icons.calendar_month_rounded,
              title: 'Este mes',
              onTap: () {
                final now = DateTime.now();
                ctx.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(now.year, now.month, 1),
                        endDate: now,
                      ),
                    );
                ctx.read<GeneralExpensesCubit>().loadGeneralExpenses(
                      startDate: DateTime(now.year, now.month, 1),
                      endDate: now,
                    );
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon: Icons.all_inclusive_rounded,
              title: 'Todo',
              onTap: () {
                ctx.read<OccasionsBloc>().add(const FilterOccasionsByDate());
                ctx.read<GeneralExpensesCubit>().loadGeneralExpenses();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<OccasionsBloc, OccasionsState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Mis Finanzas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_card_rounded),
                    onPressed: () => _showAddGeneralExpenseDialog(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                    ),
                    tooltip: 'Gasto General',
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CalendarScreen(),
                        ),
                      );
                      if (context.mounted) {
                        context
                            .read<OccasionsBloc>()
                            .add(const LoadOccasions());
                      }
                    },
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Ver calendario'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: () => _showFilterDialog(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              if (state is OccasionsLoaded) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _SummaryCard(
                      summary: state.generalSummary,
                      currencyFormat: currencyFormat,
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  ),
                ),
                if (state.homeElements.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No hay elementos',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea tu primera ocasión o gasto general',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final element = state.homeElements[index];
                          return _HomeElementCard(
                            element: element,
                            currencyFormat: currencyFormat,
                          )
                              .animate(delay: (index * 50).ms)
                              .fadeIn()
                              .slideX(begin: 0.2, end: 0);
                        },
                        childCount: state.homeElements.length,
                      ),
                    ),
                  ),
              ] else if (state is OccasionsLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is OccasionsError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar ocasiones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(state.message,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddOccasionScreen()),
          );
          if (context.mounted) {
            context.read<OccasionsBloc>().add(const LoadOccasions());
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Ocasión'),
      ).animate().fadeIn(delay: 800.ms).scale(delay: 800.ms),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final dynamic summary;
  final NumberFormat currencyFormat;

  const _SummaryCard({
    required this.summary,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Balance General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(summary.profit),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Ingresos',
                  value: currencyFormat.format(summary.totalIncome),
                  color: Colors.green[300]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Gastos',
                  value: currencyFormat.format(summary.totalExpense),
                  color: Colors.red[300]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Generales',
                  value: currencyFormat.format(summary.totalGeneralExpense),
                  color: Colors.orange[300]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccasionCard extends StatelessWidget {
  final dynamic occasion;
  final NumberFormat currencyFormat;

  const _OccasionCard({
    required this.occasion,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = occasion.profit >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OccasionDetailScreen(
                  occasionId: occasion.id,
                  occasionName: occasion.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isProfit ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isProfit
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    color: isProfit ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        occasion.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      if (occasion.occasionDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(occasion.occasionDate!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Creada: ${DateFormat('dd/MM/yyyy').format(occasion.createdAt)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          DateFormat('dd/MM/yyyy').format(occasion.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(occasion.profit),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isProfit ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeElementCard extends StatelessWidget {
  final HomeListElement element;
  final NumberFormat currencyFormat;

  const _HomeElementCard({
    required this.element,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isOccasion = element.type.toString().contains('occasion');

    if (isOccasion) {
      final isProfit = (element.amount ?? 0) >= 0;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OccasionDetailScreen(
                    occasionId: element.id,
                    occasionName: element.name ?? 'Ocasión',
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isProfit ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isProfit ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          element.name ?? 'Ocasión',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        if (element.occasionDate != null)
                          Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(element.occasionDate!),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('•',
                                  style: TextStyle(color: Colors.grey[400])),
                              const SizedBox(width: 8),
                              Text(
                                'Creada: ${DateFormat('dd/MM/yyyy').format(element.createdAt)}',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          )
                        else
                          Text(
                            DateFormat('dd/MM/yyyy').format(element.createdAt),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey)
                ],
              ),
            ),
          ),
        ),
      );
    }

    // General Expense card
    return Container(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet, color: Colors.orange),
        ),
        title: Text(
          currencyFormat.format(element.amount ?? 0),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orange[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (element.description != null &&
                (element.description?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  element.description!,
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (element.categoryName != null)
              Text(
                element.categoryName!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(element.createdAt),
              style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
