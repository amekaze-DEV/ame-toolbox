import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sticky_notes_repository.dart';

/// 注入便签列表 Repository。
final stickyNotesRepositoryProvider = Provider<StickyNotesRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return StickyNotesRepository(storageService: storage);
});
