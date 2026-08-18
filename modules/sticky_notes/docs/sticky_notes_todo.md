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
→ P5 主页面UI → P6 详情/编辑UI → P7 设置页UI → P8 合并主线 → P9 清理 → P10 首页卡片
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

---

## 7. P7 设置页 UI（对应 plan M3）

| # | 任务 | 产出文件 | 依据 |
|---|------|----------|------|
| P7.1 | 设置页 | `pages/sticky_notes_settings_page.dart` | spec §3.4 |
| P7.2 | 分类管理 | `widgets/note_category_manager.dart` | 增删改/排序 |
| P7.3 | 默认排序选择 | — | updatedDesc/createdDesc/titleAsc |

### 验收

- 设置页横竖屏正常；分类/排序可用。

---

## 8. P8 合并进主线（对应 plan M4 · 需 OWNER 确认）

> 触碰主线，必须在开发完成并经 OWNER 书面确认后进行。

| # | 任务 | 涉及文件（主线） |
|---|------|------------------|
| P8.1 | 主项目加 path 依赖 | 主项目 `pubspec.yaml`：`sticky_notes_module: { path: modules/sticky_notes }` |
| P8.2 | 注册模块 | 主线 `lib/core/modules/module_registry.dart`：新增 `'sticky_notes' => StickyNotesModule()` + import |
| P8.3 | 确认底座配置 | 主线 `lib/core/constants.dart`：`defaultModules` 是否已含 `sticky_notes`；`module_icon_mapper.dart` `notes` 图标（已确认存在） |
| P8.4 | 主线回归验证 | `flutter analyze` + `flutter test` + 运行验证 |

---

## 9. P9 清理临时应用（对应 plan M5）

删除（仅限模块内）：

- `lib/main.dart`
- `lib/debug/` 整个目录
- `windows/`（及 `.metadata` 独立运行配置）
- `pubspec.yaml` 中独立运行引入的额外依赖

保留：`lib/features/sticky_notes/`、`test/`、`docs/`、`pubspec.yaml`（含 path 依赖底座）。

主线回归验证。

---

## 10. P10 首页卡片与后续（对应 plan M6）

| # | 任务 | 依据 |
|---|------|------|
| P10.1 | 首页摘要卡片 | `ModuleContract.summary`（便签总数） |
| P10.2 | 自定义入口卡片（可选） | `buildEntryCard` / `hasCustomEntryCard` |
| P10.3 | 仪表盘额外卡片（可选） | `buildDashboardWidgets` |
| P10.4 | 与主线共同 debug | 横竖屏、同步联调 |
| P10.5 | 数据同步实现 | `StickyNotesModule.exportData` / `importData`：导出 `module_sticky_notes_config` 与 `module_sticky_notes_notes`（含图片 base64），整体替换 + id 合并（以 `updatedAt` 较新者为准），见 spec §5 / ADR-SN-003 |

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
| P6 详情/编辑UI | M2 | 否 |
| P7 设置页UI | M3 | 否 |
| P8 合并主线 | M4 | **是** |
| P9 清理临时应用 | M5 | 否 |
| P10 首页卡片 | M6 | 视实现 |

---

## 12. 引用文档

- [sticky_notes_spec.md](./sticky_notes_spec.md) v1.0（需求）
- [sticky_notes_plan.md](./sticky_notes_plan.md) v1.0（方案）
- [sticky_notes_design.md](./sticky_notes_design.md) v1.0
- [sticky_notes_coding_standards.md](./sticky_notes_coding_standards.md) v1.0（代码规范）