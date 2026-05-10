library;

import 'package:flutter/material.dart';

/// Días de la semana disponibles para el recordatorio.
enum ReminderDay {
  lunes(DateTime.monday,    'Lunes'),
  martes(DateTime.tuesday,  'Martes'),
  miercoles(DateTime.wednesday, 'Miercoles'),
  jueves(DateTime.thursday, 'Jueves'),
  viernes(DateTime.friday,  'Viernes'),
  sabado(DateTime.saturday, 'Sabado'),
  domingo(DateTime.sunday,  'Domingo');

  final int weekday;
  final String label;
  const ReminderDay(this.weekday, this.label);
}

/// Frecuencia del recordatorio.
enum ReminderFrequency {
  days7(7,   'En 1 semana'),
  days15(15, 'En 15 dias'),
  days30(30, 'En 1 mes'),
  days60(60, 'En 2 meses'),
  days90(90, 'En 3 meses');

  final int days;
  final String label;
  const ReminderFrequency(this.days, this.label);
}

/// Configuracion completa de un recordatorio.
class ReminderOption {
  final ReminderFrequency frequency;
  final ReminderDay? preferredDay; // null = el dia exacto segun la frecuencia

  const ReminderOption({
    required this.frequency,
    this.preferredDay,
  });

  /// Calcula la fecha real del recordatorio.
  /// Si hay dia preferido, busca el siguiente dia de la semana
  /// despues de que pasen los dias de la frecuencia.
  DateTime get scheduledDate {
    final base = DateTime.now().add(Duration(days: frequency.days));
    if (preferredDay == null) return base;

    // Buscar el siguiente dia de la semana preferido desde la fecha base
    var date = base;
    for (var i = 0; i < 7; i++) {
      if (date.weekday == preferredDay!.weekday) return date;
      date = date.add(const Duration(days: 1));
    }
    return base;
  }

  String get label {
    if (preferredDay == null) return frequency.label;
    return '${frequency.label}, un ${preferredDay!.label}';
  }
}

/// Muestra el selector de recordatorio en dos pasos:
/// 1. Elegir frecuencia
/// 2. Elegir dia de la semana (opcional)
Future<ReminderOption?> showReminderPicker(BuildContext context) async {
  // Paso 1: elegir frecuencia
  final frequency = await showModalBottomSheet<ReminderFrequency>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Recordar lavar en...',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ...ReminderFrequency.values.map((f) => ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: Text(f.label),
              onTap: () => Navigator.pop(ctx, f),
            )),
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: const Text('Sin recordatorio'),
              onTap: () => Navigator.pop(ctx, null),
            ),
          ],
        ),
      ),
    ),
  );

  if (frequency == null) return null;
  if (!context.mounted) return ReminderOption(frequency: frequency);

  // Paso 2: elegir dia de la semana (opcional)
  final day = await showModalBottomSheet<ReminderDay?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Que dia de la semana prefieres?',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              child: Text(
                'El recordatorio se enviara el primer dia '
                'de la semana elegido despues del periodo seleccionado.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.today_outlined),
              title: const Text('Cualquier dia (fecha exacta)'),
              subtitle: const Text('El recordatorio llega exactamente al cumplirse el plazo'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            const Divider(indent: 16, endIndent: 16),
            ...ReminderDay.values.map((d) => ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(d.label),
              onTap: () => Navigator.pop(ctx, d),
            )),
          ],
        ),
      ),
    ),
  );

  // day puede ser null si eligio "cualquier dia" — eso es valido
  return ReminderOption(frequency: frequency, preferredDay: day);
}
