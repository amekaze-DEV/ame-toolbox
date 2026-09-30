import 'dart:typed_data';

import 'package:ametoolbox/core/files/file_launcher_service.dart';
import 'package:ametoolbox/core/files/file_picker_service.dart';
import 'package:ametoolbox/core/files/picked_file.dart';

/// 构造选取结果；[declaredSize] 用于模拟系统上报大小（可与实际字节不同）。
PickedFile fakePickedFile({
  required String name,
  List<int> bytes = const [1, 2, 3],
  String? mimeType,
  int? declaredSize,
}) =>
    PickedFile(
      name: name,
      path: 'C:/tmp/$name',
      extension: name.contains('.') ? name.split('.').last : null,
      sizeBytes: declaredSize ?? bytes.length,
      mimeType: mimeType,
      readBytes: () async => Uint8List.fromList(bytes),
    );

/// 文件选择替身：按队列依次返回，队列为空视为“用户取消”。
class FakeFilePickerService implements FilePickerService {
  final List<PickedFile> pickFileQueue = [];
  final List<List<PickedFile>> pickImagesQueue = [];

  @override
  Future<PickedFile?> pickFile({List<String>? allowedExtensions}) async =>
      pickFileQueue.isEmpty ? null : pickFileQueue.removeAt(0);

  @override
  Future<PickedFile?> pickImage({List<String>? allowedExtensions}) async =>
      pickFileQueue.isEmpty ? null : pickFileQueue.removeAt(0);

  @override
  Future<List<PickedFile>> pickImages({List<String>? allowedExtensions}) async =>
      pickImagesQueue.isEmpty ? const [] : pickImagesQueue.removeAt(0);
}

/// 打开 / 另存替身：记录调用并按配置返回结果。
class FakeFileLauncherService implements FileLauncherService {
  final List<String> openedFileNames = [];
  final List<Uint8List> openedBytes = [];
  final List<String> savedFileNames = [];

  /// 打开时是否抛异常（模拟系统无默认查看器）。
  bool failOnOpen = false;

  /// 另存为返回路径；null 表示用户取消。
  String? savePath;

  @override
  Future<void> openBytesWithDefaultApp(Uint8List bytes, String fileName) async {
    if (failOnOpen) throw StateError('no viewer');
    openedFileNames.add(fileName);
    openedBytes.add(bytes);
  }

  @override
  Future<String?> saveBytesWithDialog(Uint8List bytes, String fileName) async {
    savedFileNames.add(fileName);
    return savePath;
  }
}