import 'dart:typed_data';

/// 用户通过系统文件选择器选取的单个文件。
///
/// 仅持有元数据，字节内容通过 [readBytes] 按需读取，避免大图常驻内存。
/// 该值对象对 UI 层与模块透明，不暴露底层平台实现细节。
class PickedFile {
  const PickedFile({
    required this.name,
    required this.path,
    this.extension,
    this.sizeBytes,
    this.mimeType,
    this.readBytes,
  });

  /// 文件名（含扩展名，如 "photo.png"）。
  final String name;

  /// 文件在本地文件系统中的绝对路径。
  ///
  /// 在部分平台（如 Web）可能为空，由调用方据此决定是否回退到 [readBytes]。
  final String path;

  /// 文件扩展名（不含点，如 "png"）；无扩展名时为 null。
  final String? extension;

  /// 文件大小（字节）；未知时为 null。
  final int? sizeBytes;

  /// MIME 类型；未知时为 null。
  final String? mimeType;

  /// 读取文件字节内容的回调；未提供时返回空字节。
  final Future<Uint8List> Function()? readBytes;

  /// 按需读取文件字节内容。
  ///
  /// 若创建时未提供读取回调，返回空字节数组。
  Future<Uint8List> readContent() async {
    final loader = readBytes;
    if (loader == null) return Uint8List(0);
    return loader();
  }
}