// pages/calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<DateTime> _selectedDay;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = ValueNotifier(_focusedDay);
  }

  @override
  void dispose() {
    _selectedDay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environmental Calendar'),
        backgroundColor: Colors.blueAccent.shade700,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: TableCalendar(
                  firstDay: DateTime.utc(2010, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay.value, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay.value, selectedDay)) {
                      setState(() {
                        _selectedDay.value = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color.fromARGB(255, 93, 148, 211),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: const Color.fromARGB(255, 13, 27, 110),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left, color: const Color.fromARGB(255, 43, 17, 102)),
                    rightChevronIcon: Icon(Icons.chevron_right, color: const Color.fromARGB(255, 45, 12, 121)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<DateTime>(
              valueListenable: _selectedDay,
              builder: (context, value, _) {
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event, color: Color.fromARGB(255, 80, 28, 175)),
                        const SizedBox(width: 10),
                        Text(
                          'Selected Date: ${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: const Color.fromARGB(255, 48, 22, 165),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
