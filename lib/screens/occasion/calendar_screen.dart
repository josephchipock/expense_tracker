import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/occasions/occasions_bloc.dart';
import '../../blocs/occasions/occasions_event.dart';
import '../../blocs/occasions/occasions_state.dart';
import '../../repositories/database_repository.dart';
import 'add_occasion_screen.dart';
import 'occasion_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OccasionsBloc(repository: context.read<DatabaseRepository>())
        ..add(LoadOccasions(
          startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
          endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59),
        )),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calendario'),
        ),
        body: BlocBuilder<OccasionsBloc, OccasionsState>(
          builder: (context, state) {
            final occasions = state is OccasionsLoaded ? state.occasions : <dynamic>[];

            final occasionsByDate = <DateTime, List<dynamic>>{};
            for (final o in occasions) {
              if (o.occasionDate != null) {
                final d = DateTime(o.occasionDate!.year, o.occasionDate!.month, o.occasionDate!.day);
                occasionsByDate.putIfAbsent(d, () => []).add(o);
              }
            }

            final dayOccasions = occasionsByDate[_selectedDay] ?? [];
            final monthName = DateFormat('MMMM yyyy').format(_focusedDay);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                          });
                          context.read<OccasionsBloc>().add(LoadOccasions(
                                startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
                                endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59),
                              ));
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            monthName[0].toUpperCase() + monthName.substring(1),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                          });
                          context.read<OccasionsBloc>().add(LoadOccasions(
                                startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
                                endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59),
                              ));
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MonthGrid(
                    focusedMonth: _focusedDay,
                    selectedDay: _selectedDay,
                    hasOccasion: (day) => occasionsByDate.containsKey(day),
                    onDaySelected: (day) {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: dayOccasions.isNotEmpty
                        ? ListView.builder(
                            itemCount: dayOccasions.length,
                            itemBuilder: (context, index) {
                              final occasion = dayOccasions[index];
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
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isProfit ? Colors.green[50] : Colors.orange[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                              color: isProfit ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  occasion.name,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  DateFormat('dd/MM/yyyy').format(occasion.occasionDate!),
                                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_available_rounded, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No hay ocasiones en este día', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddOccasionScreen(initialDate: _selectedDay),
                                      ),
                                    );
                                    if (context.mounted) {
                                      context.read<OccasionsBloc>().add(LoadOccasions(
                                            startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
                                            endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0, 23, 59, 59),
                                          ));
                                    }
                                  },
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Crear ocasión'),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final bool Function(DateTime day) hasOccasion;
  final void Function(DateTime day) onDaySelected;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.hasOccasion,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // 1=Mon .. 7=Sun

    final cells = <Widget>[];
    for (int i = 1; i < startWeekday; i++) {
      cells.add(Container());
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(focusedMonth.year, focusedMonth.month, d);
      final selected = day.year == selectedDay.year && day.month == selectedDay.month && day.day == selectedDay.day;
      final has = hasOccasion(day);
      cells.add(
        GestureDetector(
          onTap: () => onDaySelected(day),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : has
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            height: 48,
            child: Center(
              child: Text(
                '$d',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : has
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}