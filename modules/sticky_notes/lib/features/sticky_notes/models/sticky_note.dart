import 'note_block.dart';
import 'note_image_attachment.dart';

/// 单个便签。
class StickyNote {
  const StickyNote({
    required this.id,
    required this.title,
    this.content = const [],
    this.categoryId,
    this.isPinned = false,
    this.pinnedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 唯一标识。
  final String id;

  /// 标题（主要内容），必填。
  final String title;

  /// 富文本正文（块列表，图片为其中的 [ImageBlock]）。
  final List<NoteBlock> content;

  /// 关联 `NoteCategory.id`，可为 null（无分类）。
  final String? categoryId;

  /// 是否置顶。
  final bool isPinned;

  /// 置顶时间（置顶排序用），非置顶为 null。
  final DateTime? pinnedAt;

  /// 创建时间。
  final DateTime createdAt;

  /// 最后更新时间。
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content.map((e) => e.toJson()).toList(),
        if (categoryId != null) 'categoryId': categoryId,
        'isPinned': isPinned,
        if (pinnedAt != null) 'pinnedAt': pinnedAt!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 从 JSON 反序列化。
  ///
  /// 兼容旧格式（v1）：旧的独立图片附件数组 `images` 会被迁移为正文末尾的
  /// [ImageBlock]，下次保存后即自然落为新格式。
  factory StickyNote.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>?)
            ?.map((e) => NoteBlock.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <NoteBlock>[];
    final legacyImages = json['images'] as List<dynamic>?;
    final migrated = (legacyImages == null || legacyImages.isEmpty)
        ? content
        : <NoteBlock>[
            ...content,
            for (final e in legacyImages)
              ImageBlock(
                attachment:
                    NoteImageAttachment.fromJson(e as Map<String, dynamic>),
              ),
          ];
    return StickyNote(
      id: json['id'] as String,
      title: json['title'] as String,
      content: migrated,
      categoryId: json['categoryId'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.parse(json['pinnedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 创建副本。
  ///
  /// `categoryId` 与 `pinnedAt` 为可空字段，需要真正置空时
  /// 分别使用 [clearCategoryId] / [clearPinnedAt] 标志（clear 优先）。
  StickyNote copyWith({
    String? id,
    String? title,
    List<NoteBlock>? content,
    String? categoryId,
    bool clearCategoryId = false,
    bool? isPinned,
    DateTime? pinnedAt,
    bool clearPinnedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      StickyNote(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
        isPinned: isPinned ?? this.isPinned,
        pinnedAt: clearPinnedAt ? null : (pinnedAt ?? this.pinnedAt),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}