# 待办清单模块 — 需求规格

> **文档类型**: 子项目需求规格
> **模块 ID**: `todo_list`
> **版本**: v1.2
> **状态**: 草案（循环规则改用 sealed class + 计算引擎）
> **约束基线**: `design.md` + `project_constraints.md`

---

## 1. 功能范围

### 1.1 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 类日历主界面 | 主要页面上半部分为类日历界面，供快速选择日期查看当日待办 | P0 |
| 待办项管理 | 创建、查看、编辑、删除待办项；名称（主要内容）+ 详情（文本及图片附件）；主页面只显示名称，点击卡片进入查看/修改详情 | P0 |
| 优先级 | 5 级优先级：最高、高、中、一般、日常；通过颜色标识区分，列表按顺序显示 | P0 |
| 期限与循环 | 设定待办期限与循环类型（循环 / 不循环）；循环支持 14 种周期设定方式；可设起始时间，终止时间可选 | P0 |
| 待办历史 | 一次性事项达到期限或完成后列入待办历史，不再重启 | P1 |
| 到期提醒 | 对接底座 `NotificationService`，在期限前 N 分钟推送系统通知 | P1 |
| 首页仪表盘 | 首页展示未完成待办数量摘要 | P0 |
| 数据同步 | 实现 `exportData` / `importData`，利用底座 WebDAV 服务跨设备同步 | P0 |
| 数据导出 | 导出为可编辑文档（.md 等），或直接复制至剪贴板 | P1 |
| 分类（可选增强） | 自定义分类标签，辅助筛选与展示 | P2 |

### 1.2 非功能需求

- 模块独立运行启动时间 < 3 秒（开发环境）。
- 静态分析零报错。
- 单元测试覆盖率 ≥80%。
- 不引入 `dart:io` 到 `lib/features/` 与 `lib/shared/`。
- 离线可用：所有待办数据本地存储，不依赖网络。
- 提醒调度基于底座 `NotificationService`，不自行引入平台通知插件。
- 循环周期计算全部本地完成，不依赖网络。

---

## 2. 数据结构

### 2.1 模型清单

| 模型 | 职责 | 持久化 |
|------|------|--------|
| `TodoConfig` | 模块级根配置：分类列表、提醒开关、默认提醒提前分钟数 | 是 |
| `TodoCategory` | 单个分类：名称、颜色、显示顺序（可选增强） | 嵌入 `TodoConfig` |
| `TodoItem` | 单个待办项：名称、详情、图片附件、优先级、期限、循环规则、完成状态、历史状态 | 是（独立存储） |
| `TodoImageAttachment` | 待办详情图片附件：base64 数据、创建时间 | 嵌入 `TodoItem` |
| `RecurrenceRule` | 循环周期规则（14 种方式，以天为基本单位） | 嵌入 `TodoItem` |
| `TodoListSummary` | 首页摘要聚合：未完成数等 | 不持久化，运行时聚合 |

### 2.2 TodoConfig

```dart
class TodoConfig {
  final List<TodoCategory> categories;
  final bool remindEnabled;        // 到期提醒总开关，默认 true
  final int defaultRemindMinutes;  // 默认提前提醒分钟数，默认 30
}
```

- `categories`：分类列表，按 `displayOrder` 排序。
- 模块内置默认分类：工作（`work`）、生活（`life`）、其他（`other`），首次加载时写入。

### 2.3 TodoCategory

```dart
class TodoCategory {
  final String id;
  final String name;
  final int colorValue;   // ARGB 整数值
  final int displayOrder;
}
```

- `id`：唯一标识，内置分类使用固定 id（`work` / `life` / `other`），自定义分类使用 `category_` 前缀。
- 分类删除时：该分类下待办项的分类置为 null（无分类）。

### 2.4 TodoItem

