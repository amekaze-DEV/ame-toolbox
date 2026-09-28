# 便签模块 — 需求规格

> **文档类型**: 子项目需求规格
> **模块 ID**: `sticky_notes`
> **版本**: v1.0
> **状态**: 草案
> **约束基线**: `design.md` + `project_constraints.md`

---

## 1. 功能范围

### 1.1 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 便签管理 | 创建、查看、编辑、删除便签；标题（主要内容）+ 富文本正文 + 图片附件 | P0 |
| 置顶 | 便签可置顶固定，置顶便签始终排在普通便签之前 | P0 |
| 分类/标签 | 自定义分类，用于整理与筛选便签 | P0 |
| 富文本正文 | 正文支持段落、标题、有序/无序列表、待办清单、引用、粗体/斜体/删除线等轻量格式 | P0 |
| 图片附件 | 正文可插入多张图片，随便签数据一并存储与展示 | P0 |
| 首页仪表盘 | 首页展示便签数量摘要（总数 / 置顶数） | P1（合并入主线后开发） |
| 数据同步 | 实现 `exportData` / `importData` 满足 `ModuleContract` 契约，参与底座 WebDAV 同步 | P1（契约合规，非 P0） |

> **范围说明**：本模块**不包含**到期提醒（未选用）。数据同步作为 `ModuleContract` 契约要求实现 `exportData` / `importData`，但 WebDAV 实际接入与首页仪表盘均在**合并入主线后**展开。

### 1.2 非功能需求

- 模块独立运行启动时间 < 3 秒（开发环境）。
- 静态分析零报错。
- 单元测试覆盖率 ≥80%。
- 不引入 `dart:io` 到 `lib/features/` 与 `lib/shared/`。
- 离线可用：所有便签数据本地存储，不依赖网络。
- 富文本渲染与解析全部本地完成，不引入第三方富文本渲染依赖（避免在确认前新增依赖）。
- 正文图片以 base64 内嵌存储，随便签数据一并持久化。

---

## 2. 数据结构

### 2.1 模型清单

| 模型 | 职责 | 持久化 |
|------|------|--------|
| `StickyNotesConfig` | 模块级根配置：分类列表、默认排序方式 | 是（`module_sticky_notes_config`） |
| `NoteCategory` | 单个分类：名称、颜色、显示顺序 | 嵌入 `StickyNotesConfig` |
| `StickyNote` | 单个便签：标题、图文正文、分类、置顶、创建/更新时间 | 是（`module_sticky_notes_notes`） |
| `NoteBlock` | 正文块（sealed class）：文本块 / 图片块 | 嵌入 `StickyNote.content` |
| `ImageBlock` | 图片块：内联图片载荷，与文本块混排 | 嵌入 `StickyNote.content` |
| `NoteInline` | 行内元素：文本 + 加粗/斜体/下划线/删除线/绝对字号/自定义颜色 | 嵌入 `NoteBlock` |
| `NoteImageAttachment` | 图片载荷：base64 数据、创建时间 | 嵌入 `ImageBlock` |
| `NoteSummary` | 首页摘要聚合：总数、置顶数、分类数 | 不持久化，运行时聚合 |

### 2.2 StickyNotesConfig

```dart
class StickyNotesConfig {
  final List<NoteCategory> categories;   // 分类列表，按 displayOrder 排序
  final NoteSortMode defaultSortMode;    // 默认排序方式
}
```

- `categories`：分类列表，按 `displayOrder` 排序。
- 模块内置默认分类：工作（`work`）、生活（`life`）、其他（`other`），首次加载时写入。
- `defaultSortMode`：见 §2.7。

### 2.3 NoteCategory

```dart
class NoteCategory {
  final String id;
  final String name;
  final int colorValue;   // ARGB 整数值
  final int displayOrder;
}
```

- `id`：唯一标识，内置分类使用固定 id（`work` / `life` / `other`），自定义分类使用 `category_` 前缀。
- 分类删除时：该分类下的便签分类置为 null（无分类）。

### 2.4 StickyNote

```dart
class StickyNote {
  final String id;
  final String title;              // 标题（主要内容），必填
  final List<NoteBlock> content;   // 图文正文（图片为其中的 ImageBlock）
  final String? categoryId;        // 关联 NoteCategory.id，可为 null
  final bool isPinned;             // 是否置顶
  final DateTime? pinnedAt;        // 置顶时间（置顶排序用），非置顶为 null
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

- `title`：必填；空标题提交时拦截。
- `content`：图文正文，块列表（见 §2.5）；图片以 `ImageBlock` 内联其中。
- `isPinned = true` 时 `pinnedAt` 记录置顶时刻，用于置顶便签内部排序。

### 2.5 NoteBlock（富文本块，sealed class）

```dart
sealed class NoteBlock {
  final List<NoteInline> inlines;  // 行内元素（图片块恒为空）
}

