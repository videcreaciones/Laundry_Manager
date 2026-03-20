library;

import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

class StatusActionButton extends StatelessWidget {
  final GarmentStatus currentStatus;
  final VoidCallback? onPressed;
  final bool isLoading;

  const StatusActionButton({
    super.key,
    required this.currentStatus,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = currentStatus.actionLabel;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Icon(currentStatus == GarmentStatus.devuelta
                ? Icons.replay_rounded
                : Icons.arrow_forward_rounded),
        label: Text(
          isLoading ? 'Procesando...' : label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
