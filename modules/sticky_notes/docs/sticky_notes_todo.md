# 便签模块 — 可分步实施开发计划（任务清单）

> **文档类型**: 子项目开发任务清单（step-by-step）
> **模块 ID**: `sticky_notes`
> **版本**: v1.0
> **状态**: 草案
> **需求基线**: `sticky_notes_spec.md` v1.0
> **方案基线**: `sticky_notes_plan.md` v1.0
> **代码规范**: `sticky_notes_coding_standards.md` v1.0
> **隔离约束**: 临时底座开发期间任何代码修改不涉及主线（见 `plan.md §1.0`）

---

## 0. 基线说明与前置

### 0.1 文档基线对齐

| 文档 | 版本 | 是否与 spec v1.0 一致 | 需处理 |
|------|------|------------------------|--------|
| `sticky_notes_spec.md` | v1.0 | —（需求基线） | 无 |
| `sticky_notes_plan.md` | v1.0 | 是（引用 spec） | 无 |
| `sticky_notes_coding_standards.md` | v1.0 | 是（同步 design v1.0） | 无 |
| `sticky_notes_design.md` | v1.0 | 是（同步 spec v1.0） | 无 |

### 0.2 开发顺序总览

```text
P0 文档同步 → P1 临时应用骨架 → P2 模型+存储 → P3 服务层 → P4 状态管理
→ P5 主页面UI → P6 详情/编辑UI → P7 设置页UI → P7.5 正文重构（博客式富文本）→ P7.6 正文简化与样式选择器 → P8 合并主线 → P9 清理 → P10 首页卡片
```

### 0.3 每阶段通用验收

- `flutter analyze` 零报错。
- `flutter test` 通过；累计覆盖率 ≥80%。
- 模块 `lib/features/` 与 `lib/shared/` 无 `Platform.is*` / `dart:io`。
- 仅编辑 `modules/sticky_notes/` 内文件。

---

## 1. P1 临时应用骨架（对应 plan M1）

### 任务

| # | 任务 | 产出文件 | 备注 |
|---|------|----------|------|
| P1.1 | 建立模块包骨架 | `modules/sticky_notes/pubspec.yaml` | path 依赖 `ametoolbox: path: ../../`；sdk 与主线一致；dev 依赖 flutter_test/flutter_lints |
| P1.2 | 配置分析规范 | `modules/sticky_notes/analysis_options.yaml` | 继承或复制主线 lint 规则 |
| P1.3 | 生成 Windows 独立运行壳 | `modules/sticky_notes/windows/` | 参照 shift_assistant 的 windows 壳 |
| P1.4 | 内存 StorageService | `lib/debug/memory_storage_service.dart` | 实现 `StorageService`，内存 Map，不碰 Hive |
| P1.5 | 简化 DeviceInfo | `lib/debug/fake_device_info.dart` | 固定 DPI/内存值，规避 `device_info_plus` Windows 异常 |
| P1.6 | no-op 通知服务（如需） | `lib/debug/noop_notification_service.dart` | 实现 `NotificationService`，空操作 |
| P1.7 | 临时入口 | `lib/main.dart` | override storage/device/theme/layout/input；双页调试外壳（主页面/设置页）；MD3 主题复用 `Md3ColorScheme.fromAccent` |
| P1.8 | 空模块占位 | `lib/features/sticky_notes/sticky_notes_module.dart` | 先实现 `ModuleContract` 占位，页面返回 "开发中" |
| P1.9 | 运行验证 | — | `flutter pub get` + `flutter run -d windows --debug`（需本机开发者模式） |

### 验收

- 空壳可独立运行，双页选项卡可切换，横竖屏窗口切换触发断点。
- 不触碰任何主线文件。

> **✅ P1 已完成**：`flutter pub get` 成功（沙箱阻止插件符号链接创建，需非沙箱模式运行）、`flutter analyze` 零报错。所有文件位于 `modules/sticky_notes/` 内，未触碰主线代码。说明：按 plan §2.1 备注便签模块不涉及通知调度，`noop_notification_service.dart` 暂不创建，后续功能如需再补。`flutter run -d windows --debug` 需本机 Windows 开发者模式，由 OWNER 手动验证。可进入 P2。

---

## 2. P2 数据模型与存储层

