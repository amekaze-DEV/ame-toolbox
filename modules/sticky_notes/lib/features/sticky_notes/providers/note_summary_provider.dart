import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_summary.dart';
import 'note_summary_service_provider.dart';
import 'sticky_notes_config_provider.dart';
import 'sticky_notes_provider.dart';

/// 首页摘要（派生状态，不持久化）。
final stickyNotesSummaryProvider = Provider<NoteSummary>((ref) {
  final notes = ref.watch(stickyNotesProvider).notes;
  final config = ref.watch(stickyNotesConfigProvider).config;
  final service = ref.watch(noteSummaryServiceProvider);
  return service.computeSummary(notes, config);
});