```dart
class TodoItem {
  final String id;
  final String title;              // 名称（主要内容），主页面仅显示此项
  final String? details;           // 详情文本
  final List<TodoImageAttachment> images;  // 详情图片附件
  final String? categoryId;        // 关联 TodoCategory.id，可为 null（可选增强）
  final TodoPriority priority;     // 最高 / 高 / 中 / 一般 / 日常
  final DateTime? dueDate;         // 期限（一次性事项的到期日；循环事项由规则计算）
  final List<RecurrenceRule> recurrenceRules; // 循环规则列表；空列表表示一次性（不循环）
  final int? remindMinutes;        // 提前提醒分钟数，null 表示使用默认
  final bool isCompleted;
  final DateTime? completedAt;
  final bool isArchived;           // 是否已列入待办历史
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

- `title`：必填；`details` 与 `images` 为可选的详情内容。
- `dueDate`：只取日期部分，忽略时间。
- 一次性事项（`recurrenceRules.isEmpty`）：期限 `dueDate` 到期或完成后进入待办历史（`isArchived = true`），不再重启。
- 循环事项（`recurrenceRules` 非空）：每个规则独立计算命中日期，所有规则结果合并去重；按规则周期性自动建立实例；实例作为独立 `TodoItem` 存在。

### 2.5 TodoImageAttachment

```dart
class TodoImageAttachment {
  final String id;
  final String dataBase64;   // base64 编码的图片数据
  final DateTime createdAt;
}
```

- 图片随待办详情展示与编辑；存储方式（base64 内嵌 JSON 随 WebDAV 同步，或经底座文件能力存储）在设计阶段确认。

### 2.6 TodoPriority

```dart
enum TodoPriority {
  highest,   // 最高
  high,      // 高
  medium,    // 中
  normal,    // 一般
  daily,     // 日常
}
```

- 颜色标识：最高/高 = `error` 系，中 = `tertiary` 系，一般 = `onSurfaceVariant`，日常 = `secondary` 系（具体取值见 3.5 与设计文档）。

### 2.7 RecurrenceRule（循环周期规则）

#### 2.7.1 整体结构

```dart
/// 单个循环规则：包含日期计算策略与有效期。
/// 一个 TodoItem 可绑定多个 RecurrenceRule，所有规则独立计算后合并去重。
class RecurrenceRule {
  final RecurrencePattern pattern; // 14 种周期方式之一
  final DateTime startDate;        // 起始时间（必填）
  final DateTime? endDate;         // 终止时间（可空；空 = 自动无限循环）
}
```

- `pattern` 采用 **sealed class / tagged union** 表达，不同周期方式为独立子类，完全对应截图中的五级菜单层级。
- 每个子类包含 `interval`（截图中的 A，即"每 A 个单位"）以及对应层级的参数。
- JSON 序列化使用 `type` discriminator（如 `"type": "monthlyDay"`），便于前后兼容与 WebDAV 同步。

#### 2.7.2 菜单层级 → 数据模型映射

截图中的菜单层级与 `RecurrencePattern` 子类一一对应如下：

| 一级菜单 | 二级菜单 | 三级菜单 | 四级菜单 | 五级菜单 | 子类 |
|----------|----------|----------|----------|----------|------|
| 每A天 | 第B天 | — | — | — | `EveryXDaysPattern` |
| 每A周 | 第B天 | — | — | — | `WeeklyPattern` |
| 每A月 | 第B天 | — | — | — | `MonthlyDayPattern` |
| 每A月 | 第B周 | 第C天 | — | — | `MonthlyWeekDayPattern` |
| 每A季度 | 第B天 | — | — | — | `QuarterlyDayPattern` |
| 每A季度 | 第B月 | 第C天 | — | — | `QuarterlyMonthDayPattern` |
| 每A季度 | 第B月 | 第C周 | 第D天 | — | `QuarterlyMonthWeekDayPattern` |
| 每A年 | 第B天 | — | — | — | `YearlyDayPattern` |
| 每A年 | 第B月 | 第C天 | — | — | `YearlyMonthDayPattern` |
| 每A年 | 第B月 | 第C周 | 第D天 | — | `YearlyMonthWeekDayPattern` |
| 每A年 | 第B季度 | 第C天 | — | — | `YearlyQuarterDayPattern` |
| 每A年 | 第B季度 | 第C月 | 第D天 | — | `YearlyQuarterMonthDayPattern` |
| 每A年 | 第B季度 | 第C周 | 第D天 | — | `YearlyQuarterWeekDayPattern` |
| 每A年 | 第B季度 | 第C月 | 第D周 | 第E天 | `YearlyQuarterMonthWeekDayPattern` |

#### 2.7.3 循环周期策略（sealed class）

```dart
sealed class RecurrencePattern {}

