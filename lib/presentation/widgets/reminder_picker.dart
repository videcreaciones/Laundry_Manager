import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/value_objects/reminder_option.dart';

Future<ReminderOption?> showReminderPicker(BuildContext context) {
  return showModalBottomSheet<ReminderOption>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: (isDark ? Colors.black : Colors.white)
                .withValues(alpha: isDark ? 0.55 : 0.75),
            child: SafeArea(
              top: false,
              child: ListView(
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
              ),
            ),
          ),
        ),
      );
    },
  );
}
