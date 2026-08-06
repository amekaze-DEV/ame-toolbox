# 倒班助手模块 — 任务清单

> **文档类型**: 子项目任务清单
> **模块 ID**: `shift_assistant`
> **版本**: v2.0
> **状态**: 进行中（按新需求重构）

---

## Phase 1: 环境就绪与多班组模型（已完成）

| 任务 | 内容 | 状态 |
|------|------|------|
| T1 | 创建 `modules/shift_assistant/` 目录结构与基础配置 | ✅ |
| T2 | 实现 `MemoryStorageService` | ✅ |
| T3 | 重构 `ShiftConfig` / `ShiftGroup` / `ShiftPattern` / `ShiftSlot` / `HolidayInfo` 模型 | ✅ |
| T4 | 更新 `ShiftConfigRepository` 适配新模型 | ✅ |
| T5 | 更新 `ShiftConfigController` / `shiftConfigProvider` | ✅ |
| T6 | 更新 `ShiftAssistantModule` 与 `ModuleContract` 实现 | ✅ |
| T7 | 更新 `ShiftAssistantPage` 骨架，使用 `AdaptiveListTile` | ✅ |
| T8 | 更新模型 / Repository / 模块单元测试 | ✅ |
| T9 | 更新模块文档（design / plan / spec / todo）v2.0 | ✅ |
| T10 | 运行 `flutter pub get` / `flutter analyze` / `flutter test` | ✅ |

## Phase 2: 排班计算与月历骨架（已完成）

| 任务 | 内容 | 状态 |
|------|------|------|
| T11 | 实现 `ShiftScheduleService` 日期 → 各班组班次计算 | ✅ |
| T12 | 实现 `DayInfo` 运行时聚合模型 | ✅ |
| T13 | 实现 `ShiftCalendarController` / `shiftCalendarProvider`（支持月切換） | ✅ |
| T14 | 搭建月历页面：按周分组，左侧班次标签 + 7 列日期 | ✅ |
| T15 | 处理窄宽度横向滚动与文本自适应缩放 | ✅ |
| T16 | 编写 Service / DayInfo / 日期计算单元测试 | ✅ |

## Phase 3: 月历布局与班组交互（已完成）

| 任务 | 内容 | 状态 |
|------|------|------|
| T17 | 月历按周分组渲染，每周块独立适配可用宽度 | ✅ |
| T18 | 窄宽度时启用横向滚动，文本使用 `FittedBox` 自适应 | ✅ |
| T19 | 主要班组所在单元格高亮显示 | ✅ |
| T20 | 实现班组拖拽排序（主要班组固定置顶） | ✅ |
| T21 | 实现班组长按/右键菜单：设为主要班组、编辑、删除 | ✅ |
| T22 | Widget 测试覆盖月历渲染、横向滚动、主要班组高亮 | ✅ |

## Phase 4: 节假日、农历与日期跳转（已完成）

| 任务 | 内容 | 状态 |
|------|------|------|
| T23 | 封装 `LunarInfoService`（基于 `lunar` 包） | ✅ |
| T24 | 实现 `HolidayDataService`：内置兜底 + 三源在线更新 + 归一化 | ✅ |
| T25 | 实现 `HolidayDataController` / `holidayDataProvider` | ✅ |
| T26 | 在月历日期行显示农历、节气、节假日标记 | ✅ |
| T27 | 实现日期选择器与“返回今天”，支持历史与未来跳转 | ✅ |
| T28 | 单元测试覆盖农历计算、节假日多源归一化、日期格式化 | ✅ |

## Phase 5: 首页仪表盘与设置页（已完成）

| 任务 | 内容 | 状态 |
|------|------|------|
| T29 | 实现 `ShiftDashboardController` / `shiftDashboardProvider` | ✅ |
| T30 | 首页仪表盘：当天日期/农历/节假日、班组班次卡片、主要班组高亮 | ✅ |
| T31 | 实现设置页：班组管理、轮班模式模板、主要班组设置 | ✅ |
| T32 | 实现节假日手动更新与数据源状态展示 | ✅ |
| T33 | Widget 测试覆盖仪表盘卡片、设置页表单 | ✅ |
| T34 | 验证 `exportData` / `importData` 往返一致 | ✅ |

### Phase 5 验证结果

- `flutter analyze`: 0 issues
- `flutter test`: 100 / 100 通过
- 行覆盖率: 83.68%（≥80% 达标）

## Phase 6: 提醒、统计与合并（未开始）

| 任务 | 内容 | 状态 |
|------|------|------|
| T35 | 实现提醒时间计算服务 | ⬜ |
| T36 | 集成底座通知服务注册/取消提醒 | ⬜ |
| T37 | 实现月度工时统计卡片 | ⬜ |
| T38 | 更新主项目 `pubspec.yaml` path 依赖 | ⬜ |
| T39 | 在主项目 `lib/main.dart` 注册模块 | ⬜ |
| T40 | 主项目 `flutter analyze` / `flutter test` 通过 | ⬜ |

---

## 进度

- 总体: 34 / 40（85%）
- 当前里程碑: M5 首页仪表盘与设置页 已完成
- 下一步: 进入 Phase 6（提醒、统计与合并）

### Phase 4 验证结果

- `flutter analyze`: 0 issues
- `flutter test`: 79 / 79 通过
- 行覆盖率: 86.04%（≥80% 达标）