// 1. 每A天 -> 第B天
final class EveryXDaysPattern extends RecurrencePattern {
  final int interval;      // A：每 A 天为一个周期（≥1）
  final Set<int> days;     // B：周期内第几天（1 ~ A，可多选）
}

// 2. 每A周 -> 第B天
final class WeeklyPattern extends RecurrencePattern {
  final int interval;      // A：每 A 周（≥1）
  final Set<int> weekdays; // B：周几（1=周一 ~ 7=周日，可多选）
}

// 3. 每A月 -> 第B天
final class MonthlyDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 个月（≥1）
  final Set<int> days;     // B：几号（1 ~ 31，可多选）
}

// 4. 每A月 -> 第B周 -> 第C天
final class MonthlyWeekDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 个月（≥1）
  final List<WeekDay> items; // B=week, C=weekday
}

// 5. 每A季度 -> 第B天
final class QuarterlyDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 个季度（≥1）
  final Set<int> days;     // B：季度内第几天（1 ~ 90+，可多选）
}

// 6. 每A季度 -> 第B月 -> 第C天
final class QuarterlyMonthDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 个季度（≥1）
  final List<MonthInQuarterDay> items; // B=monthInQuarter, C=day
}

// 7. 每A季度 -> 第B月 -> 第C周 -> 第D天
final class QuarterlyMonthWeekDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 个季度（≥1）
  final List<MonthInQuarterWeekDay> items; // B=monthInQuarter, C=week, D=weekday
}

// 8. 每A年 -> 第B天
final class YearlyDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final Set<int> days;     // B：年内第几天（1 ~ 366，可多选）
}

// 9. 每A年 -> 第B月 -> 第C天
final class YearlyMonthDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<MonthDay> items; // B=month, C=day
}

// 10. 每A年 -> 第B月 -> 第C周 -> 第D天
final class YearlyMonthWeekDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<MonthWeekDay> items; // B=month, C=week, D=weekday
}

// 11. 每A年 -> 第B季度 -> 第C天
final class YearlyQuarterDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<QuarterDay> items; // B=quarter, C=day
}

// 12. 每A年 -> 第B季度 -> 第C月 -> 第D天
final class YearlyQuarterMonthDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<YearQuarterMonthDay> items; // B=quarter, C=monthInQuarter, D=day
}

// 13. 每A年 -> 第B季度 -> 第C周 -> 第D天
final class YearlyQuarterWeekDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<QuarterWeekDay> items; // B=quarter, C=week, D=weekday
}

// 14. 每A年 -> 第B季度 -> 第C月 -> 第D周 -> 第E天
final class YearlyQuarterMonthWeekDayPattern extends RecurrencePattern {
  final int interval;      // A：每 A 年（≥1）
  final List<YearQuarterMonthWeekDay> items; // B=quarter, C=monthInQuarter, D=week, E=weekday
}
```

#### 2.7.4 值对象

```dart
/// 第几周 + 周几
final class WeekDay {
  final int week;      // 第几周（1 ~ 5）
  final int weekday;   // 周几（1=周一 ~ 7=周日）
}

/// 季度内第几个月 + 几号
final class MonthInQuarterDay {
  final int monthInQuarter; // 1 ~ 3
  final int day;            // 1 ~ 31
}

/// 季度内第几个月 + 第几周 + 周几
final class MonthInQuarterWeekDay {
  final int monthInQuarter; // 1 ~ 3
  final int week;           // 1 ~ 5
  final int weekday;        // 1 ~ 7
}

/// 第几个月 + 几号
final class MonthDay {
  final int month; // 1 ~ 12
  final int day;   // 1 ~ 31
}

/// 第几个月 + 第几周 + 周几
final class MonthWeekDay {
  final int month;   // 1 ~ 12
  final int week;    // 1 ~ 5
  final int weekday; // 1 ~ 7
}

/// 第几个季度 + 第几天
final class QuarterDay {
  final int quarter; // 1 ~ 4
  final int day;     // 1 ~ 90+
}

