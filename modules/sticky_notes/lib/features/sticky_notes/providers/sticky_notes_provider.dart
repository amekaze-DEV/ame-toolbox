import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sticky_notes_controller.dart';
import 'sticky_notes_repository_provider.dart';

/// 便签列表状态控制器。
///
/// 创建后自动从持久化存储加载便签列表，确保页面首帧即展示已存数据。
final stickyNotesProvider = ChangeNotifierProvider<StickyNotesController>((ref) {
  final repository = ref.watch(stickyNotesRepositoryProvider);
  final controller = StickyNotesController(repository: repository);
  unawaited(controller.load());
  return controller;
});
