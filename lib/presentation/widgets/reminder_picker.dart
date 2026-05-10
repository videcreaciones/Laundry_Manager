import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/value_objects/reminder_option.dart';

Future<ReminderOption?> showReminderPicker(BuildContext context) {
  return showModalBottomSheet<ReminderOption>(
    context: context,
    builder: (context) {
      return ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Seleccionar recordatorio')),
          ...ReminderOption.options.map((opt) => ListTile(
                title: Text(opt.label),
                onTap: () => Navigator.pop(context, opt),
              )),
          ListTile(
            title: const Text('Sin recordatorio'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      );
    },
  );
}