### 任务（`lib/features/sticky_notes/models/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P2.1 | 排序枚举 | `note_sort_mode.dart` | spec §2.7：updatedDesc/createdDesc/titleAsc |
| P2.2 | 分类模型 | `note_category.dart` | spec §2.3：id/name/colorValue/displayOrder |
| P2.3 | 配置模型 | `sticky_notes_config.dart` | spec §2.2：categories + defaultSortMode |
| P2.4 | 行内元素 | `note_inline.dart` | spec §2.6：text/bold/italic/strikethrough/link |
| P2.5 | 富文本块 sealed class | `note_block.dart` | spec §2.5：Paragraph/Heading/Bullet/Numbered/CheckList/Quote + `type` discriminator |
| P2.6 | 图片附件模型 | `note_image_attachment.dart` | spec §2.8：id + dataBase64 + createdAt |
| P2.7 | 便签模型 | `sticky_note.dart` | spec §2.4：title/content/images/categoryId/isPinned/pinnedAt/createdAt/updatedAt |
| P2.8 | 摘要模型 | `note_summary.dart` | spec §2.9：total/pinnedCount/categoryCount |
| P2.9 | 各模型 `toJson`/`fromJson` | 同上 | spec §7：JSON 携带 schema 版本；sealed class 用 type 分发 |

### 任务（`lib/features/sticky_notes/data/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P2.10 | 配置 Repository | `data/sticky_notes_config_repository.dart` | key `module_sticky_notes_config`；默认分类首次写入 |
| P2.11 | 便签 Repository | `data/sticky_notes_repository.dart` | key `module_sticky_notes_notes`；列表整体存取 |

### 验收

- 模型 JSON 往返正确（含 `NoteBlock` sealed class 各子类 round-trip）。
- 单元测试：每个模型 + 2 个 Repository。

> **✅ P2 已完成**：8 个模型（note_sort_mode / note_category / sticky_notes_config / note_inline / note_block / note_image_attachment / sticky_note / note_summary）+ 2 个 Repository（sticky_notes_config_repository / sticky_notes_repository）+ 10 个测试文件（39 个用例）全部完成。`flutter analyze` 零报错；`flutter test` 全通过；覆盖率 95.9%（213/222 行，单文件最低 88.2%，均 ≥80%）。模型均含 `schemaVersion` 字段；`NoteBlock` sealed class 以 `type` discriminator 分发（未知 type 抛 ArgumentError）；`StickyNote.copyWith` 提供 `clearCategoryId` / `clearPinnedAt` 标志用于置空。全部文件位于 `modules/sticky_notes/` 内。可进入 P3。

---

## 3. P3 服务层（`lib/features/sticky_notes/services/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P3.1 | 查询/排序服务 | `note_query_service.dart` | spec §4.1：置顶置前 + 排序方式 + 分类筛选（纯函数） |
| P3.2 | 摘要服务 | `note_summary_service.dart` | spec §2.9：total/pinnedCount/categoryCount |
| P3.3 | 富文本解析/渲染服务 | `note_rich_text_parser.dart` | spec §2.5/§2.6：块模型 ↔ 文本、渲染分发（纯函数） |

### 验收

- 排序：置顶优先、置顶内部 pinnedAt 倒序、普通便签按排序方式、同键 createdAsc 兜底。
- 分类筛选正确；摘要聚合正确。
- 富文本解析/渲染各块类型分发正确。

> **✅ P3 已完成**：3 个服务（`note_query_service` / `note_summary_service` / `note_rich_text_parser`）+ 3 个服务测试全部完成，`flutter analyze` 零报错。排序：置顶恒在前 → 置顶内部按 `pinnedAt` 倒序 → 所选排序方式 → `createdAt` 升序兜底；筛选支持 `null`（不限）/ 分类 id / `noCategoryKey`（无分类）。解析服务提供 `visibleBlocks` / `toPlainText` / `styleForBlock` / `markerFor`。

---

## 4. P4 状态管理（`lib/features/sticky_notes/providers/`）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P4.1 | 配置 Controller | `sticky_notes_config_controller.dart` + `sticky_notes_config_provider.dart` | 分类管理、默认排序 |
| P4.2 | 便签列表 Controller | `sticky_notes_controller.dart` + `sticky_notes_provider.dart` | 增删改、置顶切换、分类筛选、排序、导入 |
| P4.3 | 摘要 Provider | `sticky_notes_summary_provider.dart` | 派生自 stickyNotesProvider |
| P4.4 | 服务 Provider | `note_query_service_provider.dart` 等 | 依赖注入 |

### 验收

- Controller 变更即持久化；Widget 通过 `ref.watch/read` 访问。
- 增删改、置顶/取消置顶逻辑正确（依赖 P3）。

