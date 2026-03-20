/// Widget de tarjeta para una prenda en la lista.
///
/// Restricciones de diseño:
/// - Solo consume datos — no llama a use cases ni providers directamente.
/// - Los callbacks [onTap] y [onStatusChange] son provistos por el padre.
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:laundry_manager/domain/entities/garment_entity.dart';
import 'package:laundry_manager/domain/value_objects/garment_status.dart';

/// Colores asociados a cada estado para feedback visual inmediato.
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

/// Tarjeta que representa una prenda en la lista principal.
class GarmentCard extends StatelessWidget {
  final GarmentEntity garment;
  final VoidCallback onTap;
  final VoidCallback? onStatusChange;

  const GarmentCard({
    super.key,
    required this.garment,
    required this.onTap,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Foto o placeholder ──────────────────────────────────────
              _GarmentThumbnail(imagePath: garment.imagePath),
              const SizedBox(width: 12),

              // ── Datos principales ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      garment.owner,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: garment.status),
                  ],
                ),
              ),

              // ── Botón de acción rápida ──────────────────────────────────
              if (onStatusChange != null &&
                  garment.status.nextStatus != null)
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

/// Thumbnail de la prenda: foto si existe, icono placeholder si no (RN-03).
class _GarmentThumbnail extends StatelessWidget {
  final String? imagePath;

  const _GarmentThumbnail({this.imagePath});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imagePath != null && File(imagePath!).existsSync()
            ? Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Placeholder(color: color),
              )
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
      child: Icon(
        Icons.checkroom_outlined,
        color: color.onSurfaceVariant,
        size: 28,
      ),
    );
  }
}

/// Chip de estado con color semántico.
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
