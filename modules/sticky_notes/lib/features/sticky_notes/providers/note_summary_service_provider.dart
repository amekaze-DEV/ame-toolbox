import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/note_summary_service.dart';

/// 注入摘要聚合服务。
final noteSummaryServiceProvider = Provider<NoteSummaryService>((ref) {
  return const NoteSummaryService();
});