> **✅ P4 已完成**：2 个 Repository Provider + 3 个服务 Provider + `sticky_notes_config_controller`/`sticky_notes_config_provider` + `sticky_notes_controller`/`sticky_notes_provider` + `note_summary_provider`（派生摘要）共 10 个文件 + 2 个控制器测试。`StickyNotesController` 含 `togglePin`（置顶记录 `pinnedAt`、取消时 `clearPinnedAt`）、`clearCategory`、`import`（按 id 合并、`updatedAt` 较新者为准）、`setCategoryFilter`。

---

## 5. P5 主页面 UI（对应 plan M2）

### 任务（`lib/features/sticky_notes/pages/` + `widgets/`）

| # | 任务 | 产出文件 |
|---|------|----------|
| P5.1 | 主页面 | `pages/sticky_notes_page.dart` |
| P5.2 | 便签卡片 | `widgets/note_card_widget.dart`（标题/分类/置顶/更新时间） |
| P5.3 | 分类筛选条 | `widgets/note_category_filter.dart` |
| P5.4 | 空状态 | `widgets/note_empty_view.dart` |
| P5.5 | 横竖屏布局 | 用底座 `ResponsiveBuilder` 包裹；竖屏单列、横屏两列网格 |

### 交互（spec §3.2）

- 点击卡片进详情/编辑；长按/右键上下文（编辑、删除、置顶/取消置顶）；删除确认 `AlertDialog`。

### 验收

- 竖屏/横屏均无溢出，切换正常。
- 触控与键鼠交互可用。

> **✅ P5 已完成**：`pages/sticky_notes_page.dart` + 3 个组件（`note_card_widget` / `note_category_filter` / `note_empty_view`）+ 7 个 widget 测试。竖屏单列列表；横屏两列（按行分块，行内卡片高度可变，未引入 masonry 依赖）；筛选条为 全部 / 各分类 / 无分类（`noCategoryKey`）；卡片为 `Card` + `AdaptiveListTile`（长按/右键菜单：编辑、置顶/取消置顶、删除）。

---

## 6. P6 详情/编辑页（对应 plan M2）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P6.1 | 详情/编辑页 | `pages/note_edit_page.dart` | spec §3.3 |
| P6.2 | 富文本编辑组件 | `widgets/note_rich_text_editor.dart` | 工具栏 + 块编辑 |
| P6.3 | 图片附件管理 | `widgets/note_image_attachments_editor.dart` | 添加/删除/缩略图/大图预览 |
| P6.4 | 分类选择 | 复用 `DropdownMenu` | spec §3.3 |
| P6.5 | 置顶开关 | 复用 `MD3Switch` | spec §3.3 |
| P6.6 | 校验 | — | 空标题拦截 |

### 验收

- 富文本工具栏可用；图片可增删预览；分类/置顶可设；空标题拦截。

> **✅ P6 已完成**：`pages/note_edit_page.dart` + `widgets/note_rich_text_editor.dart` + `widgets/note_image_attachments_editor.dart` + 6 个 widget 测试（并行任务产出，已由主会话复核并纳入全量验证）。富文本编辑器采用「块级统一样式」模型：工具栏作用于当前聚焦块，混合行内样式在编辑该块文本后折叠为统一样式（已写入类文档）；图片选择走底座 `filePickerProvider`，未新增依赖。

---

## 7. P7 设置页 UI（对应 plan M3）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P7.1 | 设置页 | `pages/sticky_notes_settings_page.dart` | spec §3.4 |
| P7.2 | 分类管理 | `widgets/note_category_manager.dart` | 增删改/排序 |
| P7.3 | 默认排序选择 | — | updatedDesc/createdDesc/titleAsc |

### 验收

- 设置页横竖屏正常；分类/排序可用。

> **✅ P7 已完成**：`pages/sticky_notes_settings_page.dart` + `widgets/note_category_manager.dart` + 5 个 widget 测试。分类管理支持增/删/改/拖拽排序（`ReorderableListView.onReorderItem`，Flutter 3.44 已弃用旧 `onReorder`），内置分类（`work`/`life`/`other`）不可删除；删除分类时同时调用 `deleteCategory` 与 `StickyNotesController.clearCategory`（spec §4.2）；排序选项用 `AdaptiveListTile` + 单选图标（避开 `Radio.groupValue` 弃用告警）。
>
> **✅ P3 ~ P7 全量验证**：`flutter analyze` 零报错；`flutter test` 106 个用例全通过；覆盖率 89.8%（964/1074 行，单文件最低 77.2%）。已接线 `sticky_notes_module.dart`（`buildPage` → `StickyNotesPage`、`buildSettingsPage` → `StickyNotesSettingsPage`、`summary` 按启动快照返回便签总数，并补齐 `buildDashboardWidgets`/`hasCustomEntryCard`/`buildEntryCard`）。下一步待 OWNER 确认后执行 P8 合并主线。

