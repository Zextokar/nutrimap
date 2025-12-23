import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ActivityCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  // Definimos los colores localmente para este widget (o podrías importarlos de un archivo de constantes)
  static const Color _accentBlue = Color(0xFF415A77);
  static const Color _textPrimary = Color(0xFFE0E1DD);

  const ActivityCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDay: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      focusedDay: focusedDay,
      currentDay: DateTime.now(), // Marca el día actual automáticamente
      // Lógica de selección
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,

      // Estilos
      headerStyle: const HeaderStyle(
        formatButtonVisible:
            false, // Ocultamos el botón de "2 weeks", "Month", etc.
        titleCentered: true,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: _textPrimary),
        rightChevronIcon: Icon(Icons.chevron_right, color: _textPrimary),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: _textPrimary),
        weekendTextStyle: TextStyle(color: _textPrimary.withOpacity(0.7)),
        outsideTextStyle: TextStyle(color: _textPrimary.withOpacity(0.3)),

        // Decoración del día actual (si no está seleccionado)
        todayDecoration: const BoxDecoration(
          color: Color.fromARGB(218, 2, 143, 2),
          shape: BoxShape.circle,
        ),

        // Decoración del día seleccionado
        selectedDecoration: const BoxDecoration(
          color: _accentBlue,
          shape: BoxShape.circle,
        ),

        // Ajuste visual para que el círculo no sea gigante
        cellMargin: const EdgeInsets.all(6.0),
      ),
    );
  }
}
