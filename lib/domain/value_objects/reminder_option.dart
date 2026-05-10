class ReminderOption {
  final int days;
  final String label;

  const ReminderOption(this.days, this.label);

  static const options = [
    ReminderOption(1, 'En 1 día'),
    ReminderOption(2, 'En 2 días'),
    ReminderOption(3, 'En 3 días'),
    ReminderOption(7, 'En 1 semana'),
  ];
}
