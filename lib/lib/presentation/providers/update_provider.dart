library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry_manager/domain/services/update_service.dart';

final updateServiceProvider = Provider<UpdateService>(
  (_) => const UpdateService(),
);

final updateCheckProvider = FutureProvider<ReleaseInfo?>((ref) async {
  return ref.read(updateServiceProvider).checkForUpdate();
});
