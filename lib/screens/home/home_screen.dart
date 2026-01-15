// lib/screens/home/home_screen.dart
import 'package:expense_tracker/models/summaries.dart';
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
import '../occasion/occasion_detail_screen.dart';
import '../occasion/add_occasion_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OccasionsBloc(
        repository: context.read<DatabaseRepository>(),
      )..add(const LoadOccasions()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                context.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(today.year, today.month, today.day),
                        endDate: DateTime(
                            today.year, today.month, today.day, 23, 59, 59),
                      ),
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
                context.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(startOfWeek.year, startOfWeek.month,
                            startOfWeek.day),
                        endDate: now,
                      ),
                    );
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon: Icons.calendar_month_rounded,
              title: 'Este mes',
              onTap: () {
                final now = DateTime.now();
                context.read<OccasionsBloc>().add(
                      FilterOccasionsByDate(
                        startDate: DateTime(now.year, now.month, 1),
                        endDate: now,
                      ),
                    );
                Navigator.pop(context);
              },
            ),
            _FilterOption(
              icon: Icons.all_inclusive_rounded,
              title: 'Todo',
              onTap: () {
                context
                    .read<OccasionsBloc>()
                    .add(const FilterOccasionsByDate());
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
                if (state.occasions.isEmpty)
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
                            'No hay ocasiones',
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
                            'Crea tu primera ocasión para comenzar',
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
                          final occasion = state.occasions[index];
                          return _OccasionCard(
                            occasion: occasion,
                            currencyFormat: currencyFormat,
                          )
                              .animate(delay: (index * 50).ms)
                              .fadeIn()
                              .slideX(begin: 0.2, end: 0);
                        },
                        childCount: state.occasions.length,
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
              const SizedBox(width: 16),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Gastos',
                  value: currencyFormat.format(summary.totalExpense),
                  color: Colors.red[300]!,
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
  final OccasionSummary occasion;
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
