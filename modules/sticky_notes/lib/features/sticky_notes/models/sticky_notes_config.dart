import 'note_category.dart';
import 'note_sort_mode.dart';

/// 模块级根配置。
class StickyNotesConfig {
  /// 模块内置默认分类（spec §2.3）。
  static const List<NoteCategory> defaultCategories = [
    NoteCategory(id: 'work', name: '工作', colorValue: 0xFF1565C0, displayOrder: 0),
    NoteCategory(id: 'life', name: '生活', colorValue: 0xFF2D7D46, displayOrder: 1),
    NoteCategory(id: 'other', name: '其他', colorValue: 0xFF6A1B9A, displayOrder: 2),
  ];

  const StickyNotesConfig({
    this.categories = defaultCategories,
    this.defaultSortMode = NoteSortMode.updatedDesc,
  });

  /// 分类列表，按 displayOrder 排序。
  final List<NoteCategory> categories;

  /// 默认排序方式。
  final NoteSortMode defaultSortMode;

  static const _schemaVersion = 1;

  Map<String, dynamic> toJson() => {
        'schemaVersion': _schemaVersion,
        'categories': categories.map((c) => c.toJson()).toList(),
        'defaultSortMode': defaultSortMode.jsonValue,
      };

  factory StickyNotesConfig.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;
    // 当前仅支持 schemaVersion 1；后续版本可在此分支迁移逻辑。
    assert(schemaVersion == 1,
        'Unsupported StickyNotesConfig schema version: $schemaVersion');
    return StickyNotesConfig(
      categories: switch (json['categories'] as List<dynamic>?) {
        // 仅缺省时（旧数据 / 首次运行）回退内置分类；
        // 显式空列表表示用户已删除全部分类，需原样保留（分类均可删除）。
        null => defaultCategories,
        final list => list
            .map((e) => NoteCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      },
      defaultSortMode: switch (json['defaultSortMode'] as String?) {
        null => NoteSortMode.updatedDesc,
        final value => NoteSortMode.fromJson(value),
      },
    );
  }

  StickyNotesConfig copyWith({
    List<NoteCategory>? categories,
    NoteSortMode? defaultSortMode,
  }) =>
      StickyNotesConfig(
        categories: categories ?? this.categories,
        defaultSortMode: defaultSortMode ?? this.defaultSortMode,
      );
}
