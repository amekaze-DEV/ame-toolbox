import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'file_launcher_service.dart';

/// 基于 [file_picker] + OS 能力的桌面/移动端实现。
///
/// 该文件属于平台实现层，允许使用 `dart:io` 与 `Platform`，仅供条件导入工厂引用，
/// 不直接暴露给 UI 层与模块。file_picker 11.x 的 [FilePicker.saveFile] 为静态方法。
class FileLauncherServiceIO implements FileLauncherService {
  /// 打开字节内容系统默认查看器。
  @override
  Future<void> openBytesWithDefaultApp(Uint8List bytes, String fileName) async {
    final path = await _materializeTempFile(bytes, fileName);
    try {
      await launchSystemViewer(path);
    } catch (_) {
      // 打开失败不影响已写出的临时文件，仅向上抛出，由调用方提示用户。
      rethrow;
    }
  }

  /// 将 [bytes] 写入系统临时目录并返回路径；文件名经清洗避免路径穿越。
  Future<String> _materializeTempFile(Uint8List bytes, String fileName) async {
    final safe = _sanitizeFileName(fileName);
    final dir = Directory.systemTemp.createTempSync('ame_sticky_note_');
    final file = File('${dir.path}${Platform.pathSeparator}$safe');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// 用系统默认应用打开 [path]。子类可覆写以用于测试。
  Future<void> launchSystemViewer(String path) async {
    await Process.run('cmd', ['/c', 'start', '', path]);
  }

  /// 弹出“另存为”对话框并落盘；取消返回 null。
  @override
  Future<String?> saveBytesWithDialog(
    Uint8List bytes,
    String fileName,
  ) async {
    final path = await FilePicker.saveFile(
      fileName: fileName,
      type: FileType.any,
      bytes: bytes,
      lockParentWindow: true,
    );
    if (path == null || path.isEmpty) return null;
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// 清洗文件名：去掉路径分隔符与常见穿越片段，避免拼进临时路径导致穿越。
  String _sanitizeFileName(String name) {
    final cleaned = name
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('..', '_')
        .replaceAll(':', '_')
        .trim();
    return cleaned.isEmpty ? 'attachment' : cleaned;
  }
}