import 'package:hive/hive.dart';

part 'module_definition.g.dart';

/// 模块定义数据。
///
/// 描述一个功能模块的元信息，由底座在首次启动时初始化。
@HiveType(typeId: 1)
class ModuleDefinition {
  const ModuleDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.iconName,
    this.defaultEnabled = true,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String iconName;

  @HiveField(4, defaultValue: true)
  final bool defaultEnabled;
}
