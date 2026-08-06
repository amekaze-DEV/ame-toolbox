# 倒班助手模块 — 需求规格

> **文档类型**: 子项目需求规格
> **模块 ID**: `shift_assistant`
> **版本**: v2.0
> **状态**: 草案（按新需求重构）
> **约束基线**: `design.md` + `project_constraints.md`

---

## 1. 功能范围

### 1.1 核心功能

| 功能 | 描述 | 优先级 |
|------|------|--------|
| 多班组管理 | 支持管理复数个班组；每个班组引用一个轮班模式，可独立设置基准日期与颜色 | P0 |
| 主要班组 | 可设置或不设置主要班组；设置后主要班组在仪表盘与月历中置顶并视觉高亮 | P0 |
| 轮班模式模板 | 内置 3–6 班制常见模板（三班两运转、四班两运转、四班三运转、五班三运转、六班三运转等），支持自定义 | P0 |
| 月历视图 | 以月历为基础展示整月排班；每周块左侧为班次标签，右侧 7 列为周一至周日；班组顺序可拖动调整 | P0 |
| 窄宽度适配 | 窗口宽度不足时，每周块整体横向滚动，班次标签与日期列同步滚动；班组名称自动缩放 | P0 |
| 国家节假日 | 展示国家法定节假日、调休上班日；调休信息通过公开源自动更新 | P0 |
| 农历日期 | 展示农历日期、节气、干支、生肖；本地计算，不依赖网络 | P0 |
| 日期查询跳转 | 支持历史与未来日期查询、快速跳转至指定日期、返回今天 | P0 |
| 首页仪表盘 | 展示当天排班情况；主要班组显示在最前方并高亮 | P0 |
| 班次提醒 | 在班次开始前 N 分钟推送提醒 | P1 |
| 工时统计 | 按周/月统计工作时长与休息天数 | P1 |

### 1.2 非功能需求

- 模块独立运行启动时间 < 3 秒（开发环境）。
- 静态分析零报错。
- 单元测试覆盖率 ≥80%。
- 不引入 `dart:io` 到 `lib/features/` 与 `lib/shared/`。
- 离线可用：节假日数据本地兜底 + 缓存。
- 多源降级：三个公开在线源按顺序备份，任一源成功即可。
- 每次打开 APP 时触发节假日数据更新检查。

---

## 2. 数据结构

### 2.1 模型清单

| 模型 | 职责 | 持久化 |
|------|------|--------|
| `ShiftConfig` | 模块级根配置：班组列表、轮班模式列表、主要班组 ID、节假日缓存、最后更新时间 | 是 |
| `ShiftGroup` | 单个班组：名称、颜色、引用的轮班模式 ID、基准日期、显示顺序、是否主要班组 | 嵌入 `ShiftConfig` |
| `ShiftPattern` | 轮班模式：名称、周期天数、班次列表 | 嵌入 `ShiftConfig` |
| `ShiftSlot` | 单个班次：名称、起止时间、是否休息 | 嵌入 `ShiftPattern` |
| `HolidayInfo` | 单天节假日信息：名称、是否法定假日、是否调休上班 | 嵌入 `ShiftConfig` |
| `DayInfo` | 某日期聚合信息：公历、农历、节气、节假日、各班组班次 | 不持久化，运行时聚合 |

### 2.2 ShiftConfig

```dart
class ShiftConfig {
  final List<ShiftGroup> groups;
  final List<ShiftPattern> patterns;
  final String? primaryGroupId;
  final Map<String, HolidayInfo> holidayCache;
  final DateTime? holidaysLastUpdated;
}
```

- `groups`：班组列表，无序；渲染顺序由 `orderedGroups` 计算。
- `patterns`：轮班模式列表，可被多个班组引用。
- `primaryGroupId`：主要班组 ID；为 null 时不设置主要班组。
- `holidayCache`：key 为 `yyyy-MM-dd`，value 为当日节假日信息。
- `holidaysLastUpdated`：节假日数据最后成功更新时间。

### 2.3 ShiftGroup

