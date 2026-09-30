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
→ P5 主页面UI → P6 详情/编辑UI → P7 设置页UI → P7.5 正文重构（博客式富文本）→ P7.6 正文简化与样式选择器 → P7.7 查看/编辑分离 → P7.8 分类编辑对话框删除入口 → P7.9 分类删除放开与便签删除入口 → P7.10 关键字检索（索引） → P7.11 文件附件 → P8 合并主线 → P9 清理 → P10 首页卡片
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

## 10. P7.7 查看/编辑分离与样式作用范围修正

> 需求：① 格式调整不应修改已输入文本（仅影响后续输入，选中文本才改选区）；
> ② 正文框 UI 与标题一致、默认高度更大；③ 点击便签进入查看页，编辑入口在查看页；
> ④ 横屏在便签列表旁直接提供内容查看。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.7.1 | 后续输入样式 | `widgets/rich_text_editing_controller.dart`：折叠光标只设 `pendingStyle`，有选区才改选区 |
| P7.7.2 | runs 引擎支持插入模板 | `services/note_inline_runs.dart`：`TextDiff` + `replaceTextRange(insertedTemplate:)` |
| P7.7.3 | 正文框对齐标题 | `widgets/note_rich_text_editor.dart`：`InputDecorator` + `OutlineInputBorder`（`minHeight` 200） |
| P7.7.4 | 只读渲染 | 新增 `widgets/note_rich_text_viewer.dart`、`widgets/note_detail_view.dart` |
| P7.7.5 | 查看页 | 新增 `pages/note_detail_page.dart`（顶栏编辑入口，按 id 取最新数据） |
| P7.7.6 | 主页交互 | `pages/sticky_notes_page.dart`：竖屏点击进查看页；横屏列表 + 预览主从双栏 |
| P7.7.7 | 卡片元信息防溢出 | `widgets/note_card_widget.dart`：时间文本可收缩（窄卡片不再溢出） |

### 验收

- 折叠光标调整格式不改变已输入文本，后续输入继承该格式；选中文本调整格式仅影响选区。
- 正文框与标题同为 `OutlineInputBorder`，默认高度更大。
- 竖屏点击便签进入查看页，查看页可进入编辑页；横屏点击便签在右侧直接查看内容并提供编辑入口。

> **✅ P7.7 已完成**：`RichTextEditingController` 改为「有选区改选区、折叠光标只设后续输入格式（pendingStyle）」；`NoteInlineRuns` 新增 `TextDiff` 与 `insertedTemplate`；正文框改用 `InputDecorator` + `OutlineInputBorder`（`minHeight` 200，标签「正文」）；新增 `NoteRichTextViewer` / `NoteDetailView` / `NoteDetailPage`；主页竖屏点击进入查看页、横屏改为列表 + 预览主从双栏；顺带修复卡片元信息行在窄卡片下溢出（时间文本改为可收缩）。`flutter analyze` 零报错；`flutter test` 153 个用例全通过；覆盖率 96.6%；未新增第三方依赖。
>
> 测试说明：`LayoutController` 读取真实 `PlatformDispatcher`（测试环境固定 800x600），无法通过 `tester.view` 控制横竖屏，页面测试改用其公开断点 API 切换布局模式。
>
> **✅ P7.7 追加修正（焦点保持 / 行高随字号）**：
> ① `widgets/note_rich_text_editor.dart` 新增 `_requestFocus`：工具栏按钮按下后、字号/字色对话框关闭后，焦点交还当前正文框，调整格式后可继续输入，无需再次点击激活；
> ② 编辑器 `TextField` 显式关闭 strut（`strutStyle: StrutStyle.disabled`）：`EditableText` 默认用基础样式生成 `forceStrutHeight: true` 的固定行高，导致大字号文本与相邻行重叠；关闭后行高随每行实际字号变化，与只读视图一致。
> 新增回归测试 3 个（焦点保持 ×2、行高随字号 ×1），`flutter test` 156 个用例全通过。

---

## 11. P7.8 分类编辑对话框内删除入口

> 需求：在编辑分类对话框内直接提供删除按钮，无需回到列表行操作。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.8.1 | 对话框删除入口 | `widgets/note_category_manager.dart`：`_CategoryEditorDialog` 新增 `onDelete`；编辑自定义分类时在 actions 展示「删除」（`colorScheme.error`），内置分类不展示 |
| P7.8.2 | 删除流程复用 | `_confirmDelete` 返回是否已删除；确认后关闭编辑对话框，该分类下便签 `categoryId` 置 null |

### 验收

