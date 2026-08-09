library;

enum WashReminderType { everyNDays, monthlyOnDay }

/// Regla de recordatorio de lavado de una prenda: "cada N días" o
/// "el día D de cada mes" (equivalente simplificado a un recordatorio
/// recurrente de calendario).
final class WashReminder {
  final WashReminderType type;
  final int value; // dias de intervalo, o dia del mes (1-31)
  final int hour;
  final int minute;

  const WashReminder({
    required this.type,
    required this.value,
    this.hour = 9,
    this.minute = 0,
  });

  String get label => switch (type) {
    WashReminderType.everyNDays =>
      value == 1 ? 'Cada día' : 'Cada $value días',
    WashReminderType.monthlyOnDay => 'El día $value de cada mes',
  };

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Proxima fecha en la que debe sonar el recordatorio, a partir de [from]
  /// (por defecto ahora).
  DateTime nextOccurrence({DateTime? from}) {
    final now = from ?? DateTime.now();
    switch (type) {
      case WashReminderType.everyNDays:
        var next = DateTime(now.year, now.month, now.day, hour, minute);
        if (!next.isAfter(now)) {
          next = next.add(Duration(days: value));
        }
        return next;
      case WashReminderType.monthlyOnDay:
        var next = _dateForDayOfMonth(now.year, now.month, value);
        if (!next.isAfter(now)) {
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          next = _dateForDayOfMonth(nextYear, nextMonth, value);
        }
        return next;
    }
  }

  DateTime _dateForDayOfMonth(int year, int month, int day) {
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final clampedDay = day > lastDayOfMonth ? lastDayOfMonth : day;
    return DateTime(year, month, clampedDay, hour, minute);
  }
}
