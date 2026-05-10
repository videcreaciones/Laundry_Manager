library;

import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

class StatusSelectorWidget extends StatelessWidget {
  final GarmentStatus currentStatus;
  final void Function(GarmentStatus) onSelected;
  final bool isLoading;

  const StatusSelectorWidget({
    super.key,
    required this.currentStatus,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cambiar estado',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: GarmentStatus.values.map((status) {
            final isSelected = status == currentStatus;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    foregroundColor: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: isLoading || isSelected
                      ? null
                      : () => onSelected(status),
                  child: Text(
                    status.shortLabel,
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