- 编辑自定义分类时对话框提供「删除」按钮，点击后弹出确认对话框；确认后分类删除、关联便签变为无分类、两个对话框均关闭。
- 内置分类（工作 / 生活 / 其他）的编辑对话框不展示删除入口（该限制已在 P7.9 放开，见 §12）。

> **✅ P7.8 已完成**：编辑分类对话框新增删除按钮（仅自定义分类），复用既有确认与置空流程；新增 2 个用例（删除入口显示规则、对话框内删除后分类移除且关联便签置空）。`flutter analyze` 零报错；`flutter test` 158 个用例全通过。

---

## 12. P7.9 分类删除放开与便签删除入口

> 需求：① 默认分类也应可删除；② 适配更多标签颜色；③ 编辑便签页顶栏新增删除按钮（新建便签页不出现）。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.9.1 | 默认分类可删除 | `widgets/note_category_manager.dart`：移除内置分类保护，列表行与编辑对话框对所有分类提供删除入口 |
| P7.9.2 | 空分类列表语义 | `models/sticky_notes_config.dart`：显式空分类列表不再回退默认分类（仅缺省字段回退） |
| P7.9.3 | 扩充色板 | `widgets/note_category_manager.dart`：候选颜色 6 → 18 色（Material 调色板，6 列排布，默认仍取首色） |
| P7.9.4 | 便签删除入口 | `pages/note_edit_page.dart`：编辑态顶栏「删除便签」按钮（确认后删除并返回便签列表），新建态隐藏 |

### 验收

- 默认分类（工作 / 生活 / 其他）在列表行与编辑对话框内均可删除；删除全部分类后重启不会恢复默认分类。
- 新增 / 编辑分类对话框提供 18 个候选颜色。
- 编辑便签页顶栏展示「删除便签」按钮，确认后便签被删除并返回便签列表；新建便签页不展示该按钮。

> **✅ P7.9 已完成**：分类管理器移除默认分类删除限制、候选色板扩至 18 色；`StickyNotesConfig.fromJson` 显式空列表不再回退默认分类；编辑便签页顶栏新增删除按钮（仅编辑态，确认后 `popUntil` 返回便签列表）。新增 3 个用例（18 色色板选用、编辑页删除按钮显示规则、编辑页删除流程），并调整 3 个既有用例断言；`flutter analyze` 零报错；`flutter test` 161 个用例全通过。

---


## 13. P7.10 便签关键字检索（索引）

> 需求：增加便签索引功能，可查找标题 / 正文 / 附件包含关键字的便签，支持模糊索引。
> 经确认：本次仅检索**标题 + 正文**（附件为内嵌图片，无可检索文本，暂不参与）；
> 模糊匹配为「子串优先 + 子序列兜底 + 打分排序 + 命中高亮」；入口为主页顶栏搜索按钮展开。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.10.1 | 检索服务 | 新增 `services/note_search_service.dart`：`normalizeKeyword` / `matchIndices` / `scoreOf` / `match` / `search`（纯函数，标题优先、子序列兜底） |
| P7.10.2 | 查询组合 | `services/note_query_service.dart`：新增 `search()`（分类筛选 + 排序兜底 + 相关度重排） |
| P7.10.3 | 命中高亮 | 新增 `widgets/highlighted_text.dart`：按命中下标切分段落并高亮；`widgets/note_card_widget.dart` 接入 `titleHighlight` / `bodyHighlight` |
| P7.10.4 | 检索交互 | `pages/sticky_notes_page.dart`：顶栏搜索按钮展开输入框（自动聚焦 / 清空 / 退出），输入即时过滤，空结果提示，横竖屏与分类筛选叠加 |

### 验收

- 顶栏搜索按钮展开输入框，输入即过滤列表；退出检索恢复完整列表与常规顶栏。
- 标题与正文均可命中；输入「工报」可模糊命中「工作汇报」；命中字符高亮。
- 标题命中排在正文命中之前；同分沿用置顶优先与默认排序。
- 与分类筛选叠加生效；无结果时提示「未找到匹配的便签」。

> **✅ P7.10 已完成**：新增 `NoteSearchService`（子串优先 + 子序列兜底 + 打分）与 `HighlightedText`；`NoteQueryService.search` 组合分类筛选与排序兜底；主页顶栏新增搜索入口（即时过滤 + 清空 + 退出，横竖屏一致）；卡片按命中下标高亮标题与正文。新增 4 个测试文件/分组共 33 个用例（检索服务 20、高亮组件 5、查询组合 5、页面交互 5，含原有用例调整）。`flutter analyze` 零报错；`flutter test` 194 个用例全通过；覆盖率 97.3%；未新增第三方依赖。

---


## 14. P7.11 文件附件（本地上传 / 打开 / 下载 / 同步）