/// 第几个季度 + 第几个月 + 几号
final class YearQuarterMonthDay {
  final int quarter;        // 1 ~ 4
  final int monthInQuarter; // 1 ~ 3
  final int day;            // 1 ~ 31
}

/// 第几个季度 + 第几周 + 周几
final class QuarterWeekDay {
  final int quarter; // 1 ~ 4
  final int week;    // 1 ~ 5
  final int weekday; // 1 ~ 7
}

/// 第几个季度 + 第几个月 + 第几周 + 周几
final class YearQuarterMonthWeekDay {
  final int quarter;        // 1 ~ 4
  final int monthInQuarter; // 1 ~ 3
  final int week;           // 1 ~ 5
  final int weekday;        // 1 ~ 7
}
```

#### 2.7.5 多规则合并

```dart
/// 计算一个 TodoItem 在指定区间内的所有待办日期。
class TodoRecurrenceResolver {
  List<DateTime> resolve(TodoItem item, DateTime from, DateTime to) {
    if (item.recurrenceRules.isEmpty) {
      // 一次性事项
      return item.dueDate != null && _inRange(item.dueDate, from, to)
          ? [item.dueDate!]
          : [];
    }
    final allDates = <DateTime>{};
    for (final rule in item.recurrenceRules) {
      allDates.addAll(_calculator.generateDates(rule, from, to));
    }
    return allDates.toList()..sort();
  }
}
```

- 每个 `RecurrenceRule` 独立计算命中日期，最终合并去重并按日期升序排列。
- 多规则用于：例如"每周一"与"每月 15 号"同时生效。

#### 2.7.6 日期计算引擎

```dart
/// 根据 RecurrenceRule 在指定区间内计算命中日期。
class RecurrenceDateCalculator {
  List<DateTime> generateDates(RecurrenceRule rule, DateTime from, DateTime to) {
    return switch (rule.pattern) {
      EveryXDaysPattern p => _generateEveryXDays(rule, p, from, to),
      WeeklyPattern p => _generateWeekly(rule, p, from, to),
      MonthlyDayPattern p => _generateMonthlyDay(rule, p, from, to),
      MonthlyWeekDayPattern p => _generateMonthlyWeekDay(rule, p, from, to),
      QuarterlyDayPattern p => _generateQuarterlyDay(rule, p, from, to),
      QuarterlyMonthDayPattern p => _generateQuarterlyMonthDay(rule, p, from, to),
      QuarterlyMonthWeekDayPattern p => _generateQuarterlyMonthWeekDay(rule, p, from, to),
      YearlyDayPattern p => _generateYearlyDay(rule, p, from, to),
      YearlyMonthDayPattern p => _generateYearlyMonthDay(rule, p, from, to),
      YearlyMonthWeekDayPattern p => _generateYearlyMonthWeekDay(rule, p, from, to),
      YearlyQuarterDayPattern p => _generateYearlyQuarterDay(rule, p, from, to),
      YearlyQuarterMonthDayPattern p => _generateYearlyQuarterMonthDay(rule, p, from, to),
      YearlyQuarterWeekDayPattern p => _generateYearlyQuarterWeekDay(rule, p, from, to),
      YearlyQuarterMonthWeekDayPattern p => _generateYearlyQuarterMonthWeekDay(rule, p, from, to),
    };
  }
}
```

- 引擎与规则表达分离：新增周期方式只需新增 `RecurrencePattern` 子类并实现对应生成器。
- 日期生成采用"区间内按周期粒度遍历 + 命中判定"策略，避免一次性计算全部未来日期造成内存压力；判定函数为纯函数，便于单元测试。

### 2.8 TodoListSummary（运行时聚合）

```dart
class TodoListSummary {
  final int total;            // 全部待办数（不含历史）
  final int pendingCount;     // 未完成数
  final int todayCount;       // 今日待办数
  final int overdueCount;     // 已过期未完成数
}
```

---

## 3. UI 规格

### 3.1 首页仪表盘（Dashboard）

- 展示未完成待办数量（如 `待办事项` / `5`）。
- 竖屏：摘要卡片单列；横屏：摘要卡片两列网格。
- 卡片内容使用 `ModuleSummary` 或自定义入口卡片，展示摘要数据与快捷进入按钮。

### 3.2 主要页面（类日历 + 当日待办）

#### 布局

- 顶部 AppBar：标题“待办清单” + 新增按钮。
- **上半部分：类日历界面**（月视图）。
  - 展示当前月份，可左右翻月、点击“今天”返回当月。
  - 每日格子显示日期，有待办的日期以标记（圆点/底色）提示。
  - 点击某日期 → 选中该日，下方列表联动显示该日待办。
- **下半部分：所选日期的待办列表**。
  - 按优先级顺序显示当日待办项（排序规则见 4.1）。
  - 每个待办项以卡片形式展示，**仅显示名称**（以及优先级/期限等辅助标识）。
  - 点击卡片进入详情页查看或修改。

#### 待办卡片

- 名称为主要内容；辅助信息行：优先级颜色标识 + 期限/循环标识。
- 已完成项：名称使用 `onSurfaceVariant` 并加删除线。
- 已过期未完成项：期限文字使用 `error`。

#### 交互

- 点击卡片：进入详情页（查看/编辑）。
- 勾选/按钮切换完成状态（入口在卡片或详情页）。
- 长按/右键（键鼠模式）：上下文菜单（编辑、删除）。
- 删除：需确认对话框（`AlertDialog`）。

### 3.3 详情页（查看/修改）

- 展示与编辑：名称、详情文本、图片附件（添加/删除）、优先级、期限、循环规则、起止时间、提醒。
- 图片附件：支持添加多张图片，缩略图列表展示，点击查看大图，可删除。
- 保存按钮：`FilledButton`；取消/返回：`TextButton`。
- 空名称提交时提示错误，不允许保存。

### 3.4 新增/编辑表单与循环设定

- 字段：名称（必填）、详情文本、图片附件、优先级（5 级分段选择）、期限、循环类型（循环/不循环）、循环规则列表、起始时间、终止时间（可选）、提前提醒分钟数。
- **循环周期严格按截图五级菜单层级设定**：
  - 每个待办项可建立**多个循环规则**，所有规则共同生效、结果合并去重。
  - 单个规则的菜单层级如下：
    - 第一级：选择周期单位（每 A 天 / 每 A 周 / 每 A 月 / 每 A 季度 / 每 A 年），A 为间隔数量（≥1）。
    - 第二级及以下：按截图层级依次选择第 B 天/月/季度/周、第 C 天/周/月……最多五级（如“每A年 → 第B季度 → 第C月 → 第D周 → 第E天”）。
  - 每级参数均支持多选，形成多组命中日期。
- 选“不循环”：`recurrenceRules` 为空，仅需期限（到期或完成后入历史）。
- 选“循环”：`recurrenceRules` 至少一条；每条规则须设起始时间；终止时间可选（不设则自动无限循环）。

### 3.5 设置页

- 分类管理：新增、编辑、删除、排序分类（可选增强）。
- 提醒设置：全局提醒开关、默认提前分钟数。
- 导出：导出 .md 文档、复制至剪贴板入口。
- 模块提供 `buildSettingsPage` 实现上述设置。

### 3.6 主题与色彩

- 所有颜色来自 `Theme.of(context).colorScheme`。
- 优先级颜色标识：最高 = `error`，高 = `errorContainer`，中 = `tertiary`，一般 = `onSurfaceVariant`，日常 = `secondary`。
- 已过期未完成项：期限文字使用 `error`。
- 已完成项：名称使用 `onSurfaceVariant` + 删除线。
- 日历选中日期使用 `primaryContainer` 背景；当天使用 `primary` 边框/填充。
- 分类颜色：自定义分类取自 `ColorScheme` 次要色板循环分配。

---

## 4. 业务规则

### 4.1 优先级排序

- 默认显示顺序：最高 → 高 → 中 → 一般 → 日常（按枚举声明顺序）。
- 提供选项“日常事项置顶”：开启后日常（`daily`）优先级事项排在最前，其余仍按默认顺序。
- 同优先级事项：按创建时间升序；循环实例按到期日期升序。
- 列表按优先级顺序显示；已过期项在原优先级位置展示（仅颜色区分，不自动置顶）。

### 4.2 完成状态与待办历史

- 标记完成：`isCompleted = true`，`completedAt = now`。
- 一次性事项（`recurrenceRules.isEmpty`）：
  - 标记完成 → 进入待办历史（`isArchived = true`），不再重启。
  - 期限到期且未完成 → 进入待办历史。
- 循环事项（`recurrenceRules` 非空）：
  - 当前实例完成后，按 `recurrenceRules` 计算下一次命中日期并生成新实例；若未设置终止时间则无限循环。
  - 设置了终止时间且已超过终止时间 → 不再生成新实例，事项进入历史。
- 待办历史：历史中事项只读展示，可通过历史视图查看。

### 4.3 循环周期规则

#### 4.3.1 设计原则

- **规则表达与计算分离**：
  - `RecurrencePattern`（sealed class）仅描述“是什么规则”。
  - `RecurrenceDateCalculator` 负责把规则转换成具体日期序列。
  - 新增周期方式只需新增 `RecurrencePattern` 子类 + 一个生成器方法，无需修改已有模型。
- **完全对应截图菜单层级**：每个 `RecurrencePattern` 子类与截图中的一级~五级菜单一一对应，参数命名即菜单中的 A/B/C/D/E。
- **无 nullable 字段组合**：每个子类只包含自己需要的字段，类型即文档。
- **多规则共同生效**：一个 `TodoItem` 可绑定多条 `RecurrenceRule`，各自计算后合并去重。
- **JSON 兼容性**：序列化使用 `type` discriminator，WebDAV 同步时可直接识别规则类型。

#### 4.3.2 菜单层级 → 模型映射

详见 [§2.7.2](#272-菜单层级--数据模型映射)。核心对应关系：

- 一级菜单 = 周期单位（天/周/月/季度/年）+ `interval` A。
- 二级及以下菜单 = 该单位内的定位参数（B/C/D/E）。
- 周相关参数统一使用 **第几周（`week`）+ 周几（`weekday`）**，不再使用“第几个周几”。

#### 4.3.3 各周期单位规则说明

> 以下 `weekday` 取值 1=周一 … 7=周日。所有 `Set<int>` / `List<T>` 均支持多选。

**（1）天周期**

| 编号 | 菜单层级 | 子类 | 参数 | 示例 | 边界规则 |
|------|----------|------|------|------|----------|
| 4.3.1 | 每A天 → 第B天 | `EveryXDaysPattern` | `interval`: A（≥1）<br>`days`: B（1~A） | 每 4 天为周期的第 1、4 天 | `days` 取值必须在 1~A 之间 |

**（2）周周期**

| 编号 | 菜单层级 | 子类 | 参数 | 示例 | 边界规则 |
|------|----------|------|------|------|----------|
| 4.3.2 | 每A周 → 第B天 | `WeeklyPattern` | `interval`: A（≥1）<br>`weekdays`: B（1~7） | 每周周一、周四 | 无 |

**（3）月周期**

| 编号 | 菜单层级 | 子类 | 参数 | 示例 | 边界规则 |
|------|----------|------|------|------|----------|
| 4.3.3 | 每A月 → 第B天 | `MonthlyDayPattern` | `interval`: A（≥1）<br>`days`: B（1~31） | 每月 1、4、20 日 | 当月无该日则自动忽略 |
| 4.3.4 | 每A月 → 第B周 → 第C天 | `MonthlyWeekDayPattern` | `interval`: A（≥1）<br>`items`: `List<WeekDay>`<br>（B=week 1~5, C=weekday 1~7） | 每月第二周的周一 | 目标月不存在该周/周几则自动忽略 |

**（4）季度周期**

| 编号 | 菜单层级 | 子类 | 参数 | 示例 | 边界规则 |
|------|----------|------|------|------|----------|
| 4.3.5 | 每A季度 → 第B天 | `QuarterlyDayPattern` | `interval`: A（≥1）<br>`days`: B（1~90+） | 每季度第 15、90 天 | 超过本季度实际天数则自动忽略 |
| 4.3.6 | 每A季度 → 第B月 → 第C天 | `QuarterlyMonthDayPattern` | `interval`: A（≥1）<br>`items`: `List<MonthInQuarterDay>`<br>（B=monthInQuarter 1~3, C=day 1~31） | 每季度第一个月第 4 天、第三个月第 10 天 | 目标月无该日则自动忽略 |
| 4.3.7 | 每A季度 → 第B月 → 第C周 → 第D天 | `QuarterlyMonthWeekDayPattern` | `interval`: A（≥1）<br>`items`: `List<MonthInQuarterWeekDay>`<br>（B=monthInQuarter 1~3, C=week 1~5, D=weekday 1~7） | 每季度第一个月第二周的周一 | 目标月不存在该周/周几则自动忽略 |

**（5）年周期**

| 编号 | 菜单层级 | 子类 | 参数 | 示例 | 边界规则 |
|------|----------|------|------|------|----------|
| 4.3.8 | 每A年 → 第B天 | `YearlyDayPattern` | `interval`: A（≥1）<br>`days`: B（1~366） | 每年第 1、100 天 | 闰年 366 天外/平年 365 天外自动忽略 |
| 4.3.9 | 每A年 → 第B月 → 第C天 | `YearlyMonthDayPattern` | `interval`: A（≥1）<br>`items`: `List<MonthDay>`<br>（B=month 1~12, C=day 1~31） | 每年第二个月第 20 天、第六个月第 15 天 | 目标月无该日则自动忽略 |
| 4.3.10 | 每A年 → 第B月 → 第C周 → 第D天 | `YearlyMonthWeekDayPattern` | `interval`: A（≥1）<br>`items`: `List<MonthWeekDay>`<br>（B=month 1~12, C=week 1~5, D=weekday 1~7） | 每年第三个月第二周的第二天 | 目标月不存在该周/周几则自动忽略 |
| 4.3.11 | 每A年 → 第B季度 → 第C天 | `YearlyQuarterDayPattern` | `interval`: A（≥1）<br>`items`: `List<QuarterDay>`<br>（B=quarter 1~4, C=day 1~90+） | 每年第一个季度第 3 天、第四个季度第 50 天 | 超过目标季度实际天数则自动忽略 |
| 4.3.12 | 每A年 → 第B季度 → 第C月 → 第D天 | `YearlyQuarterMonthDayPattern` | `interval`: A（≥1）<br>`items`: `List<YearQuarterMonthDay>`<br>（B=quarter 1~4, C=monthInQuarter 1~3, D=day 1~31） | 每年第一个季度第二个月第 4 天、第三个季度第一个月第 20 天 | 目标月无该日则自动忽略 |
| 4.3.13 | 每A年 → 第B季度 → 第C周 → 第D天 | `YearlyQuarterWeekDayPattern` | `interval`: A（≥1）<br>`items`: `List<QuarterWeekDay>`<br>（B=quarter 1~4, C=week 1~5, D=weekday 1~7） | 每年第一个季度第二周的周一 | 目标季度内不存在该周/周几则自动忽略 |
| 4.3.14 | 每A年 → 第B季度 → 第C月 → 第D周 → 第E天 | `YearlyQuarterMonthWeekDayPattern` | `interval`: A（≥1）<br>`items`: `List<YearQuarterMonthWeekDay>`<br>（B=quarter 1~4, C=monthInQuarter 1~3, D=week 1~5, E=weekday 1~7） | 每年第二个季度第三个月第一周的周一 | 目标月不存在该周/周几则自动忽略 |

#### 4.3.4 统一边界规则汇总

- **月日越界**：目标月份没有设定日期（如 2 月 30 日、4 月 31 日）→ 该设定自动忽略。
- **季度天数越界**：设定的季度内第几天超过该季度实际天数 → 自动忽略。
- **年天数越界**：`YearlyDayPattern` 中设定天数超过当年实际天数（闰年 366、平年 365）→ 自动忽略。
- **周-周几越界**：设定的“第 N 周 + 周几”在目标月份/季度内不存在 → 自动忽略。

#### 4.3.5 多规则合并

- 一个 `TodoItem` 可包含多条 `RecurrenceRule`；各规则独立调用 `RecurrenceDateCalculator` 计算命中日期。
- 所有命中日期合并后去重，按日期升序排列，作为该待办项的完整待办日期序列。
- 多规则场景示例：规则 1 = 每周一；规则 2 = 每月 15 号；合并后即为每周一 + 每月 15 号。

#### 4.3.6 日期生成策略

- `RecurrenceDateCalculator.generateDates(rule, from, to)` 在指定闭区间内返回所有命中日期。
- 生成策略：按目标周期粒度遍历区间内的候选日期，对每个候选日期调用对应生成器的命中判定函数。
  - 天/周周期：逐日遍历。
  - 月周期：逐月遍历，在该月内按规则判定具体日期。
  - 季度/年周期：逐季度/逐年遍历，再向下分解到具体日期。
- 返回结果按日期升序去重；若规则产生多个相同日期（多选导致），去重后只保留一个实例。
- 所有判定函数为纯函数，输入（日期 + 规则）→ 输出（是否命中），便于单元测试。

### 4.4 循环实例生成

- 循环事项依据 `recurrenceRules` 自动建立实例：先合并所有规则的命中日期，再为每个命中日期生成独立 `TodoItem` 实例。
- 实例生成后作为独立待办项存在，可单独完成、编辑或删除；对实例的完成/删除不影响规则本身。
- 当前实例完成后，在合并后的日期序列中查找距当前日期最近的下一个命中日并生成新实例。
- 未设置终止时间：无限循环；设置终止时间：超过终止时间不再生成。
- 模块启动/初始化时扫描 `recurrenceRules`，补齐缺失的已到期未处理实例（仅生成距“最近一次已生成实例”之后的实例，避免重复生成历史堆积）。

### 4.5 到期提醒

- 仅在 `TodoConfig.remindEnabled` 为 true 且待办设置了期限/循环规则时调度提醒。
- 提醒时间 = 到期日 00:00 − 提醒分钟数：
  - 一次性事项：按 `dueDate` 计算。
  - 循环事项：按合并后日期序列中的下一最近命中日计算。
- 通过底座 `NotificationService.schedule(id, title, body, scheduledTime)` 调度，`cancel(id)` 取消。
- 通知 id 约定：`module_todo_list_item_<itemId>`。
- 重调度时机：新增/编辑（期限、提醒、或 `recurrenceRules` 变更）、完成、取消完成、删除、提醒开关变更。

### 4.6 数据导出

- 导出为 Markdown（.md）格式的可编辑文档，内容结构示例：

```markdown
# 待办清单

