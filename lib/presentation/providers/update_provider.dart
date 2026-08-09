library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/domain/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

final updateServiceProvider = Provider<UpdateService>(
  (_) => const UpdateService(),
);

final updateCheckProvider = FutureProvider<ReleaseInfo?>((ref) async {
  return ref.read(updateServiceProvider).checkForUpdate();
});

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});
