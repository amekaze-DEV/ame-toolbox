/// 待办详情图片附件。
///
/// 图片以 base64 内嵌于 [TodoItem.images]，随模块数据一并存储与同步。
class TodoImageAttachment {
  const TodoImageAttachment({
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

  factory TodoImageAttachment.fromJson(Map<String, dynamic> json) =>
      TodoImageAttachment(
        id: json['id'] as String,
        dataBase64: json['dataBase64'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}