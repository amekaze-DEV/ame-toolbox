import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'file_picker_service.dart';
import 'picked_file.dart';

/// 基于 [file_picker] 的桌面/移动端实现。
///
/// 该文件属于平台实现层，允许使用 `dart:io` 与 `Platform`，仅供条件导入工厂引用，
/// 不直接暴露给 UI 层与模块。file_picker 11.x 的 [FilePicker.pickFiles] 为静态方法。
class FilePickerServiceIO implements FilePickerService {
  static const _defaultImageExtensions = [
    'png',
    'jpg',
    'jpeg',
    'webp',
    'bmp',
    'gif',
  ];

  @override
  Future<PickedFile?> pickImage({List<String>? allowedExtensions}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? _defaultImageExtensions,
      withData: false,
      lockParentWindow: true,
    );
    final file = result?.files.firstOrNull;
    return file == null ? null : _toPickedFile(file);
  }

  @override
  Future<List<PickedFile>> pickImages({List<String>? allowedExtensions}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions ?? _defaultImageExtensions,
      allowMultiple: true,
      withData: false,
      lockParentWindow: true,
    );
    return result?.files.map(_toPickedFile).toList() ?? const [];
  }

  @override
  Future<PickedFile?> pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.pickFiles(
      type: allowedExtensions == null ? FileType.any : FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: false,
      lockParentWindow: true,
    );
    final file = result?.files.firstOrNull;
    return file == null ? null : _toPickedFile(file);
  }

  PickedFile _toPickedFile(PlatformFile file) {
    final path = file.path;
    return PickedFile(
      name: file.name,
      path: path ?? '',
      extension: file.extension,
      sizeBytes: file.size == 0 ? null : file.size,
      mimeType: path == null ? null : _guessMimeType(path),
      readBytes: path == null
          ? (file.bytes != null ? () async => file.bytes! : null)
          : () async => File(path).readAsBytes(),
    );
  }

  String? _guessMimeType(String path) {
    final ext = path.contains('.')
        ? path.substring(path.lastIndexOf('.') + 1).toLowerCase()
        : '';
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      _ => null,
    };
  }
}