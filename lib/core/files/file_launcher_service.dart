import 'dart:typed_data';

/// 附件/文件「打开与另存」能力统一抽象。
///
/// 模块通过底座提供的 [FileLauncherService] 实现两类平台操作，无需感知平台差异：
/// - 用系统默认应用查看器打开一段字节；
/// - 弹出“另存为”对话框，把字节保存到用户选择的位置。
/// 具体实现按平台分别定义，通过条件导入工厂在编译期选择，UI 层不直接接触
/// `Platform` 或 `dart:io`。
abstract class FileLauncherService {
  /// 用系统默认应用打开 [bytes] 对应的临时文件。
  ///
  /// 内部会把 [bytes] 写入系统临时目录（文件名保留 [fileName] 的扩展名，以便
  /// 系统据此确定默认查看器），再用操作系统的默认应用打开。临时文件仅临时存在，
  /// 不会写入用户可见的文档目录。若打开失败，抛出异常由调用方兜底。
  Future<void> openBytesWithDefaultApp(Uint8List bytes, String fileName);

  /// 弹出“另存为”对话框，将 [bytes] 保存到用户选择的位置，并返回保存路径。
  ///
  /// 用户取消时返回 null。
  Future<String?> saveBytesWithDialog(Uint8List bytes, String fileName);
}