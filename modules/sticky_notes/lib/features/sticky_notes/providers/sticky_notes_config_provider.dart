import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sticky_notes_config_controller.dart';
import 'sticky_notes_config_repository_provider.dart';

/// 便签配置状态控制器。
///
/// 创建后自动从持久化存储加载配置（分类、默认排序）。
final stickyNotesConfigProvider =
    ChangeNotifierProvider<StickyNotesConfigController>((ref) {
  final repository = ref.watch(stickyNotesConfigRepositoryProvider);
  final controller = StickyNotesConfigController(repository);
  unawaited(controller.load());
  return controller;
});
