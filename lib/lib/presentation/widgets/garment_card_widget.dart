library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';
import 'package:laundry_manager/presentation/providers/settings_provider.dart';

extension _StatusColor on GarmentStatus {
  Color get chipColor => switch (this) {
    GarmentStatus.guardada => const Color(0xFFE3F2FD),
    GarmentStatus.lavando  => const Color(0xFFFFF9C4),
    GarmentStatus.devuelta => const Color(0xFFE8F5E9),
  };

  Color get chipTextColor => switch (this) {
    GarmentStatus.guardada => const Color(0xFF1565C0),
    GarmentStatus.lavando  => const Color(0xFFF57F17),
    GarmentStatus.devuelta => const Color(0xFF2E7D32),
  };

  IconData get statusIcon => switch (this) {
    GarmentStatus.guardada => Icons.inventory_2_outlined,
    GarmentStatus.lavando  => Icons.local_laundry_service_outlined,
    GarmentStatus.devuelta => Icons.check_circle_outline,
  };
}

class GarmentCard extends ConsumerWidget {
  final GarmentEntity garment;
  final VoidCallback onTap;
  final VoidCallback? onStatusChange;
  final void Function(GarmentStatus)? onStatusSelected;

  const GarmentCard({
    super.key,
    required this.garment,
    required this.onTap,
    this.onStatusChange,
    this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme          = Theme.of(context);
    final useSelector    = ref.watch(settingsProvider).useStatusSelector;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _GarmentThumbnail(imagePath: garment.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      garment.owner,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: garment.status),
                  ],
                ),
              ),

              // Botón de acción — flecha o dropdown según configuración
              if (useSelector)
                // Dropdown de estado
                _StatusDropdownButton(
                  garment: garment,
                  onSelected: onStatusSelected,
                )
              else if (onStatusChange != null)
                // Flecha clásica
                IconButton(
                  onPressed: onStatusChange,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  iconSize: 18,
                  tooltip: garment.status.actionLabel,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón que abre un menú desplegable con los 3 estados.
class _StatusDropdownButton extends StatelessWidget {
  final GarmentEntity garment;
  final void Function(GarmentStatus)? onSelected;

  const _StatusDropdownButton({
    required this.garment,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<GarmentStatus>(
      tooltip: 'Cambiar estado',
      icon: Icon(
        Icons.swap_vert_rounded,
        color: theme.colorScheme.primary,
        size: 22,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (newStatus) {
        onSelected?.call(newStatus);
      },
      itemBuilder: (_) => GarmentStatus.values.map((status) {
        final isCurrent = status == garment.status;
        final canTransition = garment.status.canTransitionTo(status);
        return PopupMenuItem<GarmentStatus>(
          value: status,
          enabled: !isCurrent,
          child: Row(
            children: [
              Icon(
                status.statusIcon,
                size: 18,
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Text(
                status.displayLabel,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isCurrent) ...[
                const Spacer(),
                Icon(Icons.check,
                    size: 16, color: theme.colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GarmentThumbnail extends StatelessWidget {
  final String? imagePath;
  const _GarmentThumbnail({this.imagePath});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56, height: 56,
        child: imagePath != null && File(imagePath!).existsSync()
            ? Image.file(File(imagePath!), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(color: color))
            : _Placeholder(color: color),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme color;
  const _Placeholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.surfaceContainerHighest,
      child: Icon(Icons.checkroom_outlined,
          color: color.onSurfaceVariant, size: 28),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GarmentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.statusIcon, size: 12, color: status.chipTextColor),
          const SizedBox(width: 4),
          Text(
            status.shortLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.chipTextColor,
            ),
          ),
        ],
      ),
    );
  }
}




