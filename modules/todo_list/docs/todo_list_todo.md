# 待办清单模块 — 可分步实施开发计划（任务清单）

> **文档类型**: 子项目开发任务清单（step-by-step）
> **模块 ID**: `todo_list`
> **版本**: v1.0
> **状态**: 已定稿
> **需求基线**: `todo_list_spec.md` v1.2
> **方案基线**: `todo_list_plan.md` v1.1
> **代码规范**: `todo_list_coding_standards.md` v1.1
> **隔离约束**: 临时底座开发期间任何代码修改不涉及主线（见 `plan.md §1.0`）

---

## 0. 基线说明与前置

### 0.1 文档基线对齐

| 文档 | 版本 | 是否与 spec v1.2 一致 | 需处理 |
|------|------|------------------------|--------|
| `todo_list_spec.md` | v1.2 | —（需求基线） | 无 |
| `todo_list_plan.md` | v1.1 | 是（引用 spec） | 无 |
| `todo_list_coding_standards.md` | v1.1 | 是（已同步 design v1.1） | 无 |
| `todo_list_design.md` | v1.1 | 是（已同步 spec v1.2） | 无 |

> **✅ 前置任务 P0 已完成**：`todo_list_design.md` 已从 v1.0 同步至 v1.1（新增类日历布局、5 级优先级、`RecurrencePattern` 循环 sealed class、图片附件 base64、导出、循环规则 UI 层级等，并新增 ADR-TDL-002/003/006）；`todo_list_coding_standards.md` 已同步至 v1.1（目录结构、命名规范、测试范围、状态管理变更项）。可进入 P1。

### 0.2 开发顺序总览

```text
P0 文档同步 → P1 临时应用骨架 → P2 模型+存储 → P3 服务层 → P4 状态管理
→ P5 主页面UI → P6 详情/表单UI → P7 设置页UI → P8 合并主线 → P9 清理 → P10 首页卡片
```

### 0.3 每阶段通用验收

- `flutter analyze` 零报错。
- `flutter test` 通过；累计覆盖率 ≥80%。
- 模块 `lib/features/` 与 `lib/shared/` 无 `Platform.is*` / `dart:io`。
- 仅编辑 `modules/todo_list/` 内文件。

---

## 1. P1 临时应用骨架（对应 plan M1）

### 任务

| # | 任务 | 产出文件 | 备注 |
|---|------|----------|------|
| P1.1 | 建立模块包骨架 | `modules/todo_list/pubspec.yaml` | path 依赖 `ametoolbox: path: ../../`；sdk ^3.12.2；dev 依赖 flutter_test/flutter_lints |
| P1.2 | 配置分析规范 | `modules/todo_list/analysis_options.yaml` | 继承或复制主线 lint 规则 |
| P1.3 | 生成 Windows 独立运行壳 | `modules/todo_list/windows/` | 参照 shift_assistant 的 windows 壳 |
| P1.4 | 内存 StorageService | `lib/debug/memory_storage_service.dart` | 实现 `StorageService`，内存 Map，不碰 Hive |
| P1.5 | 简化 DeviceInfo | `lib/debug/fake_device_info.dart` | 固定 DPI/内存值，规避 `device_info_plus` Windows 异常 |
| P1.6 | no-op 通知服务 | `lib/debug/noop_notification_service.dart` | 实现 `NotificationService`，空操作 |
| P1.7 | 临时入口 | `lib/main.dart` | override storage/device/theme/layout/input/notification；双页调试外壳（主页面/设置页）；MD3 主题复用 `Md3ColorScheme.fromAccent` |
| P1.8 | 空模块占位 | `lib/features/todo_list/todo_list_module.dart` | 先实现 `ModuleContract` 占位，页面返回 "开发中" |
| P1.9 | 运行验证 | — | `flutter pub get` + `flutter run -d windows --debug`（需本机开发者模式） |

### 验收

- 空壳可独立运行，双页选项卡可切换，横竖屏窗口切换触发断点。
- 不触碰任何主线文件。

