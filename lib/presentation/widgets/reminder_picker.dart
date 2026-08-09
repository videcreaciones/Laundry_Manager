library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/value_objects/wash_reminder.dart';

/// Resultado del picker: `null` significa "el usuario cerro el panel sin
/// elegir nada, no cambies el recordatorio actual". Un [ReminderPickerResult]
/// con `.reminder == null` significa "quitar el recordatorio explicitamente".
class ReminderPickerResult {
  final WashReminder? reminder;
  const ReminderPickerResult(this.reminder);
}

/// Abre un selector estilo recordatorio de calendario: "cada N dias" o
/// "el dia D de cada mes".
Future<ReminderPickerResult?> showReminderPicker(
  BuildContext context, {
  WashReminder? current,
}) {
  return showModalBottomSheet<ReminderPickerResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ReminderSheet(current: current),
  );
}

class _ReminderSheet extends StatefulWidget {
  final WashReminder? current;
  const _ReminderSheet({this.current});

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late WashReminderType _type;
  late int _value;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _type  = current?.type ?? WashReminderType.everyNDays;
    _value = current?.value ?? 7;
    _time  = TimeOfDay(hour: current?.hour ?? 9, minute: current?.minute ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.55 : 0.85),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recordatorio de lavado',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    SegmentedButton<WashReminderType>(
                      segments: const [
                        ButtonSegment(
                          value: WashReminderType.everyNDays,
                          label: Text('Cada N días'),
                        ),
                        ButtonSegment(
                          value: WashReminderType.monthlyOnDay,
                          label: Text('Día del mes'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                    const SizedBox(height: 20),
                    if (_type == WashReminderType.everyNDays)
                      _NumberStepper(
                        label: 'Repetir cada',
                        suffix: _value == 1 ? 'día' : 'días',
                        value: _value,
                        min: 1,
                        max: 90,
                        onChanged: (v) => setState(() => _value = v),
                      )
                    else
                      _NumberStepper(
                        label: 'Día del mes',
                        suffix: '',
                        value: _value,
                        min: 1,
                        max: 31,
                        onChanged: (v) => setState(() => _value = v),
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time_outlined),
                      title: const Text('Hora'),
                      trailing: Text(
                        _time.format(context),
                        style: theme.textTheme.titleMedium,
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time,
                        );
                        if (picked != null) setState(() => _time = picked);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (widget.current != null)
                          TextButton(
                            onPressed: () => Navigator.pop(
                              context,
                              const ReminderPickerResult(null),
                            ),
                            child: const Text('Quitar recordatorio'),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(
                            context,
                            ReminderPickerResult(WashReminder(
                              type: _type,
                              value: _value,
                              hour: _time.hour,
                              minute: _time.minute,
                            )),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  final String label;
  final String suffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _NumberStepper({
    required this.label,
    required this.suffix,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            suffix.isEmpty ? '$value' : '$value $suffix',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
