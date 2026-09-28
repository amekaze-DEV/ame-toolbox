import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/note_query_service.dart';

/// 注入便签查询 / 排序 / 筛选服务。
final noteQueryServiceProvider = Provider<NoteQueryService>((ref) {
  return const NoteQueryService();
});