> **✅ P1 已完成**：`flutter pub get` 成功，`flutter analyze` 零报错。所有文件位于 `modules/todo_list/` 内，未触碰主线代码。可进入 P2。
>
> **✅ P2 已完成**：所有模型（优先级、分类、配置、图片附件、循环值对象、循环策略 sealed class 14 种、循环规则、待办项、摘要）与 2 个 Repository 已实现；JSON 携带 `schemaVersion`；模型与 Repository 单元测试全部通过（48 个测试）。`flutter analyze` 零报错、`flutter test` 全绿。可进入 P3。
>
> **✅ P3 已完成**：5 个服务已实现（循环日期计算引擎 14 种 + 4 类越界、多规则合并、查询/排序/摘要、提醒调度、.md 导出）；服务层单元测试 47 个全部通过。累计 `flutter test` 95 个全绿、`flutter analyze` 零报错。可进入 P4。
>
> **✅ P4 已完成**：状态管理已实现——`TodoConfigController`（分类/提醒/日常置顶）、`TodoListController`（增删改、完成切换入历史、循环模板自动补齐实例、import 合并、提醒重调度）、摘要 Provider、以及 Repository/Resolver/Query/Reminder/Export 各服务 Provider。累计 `flutter test` 105 个全绿、`flutter analyze` 零报错。可进入 P5。
>
> **✅ P5 已完成**：主页面 UI 已实现——类日历月视图（翻月/今天/选中/有待办标记）、当日待办列表（优先级排序、日常置顶、过期 error 色、完成删除线、点击进详情、长按/右键编辑删除、删除确认）、空状态、横竖屏 ResponsiveBuilder 布局。新增 Widget 测试 4 个。累计 `flutter test` 109 个全绿、`flutter analyze` 零报错。可进入 P6。
>
> **✅ P6 已完成**：详情/编辑页已实现——名称/详情文本、图片附件（缩略图/删除/大图缩放预览/添加）、5 级优先级 SegmentedButton、一次性/循环切换、循环规则设定器（多规则列表 + 新增/编辑对话框 + 五级菜单 14 种参数表单 + 起止时间）、提前提醒、空名称校验拦截。主页面新增/点击卡片入口已接入 `TodoDetailPage`。新增测试 14 个（详情页 4 + describeRule 10）。累计 `flutter test` 123 个全绿、`flutter analyze` 零报错。可进入 P7。
>
> **✅ P7 已完成**：设置页已实现——分类管理（增删改/拖拽排序/颜色选择）、提醒设置（全局开关 + 默认提前分钟数）、列表显示（日常事项置顶）、导出（复制为 Markdown，Flutter 内置剪贴板）。`buildSettingsPage` 已接入 `TodoListSettingsPage`。调整 `reorderCategories` 为 `onReorderItem` 新语义并同步测试。新增测试 5 个。累计 `flutter test` 128 个全绿、`flutter analyze` 零报错。可进入 P8。

---

## 2. P2 数据模型与存储层

### 任务（`lib/features/todo_list/models/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P2.1 | 优先级枚举 | `todo_priority.dart` | spec §2.6：highest/high/medium/normal/daily |
| P2.2 | 分类模型 | `todo_category.dart` | spec §2.3 |
| P2.3 | 配置模型 | `todo_config.dart` | spec §2.2：categories + remindEnabled + defaultRemindMinutes |
| P2.4 | 图片附件模型 | `todo_image_attachment.dart` | spec §2.5：id + dataBase64 + createdAt |
| P2.5 | 循环值对象 | `recurrence_value_objects.dart` | spec §2.7.4：WeekDay/MonthInQuarterDay/MonthInQuarterWeekDay/MonthDay/MonthWeekDay/QuarterDay/YearQuarterMonthDay/QuarterWeekDay/YearQuarterMonthWeekDay |
| P2.6 | 循环策略 sealed class | `recurrence_pattern.dart` | spec §2.7.3：14 个 `final class` + `type` discriminator |
| P2.7 | 循环规则 | `recurrence_rule.dart` | spec §2.7.1：pattern + startDate + endDate |
| P2.8 | 待办项模型 | `todo_item.dart` | spec §2.4：title/details/images/categoryId/priority/dueDate/recurrenceRules/remindMinutes/isCompleted/.../isArchived |
| P2.9 | 摘要模型 | `todo_list_summary.dart` | spec §2.8：total/pendingCount/todayCount/overdueCount |
| P2.10 | 各模型 `toJson`/`fromJson` | 同上 | spec §7：JSON 携带 schema 版本；sealed class 用 type 分发 |

