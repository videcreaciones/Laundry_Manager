library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/domain/services/update_service.dart';
import 'package:laundry_manager/presentation/providers/update_provider.dart';

class UpdateBannerWidget extends ConsumerWidget {
  const UpdateBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAsync = ref.watch(updateCheckProvider);

    return updateAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (release) {
        if (release == null) return const SizedBox.shrink();
        return _UpdateBanner(release: release);
      },
    );
  }
}

class _UpdateBanner extends ConsumerStatefulWidget {
  final ReleaseInfo release;
  const _UpdateBanner({required this.release});

  @override
  ConsumerState<_UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<_UpdateBanner> {
  bool _downloading = false;
  double _progress  = 0;
  bool _dismissed   = false;

  Future<void> _startDownload() async {
    setState(() { _downloading = true; _progress = 0; });

    final service = ref.read(updateServiceProvider);
    final success = await service.downloadAndInstall(
      widget.release.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted && !success) {
      setState(() => _downloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al descargar la actualización')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: _downloading
          ? _DownloadingView(progress: _progress)
          : _AvailableView(
              version: widget.release.version,
              onInstall: _startDownload,
              onDismiss: () => setState(() => _dismissed = true),
            ),
    );
  }
}

class _AvailableView extends StatelessWidget {
  final String version;
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  const _AvailableView({
    required this.version,
    required this.onInstall,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.system_update_outlined,
              color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nueva versión disponible: v$version',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer)),
                Text('Toca Instalar para actualizar',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7))),
              ],
            ),
          ),
          TextButton(
            onPressed: onInstall,
            child: const Text('Instalar'),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _DownloadingView extends StatelessWidget {
  final double progress;
  const _DownloadingView({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.downloading_outlined,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Descargando actualización...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
