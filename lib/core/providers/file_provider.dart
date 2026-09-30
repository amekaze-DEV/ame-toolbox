import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/files/file_launcher_service.dart';
import 'package:ametoolbox/core/files/file_launcher_service_factory.dart';
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

/// 注入“用系统默认查看器打开 / 另存到用户选择位置”能力。
///
/// 模块可在 `buildPage` 中通过 `ref.read(fileLauncherProvider)` 打开附件或下载附件。
/// 工厂为纯函数，Provider 直接构造，无需在 [main] 中 override。
final fileLauncherProvider = Provider<FileLauncherService>(
  (ref) => createFileLauncherService(),
);