/// 便签正文图片载荷。
///
/// 图片以 base64 内嵌，作为正文 `ImageBlock` 的数据载荷，随模块数据一并存储与同步。
class NoteImageAttachment {
  const NoteImageAttachment({
    required this.id,
    required this.dataBase64,
    required this.createdAt,
  });

  /// 附件唯一标识。
  final String id;

  /// base64 编码的图片数据。
  final String dataBase64;

  /// 创建时间。
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dataBase64': dataBase64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteImageAttachment.fromJson(Map<String, dynamic> json) =>
      NoteImageAttachment(
        id: json['id'] as String,
        dataBase64: json['dataBase64'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
