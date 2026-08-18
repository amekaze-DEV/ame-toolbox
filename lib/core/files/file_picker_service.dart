import 'picked_file.dart';

/// 文件/图片选择能力统一抽象。
///
/// 模块通过底座提供的 [FilePickerService] 调用系统文件选择器，无需感知平台差异。
/// 具体实现按平台分别定义，通过条件导入工厂在编译期选择，UI 层不直接接触
/// `Platform` 或 `dart:io`。
abstract class FilePickerService {
  /// 选择单个图片文件；用户取消时返回 null。
  Future<PickedFile?> pickImage({List<String>? allowedExtensions});

  /// 选择多个图片文件；用户取消时返回空列表。
  Future<List<PickedFile>> pickImages({List<String>? allowedExtensions});

  /// 选择任意单个文件；用户取消时返回 null。
  Future<PickedFile?> pickFile({List<String>? allowedExtensions});
}