> 需求：便签支持添加文件附件——① 从本地上传，单个 ≤ 15MB；② 上传后可查看（系统默认查看器）
> 或下载；③ 附件不暴露在系统文件资源管理器下；④ 合并主线后可经 WebDAV 同步。
> 经确认：附件为便签级文件（与正文内联图片区分）；不新增第三方依赖；不参与关键字检索。

| # | 任务 | 产出文件 |
|---|------|----------|
| P7.11.1 | 附件元数据模型 | `models/note_attachment.dart`：id / fileName / sizeBytes / mimeType / createdAt |
| P7.11.2 | 字节存储与写穿缓存 | `data/note_attachment_store.dart`：`module_sticky_notes_attachments_<id>` + `attachmentBytesCache` + `preload` |
| P7.11.3 | 附件编排服务 | `services/attachment_service.dart`：选择→15MB 校验→落库、打开（系统默认查看器）、下载（另存为）、删除 |
| P7.11.4 | 便签模型接入 | `models/sticky_note.dart`：`attachments` 字段（toJson/fromJson/copyWith） |
| P7.11.5 | 删除级联 | `providers/sticky_notes_controller.dart`：注入 `NoteAttachmentStore`，删除便签时清理其附件字节 |
| P7.11.6 | 共用附件列表组件 | `widgets/note_attachment_list.dart`：文件名 + 大小 + 打开 / 下载（/ 删除） |
| P7.11.7 | 编辑页附件区 | `pages/note_edit_page.dart`：添加 / 打开 / 下载 / 删除，超限提示；未保存离开清理新增附件字节 |
| P7.11.8 | 查看页附件区 | `widgets/note_detail_view.dart`：只读附件区（打开 / 下载） |
| P7.11.9 | 同步导出/导入 | `data/sync_snapshots.dart` + `sticky_notes_module.dart`：`initialize` 预载字节，`exportData` / `importData` 携带附件字节并按 id 合并 |

### 验收

- 编辑页可「添加附件」选取本地文件；超过 15MB 拒绝并提示「附件超过 15MB 上限，未添加」。
- 附件行展示文件名与大小；「打开」调用系统默认查看器，「下载」弹出另存为并提示保存路径。
- 查看页（含横屏预览）附件区只读，仅提供打开 / 下载。
- 附件字节存于模块存储 key，不出现在系统文件资源管理器的用户目录下。
- 删除便签级联清理附件字节；删除附件在保存后清理；未保存离开清理本次新增附件。
- `exportData` 含 `module_sticky_notes_attachments`（仅被引用附件），`importData` 按 id 合并并落库。

> **✅ P7.11 已完成**：新增 `NoteAttachment` / `NoteAttachmentStore`（写穿缓存 + `preload`）/
> `AttachmentService` / `NoteAttachmentList` / `sync_snapshots.dart`；`StickyNote` 增加 `attachments`；
> 控制器删除便签时级联清理字节；编辑页与查看页接入附件区；模块 `initialize` 预载附件字节，
> `exportData` / `importData` 携带附件字节并支持同一轮同步内一致。
> 新增测试 31 个用例（模型 3、附件服务与存储 12、编辑页 6、查看页 3、模块同步 7）；
> `flutter analyze` 零报错；`flutter test` 227 个用例全通过；覆盖率 96.8%；未新增第三方依赖。
> 遗留（P10.5 联调）：同步导入后已打开的模块页面需刷新内存状态。

---

## 15. P8 合并进主线（对应 plan M4 · 需 OWNER 确认）

> 触碰主线，必须在开发完成并经 OWNER 书面确认后进行。

