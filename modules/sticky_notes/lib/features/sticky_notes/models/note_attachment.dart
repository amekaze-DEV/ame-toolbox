/// 便签文件附件（仅元数据）。
///
/// 二进制内容不内嵌于此；字节按附件 id 单独存储于
/// `module_sticky_notes_attachments_<id>`（见 [NoteAttachmentStore]），
/// 使大文件不随便签列表常驻内存。
class NoteAttachment {
  const NoteAttachment({
    required this.id,
    required this.fileName,
    required this.sizeBytes,
    this.mimeType,
    required this.createdAt,
  });

  /// 附件唯一标识（形如 `att_<uuid>`）。
  final String id;

  /// 文件名（含扩展名）。
  final String fileName;

  /// 文件大小（字节）。
  final int sizeBytes;

  /// MIME 类型（可选）。
  final String? mimeType;

  /// 创建时间。
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        if (mimeType != null) 'mimeType': mimeType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteAttachment.fromJson(Map<String, dynamic> json) =>
      NoteAttachment(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        sizeBytes: json['sizeBytes'] as int,
        mimeType: json['mimeType'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}