```dart
class ShiftGroup {
  final String id;
  final String name;
  final int colorValue;
  final String patternId;
  final DateTime baseDate;
  final int displayOrder;
  final bool isPrimary;
}
```

- `id`：班组唯一标识，使用 UUID 或 `group_` 前缀。
- `colorValue`：ARGB 整数值，UI 层通过 `Color(colorValue)` 使用。
- `displayOrder`：普通班组显示顺序；主要班组不受此字段影响，渲染时强制置顶。
- `isPrimary`：是否为主要班组；与 `ShiftConfig.primaryGroupId` 保持一致。

### 2.4 ShiftPattern

```dart
class ShiftPattern {
  final String id;
  final String name;
  final int cycleDays;
  final List<ShiftSlot> slots;
}
```

- `cycleDays`：周期天数，必须等于 `slots.length`。
- `slots`：周期内班次列表，按顺序对应周期第 0 天到第 `cycleDays-1` 天。

### 2.5 ShiftSlot

```dart
class ShiftSlot {
  final String name;
  final String? startTime; // HH:mm
  final String? endTime;   // HH:mm
  final bool isRest;
}
```

- `startTime` / `endTime`：格式 `HH:mm`；休息班次可为 null。
- 跨夜班（如 20:00–08:00）按次日处理，日期边界以 00:00 为准。

### 2.6 HolidayInfo

```dart
class HolidayInfo {
  final String name;
  final bool isHoliday;
  final bool isWorkday;
}
```

- `isHoliday`：法定节假日/休息日。
- `isWorkday`：调休上班日。
- 两者可同时为 false（普通周末或工作日）。

### 2.7 DayInfo（运行时聚合）

```dart
class DayInfo {
  final DateTime date;
  final String lunarDate;
  final String? solarTerm;
  final HolidayInfo? holiday;
  final Map<String, ShiftSlot> groupShifts; // groupId -> slot
}
```

---

## 3. UI 规格

### 3.1 首页仪表盘（Dashboard）

#### 竖屏

- 顶部：当前日期、农历、节气、节假日（如有）。
- 中部：当天所有班组班次卡片，主要班组置顶并使用 `primaryContainer` 背景 + 左侧强调条。
- 底部：本周排班缩略入口、设置入口。

#### 横屏

- 左侧：当天详情与主要班组大卡片（占 40%）。
- 右侧：本周 7 天排班缩略网格（占 60%）。

#### 卡片规格

- 普通班组卡片：背景 `surfaceContainerHighest`，内边距 16dp。
- 主要班组卡片：背景 `primaryContainer`，左侧 4dp 强调条颜色为班组色。
- 休息班次文字使用 `onSurfaceVariant` 低对比度。
- 所有文字使用 MD3 排版层级，不硬编码字号。

### 3.2 月历页面（Month Calendar）

#### 布局

- 顶部：年月标题居中，左右翻月图标按钮，“今天”文字按钮；极窄宽度时标题区横向滚动。
- 星期行：周一 ~ 周日 7 列 + 左侧班次标签占位，与下方每周块列宽对齐。
- 周块：左侧班次标签列（白班/夜班/休息等），右侧 7×N 日期网格。
- 每个单元格：顶部日期数字，下方按班次行显示承担该班次的班组名称。

#### 响应式

- 窗口宽度充足时：每周块占满可用宽度，7 列等分剩余空间。
- 窗口宽度不足时：每周块整体横向滚动，最小单元格宽度固定，避免文字压扁或旋转。

#### 交互

- 点击日期：选中该日期，仪表盘同步跳转。
- 长按/右键班次/班组：弹出菜单（设为主要班组、编辑、删除）。
- 拖拽班组顺序：调整普通班组显示顺序；主要班组固定置顶。

### 3.3 日期跳转

- 顶部 AppBar 提供日期选择器入口。
- 支持年份/月份快速选择，跳转后自动切换到目标日期所在月并选中该日期。
- 提供“返回今天”快捷按钮。

### 3.4 设置页

