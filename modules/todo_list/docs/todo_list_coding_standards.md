# 待办清单模块 — 代码规范

> **文档类型**: 子项目代码规范
> **模块 ID**: `todo_list`
> **约束基线**: `design.md` + `project_constraints.md` + `todo_list_design.md` v1.1
> **版本**: v1.1
> **状态**: 已定稿（同步至 design v1.1 / spec v1.2）

---

## 1. 适用范围

本规范适用于 `modules/todo_list/` 子项目内全部 Dart 代码。所有代码修改**严格限制在本子模块范围内**；如需调整底座 APP 内容（`lib/` 下任何文件或主项目 `pubspec.yaml`），必须事先获得 OWNER 确认。

---

## 2. 技术栈与依赖约束

| 约束 | 说明 |
|------|------|
| 框架 | Flutter + Riverpod |
| 状态管理 | 使用 `ConsumerWidget` + `ref.watch/read`，禁用 `setState` + `InheritedWidget` |
| 禁止依赖 | `dart:io`（UI 层）、`Platform.is*`、平台专有插件 |
| 允许新增依赖 | 仅限底座已声明依赖（如 `intl`）；新增依赖须经 OWNER 确认 |
| 通知 | 统一通过底座 `NotificationService`，模块内不得直接使用通知插件 |

---

## 3. MD3 组件使用规范

### 3.1 必须使用的 MD3 内置组件

| 场景 | 组件 |
|------|------|
| 主要操作按钮 | `FilledButton` |
| 次要操作按钮 | `OutlinedButton` / `ElevatedButton` |
| 低权重操作 | `TextButton`（如对话框取消） |
| 图标按钮 | 底座 `AdaptiveIconButton` |
| 开关切换 | 底座 `MD3Switch` |
| 列表项 | 底座 `AdaptiveListTile` |
| 对话框 | `AlertDialog` |
| 顶栏 | `AppBar` |
| 分段选择 | `SegmentedButton`（优先级选择） |
| 下拉选择 | `DropdownMenu` |
| 卡片容器 | `Card`（如需卡片场景） |

### 3.2 禁止事项

- 禁止自定义组件模仿 MD3 组件外观（如自绘按钮、自绘卡片容器）。
- 禁止使用 Cupertino 风格组件。
- 禁止直接使用 `IconButton` / `TextButton` / `FilledButton` / `ListTile` 等底座已封装的自适应组件替代品，须走底座 `AdaptiveButton` / `AdaptiveIconButton` / `AdaptiveListTile`。
- 禁止硬编码颜色、圆角、字号、间距。

### 3.3 MD3 Token 约定

| 类别 | 约定 |
|------|------|
| 颜色 | 全部取自 `Theme.of(context).colorScheme`（如 `primary`、`error`、`surfaceContainerHighest`、`onSurfaceVariant`） |
| 圆角 | 小 4dp（标签/圆点）、中 12dp（列表项/卡片）、大 16dp（对话框容器） |
| 排版 | 使用 `Theme.of(context).textTheme`（如 `titleMedium`、`bodyLarge`），禁止硬编码字号 |
| 动画 | 所有状态过渡动画 300ms + `Curves.easeInOut` |

---

## 4. 目录结构规范

```
lib/
├── main.dart                    #【临时】独立运行入口（合并后删除）
├── debug/                       #【临时】调试支撑（合并后删除）
│   ├── memory_storage_service.dart      # StorageService 内存实现
│   ├── fake_device_info.dart            # 简化 DeviceInfoProvider
│   └── noop_notification_service.dart   # NotificationService no-op
└── features/todo_list/
    ├── todo_list_module.dart   # ModuleContract 入口
    ├── data/                   # Repository（封装 StorageService）
    ├── models/                 # 数据模型与 JSON 序列化
    ├── pages/                  # 页面级 Widget
    ├── providers/              # Riverpod Provider + Controller
    ├── services/               # 纯业务计算服务（循环/查询/提醒/导出）
    └── widgets/                # 模块私有组件
```

---

## 5. 文件命名规范

遵循 `design.md` 第 6.1 节：

| 类型 | 规则 | 示例 |
|------|------|------|
| 模型 | `<name>.dart` | `todo_item.dart`、`recurrence_rule.dart`、`recurrence_pattern.dart` |
| 值对象 | `<name>.dart` | `recurrence_value_objects.dart` |
| Provider | `<name>_provider.dart` | `todo_list_provider.dart` |
| Controller | `<name>_controller.dart` | `todo_list_controller.dart` |
| 服务 | `<name>_service.dart` | `todo_reminder_service.dart`、`recurrence_date_calculator.dart` |
| 页面 | `<name>_page.dart` | `todo_list_page.dart`、`todo_detail_page.dart` |
| Widget | `<name>_widget.dart` 或 `<name>.dart` | `todo_item_tile.dart`、`todo_month_calendar_view.dart` |
| Repository | `<name>_repository.dart` | `todo_list_repository.dart` |

---

## 6. 状态管理规范

- Controller 使用 `ChangeNotifier`，通过 `ChangeNotifierProvider<[ControllerName]>` 托管。
- 变更统一走 Controller 方法（增、删、改、完成切换、循环实例生成、导入），完成后 `notifyListeners()` 并即时持久化。
- Widget 只做展示与交互，不承载业务逻辑；通过 `ref.watch` 读状态、`ref.read` 调方法。
- 派生状态（摘要）用普通 `Provider` + `ref.watch`，不重复持久化。
- 不允许在 Widget 内直接访问 `StorageService` 或 Repository。

---

## 7. 数据存储规范

- 所有读写通过 `StorageService` 抽象接口，禁止直接访问 Hive/文件系统。
- 存储 key 必须使用 `module_todo_list_` 前缀。
- 配置与业务数据分 key 存储（`module_todo_list_config` / `module_todo_list_items`）。
- 模型须实现 `toJson` / `fromJson`，JSON 携带 schema 版本字段以便迁移。

---

## 8. 平台无关性规范

- `lib/features/` 与 `lib/shared/` 下禁止 `Platform.is*` 与 `dart:io`。
- 输入模式判断使用底座 `InputModeScope`。
- 平台差异（如通知）统一走底座抽象，不在模块内实现平台分支。

---

## 9. 代码质量

| 项 | 要求 |
|----|------|
| 静态分析 | `flutter analyze` 零报错 |
| 单元测试 | 覆盖率 ≥80% |
| 测试范围 | 模型 JSON 往返（含 sealed class 各子类）、`RecurrenceDateCalculator`（14 种 + 边界）、`TodoRecurrenceResolver`（多规则合并）、`TodoQueryService`（优先级排序/过期/摘要）、`TodoReminderService`（时间计算/映射/重调度）、`TodoExportService`（.md/剪贴板）、Repository、页面 Widget 测试 |
| 提交前 | 运行 `flutter analyze` 与 `flutter test` 通过 |

---

## 10. 变更管理

- 本规范及子项目文档（spec / design / coding_standards）变更须经 OWNER 确认。
- **严禁**未确认修改底座代码（`lib/` 与主项目 `pubspec.yaml`）。
- 模块合并到底座（注册到 `module_registry.dart`、添加 path 依赖、`main.dart` 注册）属于底座变更，须在模块开发完成并经 OWNER 确认后进行。