/// 文本块（普通段落）
final class ParagraphBlock extends NoteBlock {}

/// 图片（图文混排）
final class ImageBlock extends NoteBlock {
  final NoteImageAttachment attachment;
}
```

- 正文不区分块类型（无标题/列表/引用等），由「文本块 + 图片块」按顺序组成，一个便签对应一段连续图文内容；`type` discriminator 保留用于反序列化与后续扩展。
- 空文本块在渲染时忽略；`ImageBlock` 无行内文本，渲染时恒可见。
- 兼容旧数据：取消块类型前写入的 `heading` / `bullet` / `numbered` / `checkList` / `quote` 在读取时统一降级为文本块并保留文本。

### 2.6 NoteInline

```dart
class NoteInline {
  final String text;          // 文本内容
  final bool bold;            // 粗体
  final bool italic;          // 斜体
  final bool underline;       // 下划线
  final bool strikethrough;   // 删除线
  final double? fontSize;     // 绝对字号（pt，8 ~ 72），null 为继承 textTheme
  final int? colorValue;      // 自定义颜色（ARGB 整数），null 为继承 colorScheme
  final String? link;         // 链接地址（可选）
}
```

- 行内样式通过布尔位与绝对字号 / 自定义色值表达，渲染时映射到 `TextSpan` 样式。一个文本块由若干 `NoteInline` 顺序拼接而成（runs 模型）。
- 字号为绝对 pt（选择器范围 8 ~ 72，滑块步长 1）；颜色取自常用色板（参考 Office 主题色板，10 基色 × 6 档明暗）。未自定义时分别继承 `textTheme` 基线字号与 `colorScheme` 前景色。

### 2.7 NoteSortMode

```dart
enum NoteSortMode {
  updatedDesc,   // 按更新时间倒序（默认）
  createdDesc,   // 按创建时间倒序
  titleAsc,      // 按标题字母序
}
```

- 置顶不受排序方式影响：置顶便签恒排在普通便签之前；置顶内部按 `pinnedAt` 倒序，再按所选排序方式。

### 2.8 NoteImageAttachment

```dart
class NoteImageAttachment {
  final String id;
  final String dataBase64;   // base64 编码的图片数据
  final DateTime createdAt;
}
```

- 作为 `ImageBlock` 的载荷内联于正文；以 base64 内嵌 JSON，随 `module_sticky_notes_notes` 一并存储。

### 2.9 NoteSummary（运行时聚合）

```dart
class NoteSummary {
  final int total;         // 便签总数
  final int pinnedCount;   // 置顶数
  final int categoryCount; // 分类数
}
```

---

## 3. UI 规格

### 3.1 首页仪表盘（Dashboard）

- 展示便签总数（如 `便签` / `12`）。
- 竖屏：摘要卡片单列；横屏：摘要卡片两列网格。
- **P1 阶段实现**：合并入主线后开发，临时应用阶段不实现。

### 3.2 便签主页面

#### 布局

- 顶部 AppBar：标题“便签” + 新增 `AdaptiveIconButton`。
- 分类筛选条：横向滚动的一排分类标签（全部 / 各分类），点击切换筛选。
- 便签列表：按排序方式 + 置顶规则排序展示。
  - 竖屏：单列列表。
  - 横屏：两列网格（复用/参照底座 Masonry 思路，便签卡片高度可变）。
- 空状态：无便签时展示 `Icons.sticky_note_2_outlined` + “暂无便签”提示文字。

#### 便签卡片

- 标题为主要内容；辅助信息行：分类色点/标签 + 置顶标识 + 更新时间。
- 置顶便签：前置 `Icons.push_pin` 图标标识，颜色使用 `colorScheme.primary`。
- 分类色点：使用该分类 `colorValue` 映射的圆点。

#### 交互

- 点击卡片：进入详情/编辑页。
- 长按/右键（键鼠模式）：上下文菜单（编辑、删除、置顶/取消置顶）。
- 删除：需确认对话框（`AlertDialog`）。
- 置顶/取消置顶：卡片快捷操作或上下文菜单。

### 3.3 详情/编辑页

- 展示与编辑：标题（必填）、图文正文（连续文本 + 内联图片）、分类选择、置顶开关。
- 正文编辑区为**独立的填充容器**（`surfaceContainerLow` 填充 + `outlineVariant` 描边 + 12dp 圆角），与页面背景区分；文本为无边框多行输入，图片块内联其间。
- 正文不设块类型，也不提供「添加段落 / 块格式 / 删除本块」等块级操作入口（回车即为换行）。
- 富文本工具栏：加粗、斜体、下划线、删除线（作用于**选区**）、字号选择器（滑块 + 数值输入框，8 ~ 72 pt）、字体颜色取色盘（常用色板 + 默认），以及「插入图片」（在当前块后插入图片块并补一个空文本块）。
- 保存按钮：`FilledButton`；取消/返回：`TextButton`。
- 空标题提交时提示错误，不允许保存。

### 3.4 设置页

- 分类管理：新增、编辑、删除、排序分类。
- 默认排序方式选择：更新时间 / 创建时间 / 标题。
- 模块提供 `buildSettingsPage` 实现上述设置。

### 3.5 主题与色彩

- 界面颜色默认取自 `Theme.of(context).colorScheme`；正文文字颜色为用户可自定义项（常用色板），未自定义时继承 `colorScheme`。
- 置顶标识使用 `colorScheme.primary`。
- 分类颜色：自定义分类从 `ColorScheme` 次要色板循环分配。
- 已删除分类的便签显示“无分类”（`onSurfaceVariant`）。
- 圆角遵循 MD3：小 4dp（标签/圆点）、中 12dp（卡片）、大 16dp（对话框容器）。

---

## 4. 业务规则

### 4.1 排序规则

- 置顶优先：置顶便签恒排在普通便签之前。
- 置顶内部：按 `pinnedAt` 倒序；再按所选排序方式。
- 普通便签：按 `NoteSortMode` 排序（默认更新时间倒序）。
- 同排序键：按 `createdAt` 升序兜底。

### 4.2 分类规则

- 便签可绑定一个分类（`categoryId`），可为 null（无分类）。
- 删除分类：该分类下便签 `categoryId` 置为 null。
- 分类排序：按 `displayOrder` 升序。

### 4.3 图片内联规则

- 图片为正文中的一个独立块（`ImageBlock`），与文本块按顺序上下混排，不作为独立附件区。
- 图片以 base64 内嵌，随正文顺序持久化与同步；删除块即删除图片，删除便签时一并移除。
- 每张图片限制尺寸/数量，避免数据量与 JSON 体积过大（设计阶段定具体阈值）。
- 兼容旧格式：读取到旧版 `StickyNote.images` 时自动迁移为正文末尾的图片块，再次保存后落为新格式。

### 4.4 富文本规则

- 正文为空时保存为默认空段落（渲染时显示空内容占位）。
- 富文本渲染用 Flutter 内置 `Text` / `RichText` 实现，不引入第三方富文本渲染包。
- 行内样式以**选区**为单位应用；无选区（折叠光标）时作用于光标所在片段；块内无文本时暂存样式供随后输入使用。
- 字号以绝对 pt 存储（选择器范围 8 ~ 72）；颜色以 ARGB 整数存储，取自常用色板。二者的「默认」表示继承 `textTheme` / `colorScheme`，因此主题切换时未自定义部分仍自适应。

---

## 5. 接口契约

模块实现 `ModuleContract`：

| 方法/属性 | 行为 |
|-----------|------|
| `definition` | id=`sticky_notes`, name=`便签`, icon=`notes` |
| `buildPage` | 返回 `StickyNotesPage`（分类筛选 + 便签列表） |
| `buildSettingsPage` | 返回 `StickyNotesSettingsPage`（分类管理、排序） |
| `summary` | 返回便签总数（如 label=`便签`, value=`12`） |
| `initialize(storage)` | 加载 `StickyNotesConfig` 与 `StickyNote` 列表 |
| `dispose()` | 释放 Controller |
| `exportData()` | 导出 `module_sticky_notes_config` 与 `module_sticky_notes_notes`（含图片 base64） |
| `importData(data)` | 导入并更新配置与便签，按 id 合并 |

---

## 6. 外部依赖与开源代码

| 来源 | 用途 | 许可 | 集成方式 |
|------|------|------|----------|
| 底座 `StorageService` | 数据持久化 | - | 通过 `initialize(storage)` 注入 |
| 底座 `ResponsiveBuilder` / `Adaptive*` | 布局与组件 | - | 模块内复用 |
| 自研 | 便签模型、富文本解析/渲染（含选区级行内样式）、分类、排序、图片内联 | - | 模块内部实现 |

- **不新增第三方依赖**（富文本、图片选择等均用 Flutter 内置能力实现）；如需新增依赖须经 OWNER 确认。

---

## 7. 参考

- [sticky_notes_design.md](./sticky_notes_design.md)
- [sticky_notes_coding_standards.md](./sticky_notes_coding_standards.md)