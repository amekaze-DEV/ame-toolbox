# 倒班助手模块 — 开发计划

> **文档类型**: 子项目开发计划
> **模块 ID**: `shift_assistant`
> **版本**: v2.0
> **状态**: 草案（按新需求重构）

---

## 1. 目标

为 AMEToolbox 提供一个独立开发、独立测试的倒班助手模块，支持多班组管理、月历视图、节假日/农历展示、窄宽度横向滚动自适应，完成后合并到主项目。

---

## 2. 里程碑

### M1: 环境就绪与多班组模型（已完成 / 进行中）

- [x] 创建 `modules/shift_assistant/` 子项目目录结构
- [x] 配置 `pubspec.yaml` 与 `analysis_options.yaml`
- [x] 实现独立运行入口 `lib/main.dart`
- [x] 实现 `MemoryStorageService`
- [x] 实现 `ShiftAssistantModule` 与 `ModuleContract`
- [x] 重构数据模型：`ShiftConfig` / `ShiftGroup` / `ShiftPattern` / `ShiftSlot` / `HolidayInfo`
- [x] 更新 Repository / Controller / Page / 单元测试，适配新模型
- [x] 创建 Windows 桌面运行平台目录
- [x] 创建/更新模块文档（design / plan / spec / todo）v2.0
- [x] 运行 `flutter analyze` / `flutter test` 通过

**验收标准**：
- `flutter analyze` 无问题。
- 单元测试覆盖率 ≥60%。
- 模型 JSON 往返、主要班组置顶、Repository 持久化测试通过。

### M2: 排班计算与月历骨架（已完成）

- [x] 实现 `ShiftScheduleService`：日期 → 各班组班次计算（含负数取模）
- [x] 扩展 `ShiftCalendarController` / `shiftCalendarProvider`：聚焦月份、选中日期、月切換
- [x] 实现 `DayInfo` 运行时聚合
- [x] 搭建月历页面骨架：整月按周分组，左侧班次标签 + 7 列日期，每个单元格显示日期及班组
- [x] 处理窄宽度横向滚动与班组名称自适应缩放，避免文字被压扁
- [x] 单元测试覆盖排班计算、月/周起始/结束计算、`DayInfo` 聚合

**验收标准**：
- 任意日期可正确推算 3–6 班制班次。
- 月历页面可展示整月，每周 7 天 × M 个班次。
- 窄宽度下每周块可横向滚动，文字不自适应旋转或压扁。
- 单元测试覆盖率 ≥70%。

### M3: 月历布局与班组交互（已完成）

- [x] 月历按周分组渲染，每周块独立适配可用宽度
- [x] 窄宽度时启用横向滚动，班组名称使用 `FittedBox` 自适应缩放
- [x] 主要班组所在单元格高亮显示
- [x] 实现班组拖拽排序（主要班组固定置顶）
- [x] 实现班组长按/右键菜单：设为主要班组、编辑、删除
- [x] Widget 测试覆盖月历渲染、横向滚动、主要班组高亮

**验收标准**：
- 整月月历无布局异常。
- 窄宽度下每周块可横向滚动，文字不被压扁或旋转。
- 拖拽可调整普通班组顺序，主要班组位置不变。
- 单元测试 + Widget 测试覆盖率 ≥75%。

### M4: 节假日、农历与日期跳转（已完成）

- [x] 封装 `LunarInfoService`（基于 `lunar` 包）
- [x] 实现 `HolidayDataService`：内置兜底 + 三源在线更新 + 格式归一化
- [x] 实现 `HolidayDataController` / `holidayDataProvider`：缓存、更新状态、自动检查
- [x] 在月历日期行显示农历、节气、节假日标记
- [x] 实现日期选择器与“返回今天”，支持历史与未来跳转
- [x] 单元测试覆盖农历计算、节假日多源归一化、日期格式化

**验收标准**：
- 离线可显示近三年节假日与农历。
- 三源任一成功即可更新；全部失败不崩溃。
- 单元测试覆盖率 ≥80%。

### M5: 首页仪表盘与设置页

- [ ] 实现 `ShiftDashboardController` / `shiftDashboardProvider`
- [ ] 首页仪表盘：当天日期/农历/节假日、所有班组班次卡片、主要班组高亮
- [ ] 实现设置页：班组管理、轮班模式模板、主要班组设置、节假日手动更新
- [ ] Widget 测试覆盖仪表盘卡片、设置页表单
- [ ] 验证 `exportData` / `importData` 往返一致，兼容旧版数据迁移

**验收标准**：
- 仪表盘与月历选中日期联动。
- 设置页即时持久化，返回后 UI 同步。
- 单元测试 + Widget 测试覆盖率 ≥80%。

### M6: 提醒、统计与合并

- [ ] 实现提醒时间计算服务
- [ ] 集成底座通知服务注册/取消提醒
- [ ] 实现月度工时统计卡片
- [ ] 更新主项目 `pubspec.yaml` path 依赖
- [ ] 在主项目 `lib/main.dart` 注册模块
- [ ] 主项目 `flutter analyze` / `flutter test` 通过
- [ ] 提交合并

**验收标准**：
- 提醒功能在 Windows 桌面可正常触发（或至少接口对接完成）。
- 主项目集成后无编译错误。
- 全模块测试覆盖率 ≥80%。

---

## 3. 测试计划

### 3.1 单元测试

| 目标 | 内容 | 里程碑 |
|------|------|--------|
| Models | ShiftConfig / ShiftGroup / ShiftPattern / ShiftSlot / HolidayInfo 的 JSON 往返、copyWith、默认构造 | M1 |
| Repository | 默认配置加载、自定义配置持久化、key 前缀规范 | M1 |
| ShiftScheduleService | 3–6 班制日期推算、负数取模、跨夜班、休息班次 | M2 |
| LunarInfoService | 公历 → 农历、节气、干支、生肖 | M4 |
| HolidayDataService | 多源格式归一化、兜底合并、异常降级 | M4 |
| DashboardController | 当天数据聚合、主要班组优先 | M5 |

### 3.2 Widget 测试

| 目标 | 内容 | 里程碑 |
|------|------|--------|
| ShiftAssistantPage | 班组列表渲染、加载状态 | M1 |
| MonthCalendar | 周块渲染、班次网格、主要班组高亮、横向滚动 | M3 |
| ReorderableGroupList | 拖拽排序、主要班组固定 | M3 |
| Dashboard | 当天卡片渲染、横竖屏切换 | M5 |
| SettingsPage | 班组增删改、模式选择 | M5 |

### 3.3 集成测试

| 目标 | 内容 | 里程碑 |
|------|------|--------|
| Module lifecycle | initialize / dispose / exportData / importData | M1 / M5 |
| Holiday update | 三源降级、离线兜底 | M4 |
| Main project | 模块注册、导航、同步 | M6 |

### 3.4 静态分析

- 每个里程碑结束时运行 `flutter analyze`，确保零报错。
- 模块合并前运行主项目 `flutter analyze`。

---

## 4. 关键决策

- 固定周期模型优先，复杂自定义排班后续迭代。
- 节假日数据采用“本地兜底 + 多源在线更新”策略，确保离线可用。
- 月历网格自研（周块 × 班次行 × 日期列），贴合截图架构并避免通用组件样式偏移。
- 农历/节气借用 `lunar` 包，本地计算不依赖网络。
- 提醒功能在 M6 阶段对接底座通知服务。

---

## 5. 参考

- [shift_assistant_design.md](./shift_assistant_design.md)
- [shift_assistant_spec.md](./shift_assistant_spec.md)
- [shift_assistant_todo.md](./shift_assistant_todo.md)
