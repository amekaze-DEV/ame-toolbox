/// 待办分类。
class TodoCategory {
  const TodoCategory({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.displayOrder,
  });

  /// 唯一标识。内置分类使用固定 id（`work` / `life` / `other`），
  /// 自定义分类使用 `category_` 前缀。
  final String id;

  /// 分类名称。
  final String name;

  /// ARGB 整数值。
  final int colorValue;

  /// 显示顺序（升序）。
  final int displayOrder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'displayOrder': displayOrder,
      };

  factory TodoCategory.fromJson(Map<String, dynamic> json) => TodoCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        displayOrder: json['displayOrder'] as int,
      );

  TodoCategory copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? displayOrder,
  }) =>
      TodoCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        displayOrder: displayOrder ?? this.displayOrder,
      );
}