### 任务（`lib/features/todo_list/data/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P2.11 | 配置 Repository | `data/todo_config_repository.dart` | key `module_todo_list_config`；默认分类首次写入 |
| P2.12 | 待办 Repository | `data/todo_list_repository.dart` | key `module_todo_list_items`；列表整体存取 |

### 验收

- 模型 JSON 往返正确（含 sealed class 各子类 round-trip）。
- 单元测试：每个模型 + 2 个 Repository。

---

## 3. P3 服务层（`lib/features/todo_list/services/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P3.1 | 循环日期计算引擎 | `recurrence_date_calculator.dart` | spec §2.7.6：`generateDates(rule, from, to)`，switch 分发 14 种 |
| P3.2 | 多规则合并解析 | `todo_recurrence_resolver.dart` | spec §2.7.5：`resolve(item, from, to)`，空规则走一次性 dueDate |
| P3.3 | 查询/排序服务 | `todo_query_service.dart` | spec §4.1：优先级排序 + 日常置顶选项；过期判定 |
| P3.4 | 提醒服务 | `todo_reminder_service.dart` | spec §4.5：时间计算、通知 id `module_todo_list_item_<id>`、重调度/取消 |
| P3.5 | 导出服务 | `todo_export_service.dart` | spec §4.6：生成 .md、复制剪贴板 |

### 验收

- 循环计算：覆盖 14 种方式 + 4 类边界（月日越界/季度天数/年天数/周-周几）单测。
- 多规则合并去重、升序正确。
- 提醒服务：时间计算、完成/删除/配置变更重调度逻辑单测。
- 导出：.md 文本结构与剪贴板复制单测。

---

## 4. P4 状态管理（`lib/features/todo_list/providers/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P4.1 | 配置 Controller | `todo_config_controller.dart` + `todo_config_provider.dart` | design §2 Provider 清单 |
| P4.2 | 待办列表 Controller | `todo_list_controller.dart` + `todo_list_provider.dart` | 增删改、完成切换、导入 |
| P4.3 | 摘要 Provider | `todo_summary_provider.dart` | 派生自 todoListProvider |
| P4.4 | 提醒服务 Provider | `todo_reminder_service_provider.dart` | 依赖底座通知服务 |

### 验收

- Controller 变更即持久化；Widget 通过 `ref.watch/read` 访问。
- 完成/取消完成、一次性入历史、循环补实例逻辑正确（依赖 P3）。

---

## 5. P5 主页面 UI（对应 plan M2）

### 任务（`lib/features/todo_list/pages/` + `widgets/`）

| # | 任务 | 产出文件 |
|---|------|----------|
| P5.1 | 主页面（日历 + 列表） | `pages/todo_list_page.dart` |
| P5.2 | 类日历月视图组件 | `widgets/todo_month_calendar_view.dart`（翻月/今天/选中/有待办标记） |
| P5.3 | 待办卡片 | `widgets/todo_item_tile.dart`（仅名称 + 优先级色标 + 期限/循环标） |
| P5.4 | 完成勾选组件 | `widgets/todo_check_button.dart` |
| P5.5 | 空/历史视图 | `widgets/todo_empty_view.dart` 等 |
| P5.6 | 横竖屏布局 | 用底座 `ResponsiveBuilder` 包裹；竖屏堆叠、横屏并排/增列 |

### 交互（spec §3.2）

- 点击日历日期 → 列表联动；点击卡片进详情；勾选完成；长按/右键上下文（编辑/删除）；删除确认 `AlertDialog`。
- 优先级排序 + 日常置顶；已过期 `error` 色；已完成删除线。

### 验收

- 竖屏/横屏均无溢出，切换正常。
- 触控与键鼠交互可用。

---

## 6. P6 详情页 / 新增编辑表单（对应 plan M2）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P6.1 | 详情/编辑页 | `pages/todo_detail_page.dart` | spec §3.3：名称/详情/图片/优先级/期限/循环/起止时间/提醒 |
| P6.2 | 图片附件管理 | `widgets/todo_image_attachments_editor.dart` | 添加/删除/缩略图/大图预览 |
| P6.3 | 优先级选择 | 复用 `SegmentedButton` | spec §3.6 5 级色标 |
| P6.4 | 循环规则设定器 | `widgets/recurrence_rule_editor.dart` | spec §3.4：五级菜单层级 + 多规则列表 |
| P6.5 | 规则参数表单 | `widgets/recurrence_form_{unit}.dart` | 对应 14 种方式的参数表单 |
| P6.6 | 校验 | — | 空名称拦截；循环规则有效性 |

