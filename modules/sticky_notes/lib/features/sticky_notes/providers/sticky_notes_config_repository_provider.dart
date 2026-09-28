import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sticky_notes_config_repository.dart';

/// 注入便签配置 Repository。
final stickyNotesConfigRepositoryProvider =
    Provider<StickyNotesConfigRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StickyNotesConfigRepository(storageService: storage);
});