---

## 8. P7.5 正文重构（博客式富文本）

> 需求：正文改为博客式编辑——图片内联（非附件）、图文混排、选区级字号 / 字体颜色 / 加粗 / 斜体 / 下划线 / 删除线。
> 约束：不新增第三方依赖（ADR-SN-001 / 底座 M-011）。

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P7.5.1 | 行内样式扩展 | `models/note_inline.dart`：`underline` / `fontSizeKey` / `colorKey` + 语义常量类 + 值相等语义 | spec §2.6 |
| P7.5.2 | 图片块 | `models/note_block.dart`：`ImageBlock`（`type: image`） | spec §2.5 |
| P7.5.3 | 便签模型调整 | `models/sticky_note.dart`：移除 `images`，`fromJson` 迁移旧数据 | spec §2.4 / §4.3 |
| P7.5.4 | 行内 runs 引擎 | `services/note_inline_runs.dart`：`textOf` / `normalize` / `styleAtOffset` / `applyStyleToRange` / `replaceTextRange` | 纯函数 |
| P7.5.5 | 渲染管线扩展 | `services/note_rich_text_parser.dart`：`inlineStyleOf` / `buildTextSpan`，`visibleBlocks` 保留图片块 | spec §4.4 |
| P7.5.6 | 富文本控制器 | `widgets/rich_text_editing_controller.dart`：runs 真值源 + `buildTextSpan` + `applyStyle` + pendingStyle | ADR-SN-001 |
| P7.5.7 | 图片块组件 | `widgets/note_image_block.dart`（替代并删除 `note_image_attachments_editor.dart`） | spec §3.3 |
| P7.5.8 | 编辑器重写 | `widgets/note_rich_text_editor.dart`：选区级行内样式 + 插入图片 | spec §3.3 |
| P7.5.9 | 编辑页改造 | `pages/note_edit_page.dart`：移除独立图片区，注入 `onPickImages` | spec §3.3 |

### 验收

- 选中文本可独立设置加粗 / 斜体 / 下划线 / 删除线 / 字号 / 字体颜色；折叠光标作用于光标所在片段。
- 图片以图片块内联，与文本块上下混排，可删除。
- 旧便签的 `images` 数据自动迁移为正文末尾图片块。

> **✅ P7.5 已完成**：模型（`note_inline` / `note_block` / `sticky_note`）+ 新增 `services/note_inline_runs.dart`、`widgets/rich_text_editing_controller.dart`、`widgets/note_image_block.dart` + 重写 `widgets/note_rich_text_editor.dart` 与 `pages/note_edit_page.dart`，删除 `widgets/note_image_attachments_editor.dart`。`flutter analyze` 零报错；`flutter test` 149 个用例全通过；未新增任何第三方依赖（`pubspec.yaml` 未改动）。

---

## 9. P7.6 正文交互简化与样式选择器（字号 / 取色盘）

> 需求：① 删除块设定，默认一个便签对应一段内容；② 正文编辑区与页面背景区分；
> ③ 取消块类型（标题 / 列表 / 引用等随之不再支持）；④ 字号改为选择器（滑块 + 数值输入框）；
> ⑤ 字色改为常用色板取色盘。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.6.1 | 取消块类型 | `models/note_block.dart`：仅保留文本块 / 图片块，旧块类型读取时降级为文本块 |
| P7.6.2 | 行内样式改绝对量 | `models/note_inline.dart`：`fontSize`（double?，8~72）/ `colorValue`（int? ARGB） |
| P7.6.3 | 服务适配 | `services/note_inline_runs.dart`、`note_rich_text_parser.dart`：移除 `markerFor`，字号 / 颜色解析改为绝对值 |
| P7.6.4 | 样式选择器 | 新增 `widgets/note_text_style_panel.dart`：常用色板取色盘 + 字号对话框（滑块 + 数值输入） |
| P7.6.5 | 编辑器简化 | `widgets/note_rich_text_editor.dart`：移除块级入口与标记列，正文改为独立填充容器 |
| P7.6.6 | 图片预览视口 | `widgets/note_image_block.dart`：固定预览视口，避免小图时对话框塌缩为原始尺寸 |

### 验收