- 班组管理：添加、编辑、删除班组；设置主要班组；调整顺序。
- 轮班模式管理：选择模板、自定义周期、班次增删改。
- 节假日：手动更新按钮、最后更新时间、数据源状态。
- 提醒：开关、提前分钟数。

### 3.5 主题与色彩

- 所有颜色来自 `Theme.of(context).colorScheme`。
- 班组颜色循环使用 `ColorScheme` 次要色板；用户可覆盖。
- 节假日/调休文字使用 `error` 或 `tertiary`。
- 当前日期高亮使用 `primaryContainer`。

---

## 4. 业务规则

### 4.1 排班计算

- 对任意班组 `g` 与日期 `d`：
  - `offset = d.difference(g.baseDate).inDays`。
  - `index = offset % pattern.cycleDays`（处理负数取模）。
  - 返回 `pattern.slots[index]`。
- 周期天数必须大于 0 且等于 `slots.length`。
- 基准日期只取日期部分，忽略时间。

### 4.2 主要班组置顶

- 渲染时：`orderedGroups = [primaryGroup, ...otherGroups sortedBy displayOrder]`。
- 设置主要班组时：原主要班组 `isPrimary` 自动取消，新主要班组 `isPrimary` 设为 true，`primaryGroupId` 更新。
- 取消主要班组时：`primaryGroupId` 置 null，所有班组 `isPrimary` 置 false。

### 4.3 班组顺序调整

- 普通班组通过 `displayOrder` 排序。
- 拖拽只影响普通班组相对顺序，主要班组位置不变。
- 新增班组时 `displayOrder = max(displayOrder) + 1`。

### 4.4 节假日更新

- 启动时检查：若本地无数据或最后更新超过 24 小时，触发更新。
- 数据源优先级：
  1. NateScarlet/holiday-cn（GitHub 静态 JSON）
  2. cg-zhou/holiday-calendar（GitHub 静态 JSON）
  3. Chinese Days（公开 API/JSON）
- 任一源成功即停止，失败则降级到下一个源。
- 全部失败时使用本地缓存；无缓存时使用内置近三年兜底数据。
- 数据格式归一化：`HolidayDataService` 负责将不同源格式转换为 `HolidayInfo`。

---

## 5. 接口契约

模块实现 `ModuleContract`：

| 方法/属性 | 行为 |
|-----------|------|
| `definition` | id=`shift_assistant`, name=`倒班助手`, icon=`calendar_month` |
| `buildPage` | 返回 `ShiftAssistantPage`（月历/仪表盘入口） |
| `buildSettingsPage` | 返回 `ShiftAssistantSettingsPage` |
| `summary` | 返回主要班组名称；未设置时返回第一个班组名称；无班组时返回 `-` |
| `initialize(storage)` | 加载 `ShiftConfig`；触发节假日更新检查 |
| `dispose()` | 释放 Controller |
| `exportData()` | 导出 `module_shift_assistant_config` |
| `importData(data)` | 导入并更新配置，兼容旧版单班组数据迁移 |

---

## 6. 外部依赖与开源代码

| 来源 | 用途 | 许可 | 集成方式 |
|------|------|------|----------|
| `lunar` | 农历、节气、干支、生肖 | MIT | pub 依赖，封装为 `LunarInfoService` |
| `intl` | 日期格式化 | BSD-3 | pub 依赖 |
| `holiday-cn` (NateScarlet) | 中国节假日/调休在线数据 | MIT | HTTP 拉取静态 JSON，离线缓存 |
| `holiday-calendar` (cg-zhou) | 中国节假日/调休在线数据备用源 | MIT | HTTP 拉取静态 JSON，离线缓存 |
| `Chinese Days` | 中国节假日/调休在线数据备用源 | 公开数据 | HTTP 拉取静态 JSON，离线缓存 |

---

## 7. 参考

- [shift_assistant_design.md](./shift_assistant_design.md)
- [shift_assistant_plan.md](./shift_assistant_plan.md)
- [shift_assistant_todo.md](./shift_assistant_todo.md)