| # | 任务 | 涉及文件（主线） |
|---|------|------------------|
| P8.1 | 主项目加 path 依赖 | 主项目 `pubspec.yaml`：`sticky_notes_module: { path: modules/sticky_notes }` |
| P8.2 | 注册模块 | 主线 `lib/core/modules/module_registry.dart`：新增 `'sticky_notes' => StickyNotesModule()` + import |
| P8.3 | 确认底座配置 | 主线 `lib/core/constants.dart`：`defaultModules` 是否已含 `sticky_notes`；`module_icon_mapper.dart` `notes` 图标（已确认存在） |
| P8.4 | 主线回归验证 | `flutter analyze` + `flutter test` + 运行验证 |
> **✅ P8 已完成（2026-09-29，OWNER 授权执行）**：
> - P8.1 主项目 `pubspec.yaml` 新增 `sticky_notes_module: { path: modules/sticky_notes }`（`flutter pub get` 通过）。
> - P8.2 主线 `module_registry.dart` 新增 import 与 `'sticky_notes' => StickyNotesModule()` 分支。
> - P8.3 `defaultModules` 的便签槽位 id 由 `'notes'` **校正为 `'sticky_notes'`**（原 id 与模块定义 id 不一致，注册表 switch 按 id 命中，必须对齐）；`iconName: 'notes'` 保持不变（`module_icon_mapper` 已有映射）。
> - 附带主线修正（合并必需）：`main.dart` 调整初始化顺序——**先 `module.initialize(storage)`，再 `syncService.load()`**；原顺序下启动同步可能在模块初始化前调用 `exportData()`，存在把默认 / 空数据当作本地数据上传、覆盖服务端数据的风险（该风险对所有模块成立）。模块侧同时增加「未初始化不导出」护栏。
> - P8.4 验证：主线 `flutter analyze lib` 仅 1 条既有 info（`home_page.dart` `onReorder` 弃用，与本次无关）、`flutter analyze test` 零问题、`flutter test` 11 用例全通过（含修正 1 条在 Windows 下不可能成立的底座断言：`file_launcher_service_test.dart` 改为只校验文件名清洗结果）；模块侧 `flutter analyze` 零报错、227 用例全通过。
> - 追加主线修正（2026-09-30，OWNER 指定）：`module_management_page.dart` 自带的图标 switch 改为复用 `ModuleIconMapper`（与首页 / 设置页 / 导航共用同一映射，5 个模块在「模块管理」页不再显示兜底图标）；新增 `test/shared/utils/module_icon_mapper_test.dart` 锁定「`defaultModules` 的 iconName 均已登记」不变式。底座 `flutter analyze lib` / `analyze test` 无新增问题、`flutter test` 14 用例全通过。

---

## 16. P9 清理临时应用（对应 plan M5）

删除（仅限模块内）：

- `lib/main.dart`
- `lib/debug/` 整个目录
- `windows/`（及 `.metadata` 独立运行配置）
- `pubspec.yaml` 中独立运行引入的额外依赖

保留：`lib/features/sticky_notes/`、`test/`、`docs/`、`pubspec.yaml`（含 path 依赖底座）。

主线回归验证。
> **✅ P9 已完成（2026-09-29）**：删除 `lib/main.dart`、`lib/debug/`（2 文件）、`windows/`（65 文件）与 `.metadata`；
> `pubspec.yaml` 描述由「临时独立调试应用」更新为「记录、分类、置顶与附件管理」（模块本身无独立运行专用依赖需移除，`ametoolbox` / `flutter_riverpod` / `intl` 均为业务所需）。
> 清理后 `lib/` 仅剩 `features/sticky_notes/`（47 个 dart 文件），结构与其他已合并模块（`shift_assistant`）一致；
> 模块侧 `flutter analyze` 零报错、`flutter test` 227 用例全通过（清理未影响测试，测试使用的是 `test/helpers/` 内的独立替身）。
> 备注：`shift_assistant` 模块仍保留其 `windows/` 与 `.metadata`（未随清理删除），属既有遗留，未在本次范围内处理。

---

## 17. P10 首页卡片与后续（对应 plan M6）

| # | 任务 | 依据 |
|---|------|------|
| P10.1 | 首页摘要卡片 | `ModuleContract.summary`（便签总数） |
| P10.2 | 自定义入口卡片（可选） | `buildEntryCard` / `hasCustomEntryCard` |
| P10.3 | 仪表盘额外卡片（可选） | `buildDashboardWidgets` |
| P10.4 | 与主线共同 debug | 横竖屏、同步联调 |
| P10.5 | 数据同步联调 | 主链路已在 P7.11 实现（`module_sticky_notes_config` / `_notes` / `_attachments`，按 id 合并，`updatedAt` 较新者为准，见 spec §5 / ADR-SN-003 / ADR-SN-008）；合并主线后需联调：同步导入后刷新已打开页面的内存状态、附件较大时的同步耗时与进度展示 |

---

## 18. 依赖与里程碑对照

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
| P7.7 查看/编辑分离与样式作用范围修正 | - | 否 |
| P7.8 ~ P7.10 分类删除放开 / 检索索引 | - | 否 |
| P7.11 文件附件 | - | 否 |
| P8 合并主线 | M4 | **是**（已完成） |
| P9 清理临时应用 | M5 | 否（已完成） |
| P10 首页卡片 | M6 | 视实现 |

---

## 19. 引用文档

- [sticky_notes_spec.md](./sticky_notes_spec.md) v1.0（需求）
- [sticky_notes_plan.md](./sticky_notes_plan.md) v1.0（方案）
- [sticky_notes_design.md](./sticky_notes_design.md) v1.0
- [sticky_notes_coding_standards.md](./sticky_notes_coding_standards.md) v1.0（代码规范）