- 正文为一段连续图文，无「添加段落 / 块格式 / 删除本块」等块级入口；内容区以填充 + 描边与页面背景区分。
- 选中文本可通过取色盘设定颜色、通过滑块或数值输入框设定字号；「默认」可恢复继承主题。
- 旧数据（旧块类型正文、旧图片附件）可正常读取不报错。

> **✅ P7.6 已完成**：`note_block.dart` 仅保留 `ParagraphBlock` / `ImageBlock`（`legacyTypeNames` 兼容 heading/bullet/numbered/checkList/quote 并降级为文本块）；`note_inline.dart` 以 `fontSize` / `colorValue` 取代原语义 key；新增 `widgets/note_text_style_panel.dart`（Office 主题色板 10 基色 × 6 档取色盘 + 字号滑块/数值对话框）；编辑器移除块类型工具栏、标记列与全部块级入口，正文改为 `surfaceContainerLow` 填充 + `outlineVariant` 描边 + 12dp 圆角的独立容器；顺带修复图片预览对话框在小图时塌缩为原始尺寸（关闭按钮被裁切）的问题。`flutter analyze` 零报错；`flutter test` 137 个用例全通过；未新增第三方依赖。

---

## 10. P8 合并进主线（对应 plan M4 · 需 OWNER 确认）

> 触碰主线，必须在开发完成并经 OWNER 书面确认后进行。

| # | 任务 | 涉及文件（主线） |
|---|------|------------------|
| P8.1 | 主项目加 path 依赖 | 主项目 `pubspec.yaml`：`sticky_notes_module: { path: modules/sticky_notes }` |
| P8.2 | 注册模块 | 主线 `lib/core/modules/module_registry.dart`：新增 `'sticky_notes' => StickyNotesModule()` + import |
| P8.3 | 确认底座配置 | 主线 `lib/core/constants.dart`：`defaultModules` 是否已含 `sticky_notes`；`module_icon_mapper.dart` `notes` 图标（已确认存在） |
| P8.4 | 主线回归验证 | `flutter analyze` + `flutter test` + 运行验证 |

---

## 11. P9 清理临时应用（对应 plan M5）

删除（仅限模块内）：

- `lib/main.dart`
- `lib/debug/` 整个目录
- `windows/`（及 `.metadata` 独立运行配置）
- `pubspec.yaml` 中独立运行引入的额外依赖

保留：`lib/features/sticky_notes/`、`test/`、`docs/`、`pubspec.yaml`（含 path 依赖底座）。

主线回归验证。

---

## 12. P10 首页卡片与后续（对应 plan M6）

| # | 任务 | 依据 |
|---|------|------|
| P10.1 | 首页摘要卡片 | `ModuleContract.summary`（便签总数） |
| P10.2 | 自定义入口卡片（可选） | `buildEntryCard` / `hasCustomEntryCard` |
| P10.3 | 仪表盘额外卡片（可选） | `buildDashboardWidgets` |
| P10.4 | 与主线共同 debug | 横竖屏、同步联调 |
| P10.5 | 数据同步实现 | `StickyNotesModule.exportData` / `importData`：导出 `module_sticky_notes_config` 与 `module_sticky_notes_notes`（含图片 base64），整体替换 + id 合并（以 `updatedAt` 较新者为准），见 spec §5 / ADR-SN-003 |

---

## 13. 依赖与里程碑对照

| 开发阶段 | 对应 plan 里程碑 | 触碰主线 |
|----------|------------------|----------|
| P0 文档同步 | （前置） | 否 |
| P1 临时骨架 | M1 | 否 |
| P2 模型+存储 | M1/M2 | 否 |
| P3 服务层 | M1/M2 | 否 |
| P4 状态管理 | M2 | 否 |
| P5 主页面UI | M2 | 否 |
| P6 详情/编辑UI | M2 | 否 |
| P7 设置页UI | M3 | 否 |
| P7.5 正文重构（博客式富文本） | - | 否 |
| P7.6 正文简化与样式选择器 | - | 否 |
| P8 合并主线 | M4 | **是** |
| P9 清理临时应用 | M5 | 否 |
| P10 首页卡片 | M6 | 视实现 |

---

## 14. 引用文档

- [sticky_notes_spec.md](./sticky_notes_spec.md) v1.0（需求）
- [sticky_notes_plan.md](./sticky_notes_plan.md) v1.0（方案）
- [sticky_notes_design.md](./sticky_notes_design.md) v1.0
- [sticky_notes_coding_standards.md](./sticky_notes_coding_standards.md) v1.0（代码规范）