## 进行中
- [ ] 待办名称（最高｜2026-08-11 截止）
- [ ] 另一个待办（日常，循环：每周一）

## 已完成
- [x] 已完成事项（2026-08-10）
```

- 支持“复制至剪贴板”直接复制上述文本。
- 导出文件能力若超出底座 `StorageService` 现有接口（需写入磁盘文件），视为底座变更，须经 OWNER 确认后扩展。

---

## 5. 接口契约

模块实现 `ModuleContract`：

| 方法/属性 | 行为 |
|-----------|------|
| `definition` | id=`todo_list`, name=`待办清单`, icon=`todo` |
| `buildPage` | 返回 `TodoListPage`（类日历 + 当日待办） |
| `buildSettingsPage` | 返回 `TodoListSettingsPage`（分类、提醒、导出） |
| `summary` | 返回未完成待办数（如 label=`待办事项`, value=`5`） |
| `initialize(storage)` | 加载 `TodoConfig` 与 `TodoItem` 列表；补齐循环实例；初始化提醒调度 |
| `dispose()` | 释放 Controller；取消本模块全部待调度提醒（可选，取决于底座策略） |
| `exportData()` | 导出 `module_todo_list_config` 与 `module_todo_list_items`（含图片附件 base64） |
| `importData(data)` | 导入并更新配置与待办项，按 id 合并 |

---

## 6. 外部依赖与开源代码

| 来源 | 用途 | 许可 | 集成方式 |
|------|------|------|----------|
| `intl` | 日期格式化（中文） | BSD-3 | pub 依赖 |
| 底座 `NotificationService` | 到期提醒调度 | - | 通过底座 Provider 注入 |
| 底座 `StorageService` | 数据持久化 | - | 通过 `initialize(storage)` 注入 |
| 自研 | 待办模型、日历界面、循环计算、优先级排序、详情图片、导出 | - | 模块内部实现 |

---

## 7. 参考

- [todo_list_design.md](./todo_list_design.md)
- [todo_list_coding_standards.md](./todo_list_coding_standards.md)