### 验收

- 五级菜单可逐级选择并生成对应 `RecurrencePattern`；多规则可增删。
- 图片附件可增删预览；保存/取消正确。

---

## 7. P7 设置页 UI（对应 plan M3）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P7.1 | 设置页 | `pages/todo_list_settings_page.dart` | spec §3.5 |
| P7.2 | 分类管理 | `widgets/todo_category_manager.dart` | 增删改/排序分类 |
| P7.3 | 提醒设置 | — | 全局开关 + 默认提前分钟数 |
| P7.4 | 导出入口 | — | .md 导出 / 复制剪贴板 |

### 验收

- 设置页横竖屏正常；分类/提醒/导出可用。

---

## 8. P8 合并进主线（对应 plan M4 · 需 OWNER 确认）

> 触碰主线，必须在开发完成并经 OWNER 书面确认后进行。

| # | 任务 | 涉及文件（主线） |
|---|------|------------------|
| P8.1 | 主项目加 path 依赖 | 主项目 `pubspec.yaml`：`todo_list_module: { path: modules/todo_list }` |
| P8.2 | 注册模块 | 主线 `lib/core/modules/module_registry.dart`：新增 `'todo_list' => TodoListModule()` + import |
| P8.3 | 确认底座配置 | 主线 `lib/core/constants.dart`：`defaultModules` 是否已含 `todo_list`；`module_icon_mapper.dart` `todo` 图标（已确认存在） |
| P8.4 | 主线回归验证 | `flutter analyze` + `flutter test` + 运行验证 |

---

## 9. P9 清理临时应用（对应 plan M5）

删除（仅限模块内）：

- `lib/main.dart`
- `lib/debug/` 整个目录
- `windows/`（及 `.metadata` 独立运行配置）
- `pubspec.yaml` 中独立运行引入的额外依赖

保留：`lib/features/todo_list/`、`test/`、`docs/`、`pubspec.yaml`（含 path 依赖底座）。

主线回归验证。

---

## 10. P10 首页卡片与后续（对应 plan M6）

| # | 任务 | 依据 |
|---|------|------|
| P10.1 | 首页摘要卡片 | `ModuleContract.summary`（未完成数） |
| P10.2 | 自定义入口卡片（可选） | `buildEntryCard` / `hasCustomEntryCard` |
| P10.3 | 仪表盘额外卡片（可选） | `buildDashboardWidgets` |
| P10.4 | 与主线共同 debug | 横竖屏、同步、提醒、导出联调 |
| P10.5 | 数据同步实现 | `TodoListModule.exportData` / `importData`：导出 `module_todo_list_config` 与 `module_todo_list_items`（含图片 base64），整体替换 + id 合并（以 `updatedAt` 较新者为准），见 spec §5 / ADR-TDL-005/006 |

---

## 11. 依赖与里程碑对照

| 开发阶段 | 对应 plan 里程碑 | 触碰主线 |
|----------|------------------|----------|
| P0 文档同步 | （前置） | 否 |
| P1 临时骨架 | M1 | 否 |
| P2 模型+存储 | M1/M2 | 否 |
| P3 服务层 | M1/M2 | 否 |
| P4 状态管理 | M2 | 否 |
| P5 主页面UI | M2 | 否 |
| P6 详情/表单UI | M2 | 否 |
| P7 设置页UI | M3 | 否 |
| P8 合并主线 | M4 | **是** |
| P9 清理临时应用 | M5 | 否 |
| P10 首页卡片 | M6 | 视实现 |

---

## 12. 引用文档

- [todo_list_spec.md](./todo_list_spec.md) v1.2（需求）
- [todo_list_plan.md](./todo_list_plan.md) v1.1（方案）
- [todo_list_design.md](./todo_list_design.md) v1.1（已同步 spec v1.2）
- [todo_list_coding_standards.md](./todo_list_coding_standards.md) v1.1（代码规范）