import 'note_image_attachment.dart';
import 'note_inline.dart';

/// 正文块（sealed class）。
///
/// 正文由「文本块 + 图片块」按顺序组成，实现图文混排；
/// 不区分标题 / 列表 / 引用等块类型，一个便签对应一段图文内容。
///
/// JSON 序列化使用 `type` discriminator 标识具体子类。
sealed class NoteBlock {
  const NoteBlock({required this.inlines});

  /// 行内元素列表（图片块恒为空）。
  final List<NoteInline> inlines;

  /// JSON 序列化判别标识。
  String get type;

  Map<String, dynamic> toJson();

  /// 已废弃的块类型标识（取消块类型前的历史数据）。
  ///
  /// 读取时统一降级为普通文本块，保留文本内容，避免旧数据解析失败。
  static const Set<String> legacyTypeNames = {
    'heading',
    'bullet',
    'numbered',
    'checkList',
    'quote',
  };

  /// 从 JSON 反序列化，按 `type` 分发到具体子类。
  static NoteBlock fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    if (legacyTypeNames.contains(type)) {
      return ParagraphBlock(
        inlines: inlinesFromJson(json['inlines'] as List<dynamic>?),
      );
    }
    return switch (type) {
      ParagraphBlock.typeName => ParagraphBlock.fromJson(json),
      ImageBlock.typeName => ImageBlock.fromJson(json),
      _ => throw ArgumentError('Unknown NoteBlock type: $type'),
    };
  }

  /// 序列化行内元素列表。
  static List<Map<String, dynamic>> inlinesToJson(List<NoteInline> inlines) =>
      inlines.map((e) => e.toJson()).toList();

  /// 反序列化行内元素列表。
  static List<NoteInline> inlinesFromJson(List<dynamic>? json) =>
      json
          ?.map((e) => NoteInline.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NoteInline>[];
}

/// 文本块（普通段落）。
final class ParagraphBlock extends NoteBlock {
  const ParagraphBlock({required super.inlines});

  /// JSON 判别标识。
  static const typeName = 'paragraph';

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'inlines': NoteBlock.inlinesToJson(inlines),
      };

  factory ParagraphBlock.fromJson(Map<String, dynamic> json) => ParagraphBlock(
        inlines: NoteBlock.inlinesFromJson(json['inlines'] as List<dynamic>?),
      );
}

/// 图片块。
///
/// 图片以 base64 内嵌为正文的一个块，与文本块按顺序排列，实现图文混排。
final class ImageBlock extends NoteBlock {
  const ImageBlock({required this.attachment}) : super(inlines: const []);

  /// 图片数据载荷。
  final NoteImageAttachment attachment;

  /// JSON 判别标识。
  static const typeName = 'image';

  @override
  String get type => typeName;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'image': attachment.toJson(),
      };

  factory ImageBlock.fromJson(Map<String, dynamic> json) => ImageBlock(
        attachment: NoteImageAttachment.fromJson(
          json['image'] as Map<String, dynamic>,
        ),
      );
}