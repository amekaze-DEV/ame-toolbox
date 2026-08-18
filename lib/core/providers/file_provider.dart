import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/files/file_picker_service.dart';
import 'package:ametoolbox/core/files/file_picker_service_factory.dart';

/// 注入文件/图片选择服务能力。
///
/// 模块可在 `buildPage` 中通过 `ref.read(filePickerProvider)` 调用系统文件选择器，
/// 例如 `await ref.read(filePickerProvider).pickImage()`。
/// 工厂为纯函数，Provider 直接构造，无需在 [main] 中 override。
final filePickerProvider = Provider<FilePickerService>(
  (ref) => createFilePickerService(),
);