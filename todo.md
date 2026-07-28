# AMEToolbox 任务追踪清单

> **用途**: 项目负责人与 Agent 日常任务跟踪
> **数据源**: task_assignments.md

---

## 项目状态面板

| 属性 | 值 |
|------|-----|
| **项目名称** | AMEToolbox |
| **当前阶段** | Phase A（底座开发） |
| **总体进度** | 33% |
| **已完成任务数** | 5 / 15 |
| **阻塞任务数** | 0 |
| **交互原型** | 已完成（16 页面，含 6 基础版页面） |
| **下一里程碑** | M2 - 基础设施完成 |

---

## 1. Phase A: APP底座框架开发

### TASK-00: 项目初始化与基础架构
- [x] TASK-00: 项目初始化与基础架构
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 3-5天
  - 状态: 已完成
  - 验收标准摘要: Flutter项目可成功编译运行；PlatformInfo/DeviceInfoProvider抽象接口定义完成；UI层与平台层解耦
  - 完成说明: 代码已通过 `flutter analyze`；Windows 桌面端 debug 构建通过；应用启动后显示空白 Scaffold 页面

### TASK-01: 本地持久化存储层
- [x] TASK-01: 本地持久化存储层
  - 优先级: P0
  - 主导: DEV
  - 依赖: TASK-00
  - 预估工时: 3-5天
  - 状态: 已完成
  - 验收标准摘要: StorageService接口CRUD完整；Hive实现读写正确；密码字段加密存储；首次启动自动初始化预设数据
  - 完成说明: 已实现StorageService抽象接口与HiveStorage实现；首次启动自动写入默认主题/布局/同步配置及3个预设模块定义与状态；WebDAV密码与设备ID通过flutter_secure_storage加密存储；静态代码检查通过，UI层与存储层无Platform.is*/dart:io引用

### TASK-08: 输入模式适配（触控与键鼠）
- [ ] TASK-08: 输入模式适配（触控与键鼠）
  - 优先级: P0
  - 主导: DEV
  - 依赖: TASK-00
  - 预估工时: 4-6天
  - 状态: 待开始
  - 验收标准摘要: 触控/键鼠自动切换；AdaptiveButton/AdaptiveListTile组件完备；键盘快捷键键鼠模式可用；无Platform.is*引用

### TASK-02: 模块管理系统
- [x] TASK-02: 模块管理系统
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-00, TASK-01
  - 预估工时: 3-4天
  - 状态: 已完成
  - 验收标准摘要: 模块管理页面Switch开关双向绑定持久化；ModuleContract接口定义完成并冻结
  - 完成说明: 已定义ModuleContract并冻结接口；实现ModuleRegistry注册表（含占位模块）与ModuleController状态管理；完成模块管理页面与MD3 Switch组件；Switch状态与ModuleState.enabled双向绑定、300ms过渡、即时持久化；底部实时显示已启用模块数；主页通过临时入口可跳转模块管理页面；flutter analyze与flutter test均通过

### TASK-03: 响应式布局引擎
- [x] TASK-03: 响应式布局引擎
  - 优先级: P0
  - 主导: DEV
  - 依赖: TASK-00, TASK-01
  - 预估工时: 4-6天
  - 状态: 已完成
  - 验收标准摘要: 横竖屏判定正确切换平滑；自动/手动断点模式；DPI缩放机制（自动/手动）；布局逻辑无Platform.is*调用
  - 完成说明: 已实现LayoutController（WidgetsBindingObserver监听尺寸变化、自动/手动断点、自动/手动DPI缩放、配置持久化）、LayoutMode枚举、layout_provider、ResponsiveBuilder（300ms AnimatedSwitcher过渡）与AspectRatioHelper；DPI缩放已通过App根组件MediaQuery.textScaler注入；flutter analyze、flutter test、flutter build windows --debug均通过；lib/features/与lib/shared/无Platform.is*/dart:io引用

### TASK-04: 主题与显示设置系统
- [x] TASK-04: 主题与显示设置系统
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-00, TASK-01
  - 预估工时: 4-6天
  - 状态: 已完成
  - 验收标准摘要: 明亮/暗黑模式切换；6种强调色选择；DPI/字体缩放调节；配置即时生效并持久化
  - 完成说明: 已实现Md3ColorScheme（ColorScheme.fromSeed生成完整MD3色板）、ThemeSettingsPage（主题模式卡片/强调色色块/DPI缩放区/字体大小区/实时预览区）、LayoutSettingsPage（横竖屏断点区/DPI缩放区）、Md3Slider封装；App根组件使用AnimatedTheme实现300ms主题切换过渡；主题页与布局页DPI设置通过同一LayoutController实时联动；所有配置即时持久化；flutter analyze、flutter test、flutter build windows --debug均通过；lib/features/与lib/shared/无Platform.is*/dart:io引用

### TASK-07: WebDAV数据同步
- [ ] TASK-07: WebDAV 数据同步
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-00, TASK-01
  - 预估工时: 5-7天
  - 状态: 待开始
  - 验收标准摘要: 连接测试与手动/自动同步；冲突解决（最后修改时间优先）；密码加密存储；同步状态反馈

### TASK-05: 导航与主页
- [ ] TASK-05: 导航与主页
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-01, TASK-02, TASK-03, TASK-08
  - 预估工时: 5-7天
  - 状态: 待开始
  - 验收标准摘要: 竖屏底部导航/横屏左侧导航自适应；模块卡片展示已启用模块；导航栏滚动支持；同步状态卡片

### TASK-06: 设置页
- [ ] TASK-06: 设置页
  - 优先级: P2
  - 主导: DEV
  - 依赖: TASK-01, TASK-02, TASK-04, TASK-07
  - 预估工时: 4-5天
  - 状态: 待开始
  - 验收标准摘要: 三大分区布局（全局/同步/模块）；同步/模块总开关折叠隐藏子项；MD3分组列表视觉规范

---

## 2. Phase B: 子项目并行开发

### SUB-01: 计数器模块开发
- [ ] SUB-01: 计数器模块开发
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-02 (ModuleContract 冻结)
  - 预估工时: 2-3周
  - 状态: 待开始
  - 验收标准摘要: 实现ModuleContract全部方法；计数/重置/目标值功能完整；单元测试覆盖率>=80%；集成测试通过

### SUB-02: 计时器模块开发
- [ ] SUB-02: 计时器模块开发
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-02 (ModuleContract 冻结)
  - 预估工时: 2-3周
  - 状态: 待开始
  - 验收标准摘要: 实现ModuleContract全部方法；启动/暂停/重置/预设/正倒计时功能完整；单元测试覆盖率>=80%；集成测试通过

### SUB-03: 检查表模块开发
- [ ] SUB-03: 检查表模块开发
  - 优先级: P1
  - 主导: DEV
  - 依赖: TASK-02 (ModuleContract 冻结)
  - 预估工时: 2-3周
  - 状态: 待开始
  - 验收标准摘要: 实现ModuleContract全部方法；检查项增删改查/勾选/分类功能完整；单元测试覆盖率>=80%；集成测试通过

---

## 3. Phase C: 集成与发布

### INT-01: 集成测试
- [ ] INT-01: 集成测试
  - 优先级: P0
  - 主导: QA
  - 依赖: 所有 TASK + SUB 完成
  - 预估工时: 1-2周
  - 状态: 待开始
  - 验收标准摘要: 全功能集成测试通过；约束合规检查全部通过；Bug跟踪闭环

### INT-02: CI/CD 流水线
- [ ] INT-02: CI/CD 流水线搭建
  - 优先级: P1
  - 主导: OPS
  - 依赖: TASK-00
  - 预估工时: 3-5天
  - 状态: 待开始
  - 验收标准摘要: 自动构建/静态分析/单元测试/打包发布全流程自动化

### INT-03: v1.0 版本发布
- [ ] INT-03: v1.0 版本发布
  - 优先级: P0
  - 主导: OPS
  - 依赖: INT-01, INT-02
  - 预估工时: 2-3天
  - 状态: 待开始
  - 验收标准摘要: Windows平台可运行安装包；全部验收测试通过；版本号正确；OWNER签署验收

---

## 4. 里程碑追踪

- [x] **M1: 项目初始化完成**
  - 目标日期: 第1周
  - 验收条件: TASK-00 完成，Flutter项目可运行，平台抽象层接口定义完成
  - 状态: 已达到
  - 备注: 代码静态分析与 Windows debug 构建均已通过

- [ ] **M2: 基础设施完成**
  - 目标日期: 第2周
  - 验收条件: TASK-01 + TASK-08 完成，存储层与输入适配框架就绪
  - 状态: 进行中
  - 备注: TASK-01 已完成，待 TASK-08 完成后达到

- [ ] **M3: 核心能力层完成**
  - 目标日期: 第4周
  - 验收条件: TASK-02 + TASK-03 + TASK-04 + TASK-07 完成
  - 状态: 进行中
  - 备注: TASK-02、TASK-03、TASK-04 已完成，待 TASK-07 完成后达到

- [ ] **M4: ModuleContract 接口冻结**
  - 目标日期: 第4周
  - 验收条件: TASK-02 完成，ModuleContract 接口在规格文档中冻结，OWNER + ARCH 审批
  - 状态: 已达到（待人工审批）
  - 备注: TASK-02 已完成，ModuleContract 实现与 modular_tool_app_spec.md 3.9 节规格一致，等待 OWNER + ARCH 最终审批

- [ ] **M5: 底座框架完成**
  - 目标日期: 第6周
  - 验收条件: TASK-05 + TASK-06 完成，底座具备完整能力
  - 状态: 未达到

- [ ] **M6: 子项目全部完成**
  - 目标日期: 第9周
  - 验收条件: SUB-01 + SUB-02 + SUB-03 全部完成，集成测试通过
  - 状态: 未达到

- [ ] **M7: v1.0 发布**
  - 目标日期: 第11周
  - 验收条件: 集成测试通过，全平台验证通过，发布包就绪，OWNER签署
  - 状态: 未达到

---

## 5. 本周任务

> 当前聚焦任务，用于快速查看与每日更新

- [x] **交互原型设计：AMEToolbox 交互原型**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: Design Agent
  - 交付物: `ametoolbox-prototype/` 目录（10 页面 HTML + .design 画布 + MD3 品牌 CSS）
  - 覆盖范围: 主页（竖屏/横屏）、模块管理、设置页、主题/布局/同步设置、计数器/计时器/检查表模块
  - 设计约束: MD3 设计规范、安全橙 #E85D04 种子色、UI 可移植性（无 Platform.is*）、触控+键鼠双模式
  - 验证状态: validate-design-workspace 通过、validate-finish-readiness 通过

- [x] **基础版 UI 开发：交互原型功能增强**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: Design Agent
  - 交付物: `ametoolbox-prototype/pages/` 新增 6 个基础版 HTML 页面（home-portrait-basic、counter-basic、timer-basic、checklist-basic、settings-basic、module-management-basic）
  - 覆盖范围: 在交互原型基础上增加功能交互（计数器目标设置/进度环、计时器正倒计时切换/圈数记录、检查表筛选/添加弹窗、设置可折叠分区/MD3 开关、模块管理摘要卡片、主页问候语/同步横幅/FAB）
  - 版本收敛: 6 个基础版页面通过 `supersedesPageId` 标记替代对应原版页面，原版页面保留于画布供对比
  - 验证状态: validate-design-workspace --expected-pages=16 通过、validate-finish-readiness --check=all 通过

- [x] **TASK-00: 项目初始化与基础架构**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: DEV
  - 备注: 代码已通过 `flutter analyze`；Windows 完整构建需启用开发者模式

- [x] **TASK-01: 本地持久化存储层**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: DEV
  - 交付物: `lib/core/storage/storage_service.dart`、`lib/core/storage/hive_storage.dart`、各模型 Hive TypeAdapter
  - 备注: StorageService CRUD 完整；Hive 实现覆盖全部数据模型；敏感字段走 flutter_secure_storage；首次启动自动初始化默认配置与模块清单

- [x] **TASK-02: 模块管理系统**
  - 优先级: P1
  - 状态: 已完成
  - 负责人: DEV
  - 交付物: `lib/core/modules/module_contract.dart`、`lib/core/modules/module_registry.dart`、`lib/core/modules/module_controller.dart`、`lib/features/module_management/module_management_page.dart`、`lib/shared/widgets/md3_switch.dart`
  - 备注: ModuleContract 接口冻结；模块管理页面 Switch 双向绑定持久化；300ms 过渡动效；底部实时计数；flutter analyze / flutter test 通过；Windows debug 构建需开启开发者模式

- [x] **TASK-03: 响应式布局引擎**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: DEV
  - 交付物: `lib/core/layout/layout_controller.dart`、`lib/core/layout/responsive_builder.dart`、`lib/core/models/layout_mode.dart`、`lib/core/providers/layout_provider.dart`、`lib/shared/utils/aspect_ratio_helper.dart`
  - 备注: LayoutController 监听屏幕尺寸并实时判定横竖屏；自动/手动断点与 DPI 缩放；ResponsiveBuilder 提供 300ms 切换动画；DPI 通过 MediaQuery.textScaler 注入；flutter analyze / flutter test / flutter build windows --debug 均通过

- [x] **TASK-04: 主题与显示设置系统**
  - 优先级: P1
  - 状态: 已完成
  - 负责人: DEV
  - 交付物: `lib/core/theme/md3_color_scheme.dart`、`lib/features/settings/theme_settings_page.dart`、`lib/features/settings/layout_settings_page.dart`、`lib/shared/widgets/md3_slider.dart`
  - 备注: Md3ColorScheme 通过 ColorScheme.fromSeed 生成完整 MD3 色板；主题设置页含明暗/强调色/DPI/字体/预览区；布局设置页含断点/DPI 区；两页 DPI 设置实时联动；App 根组件 AnimatedTheme 实现 300ms 主题过渡；flutter analyze / flutter test / flutter build windows --debug 均通过

---

## 6. 阻塞与风险

### 当前阻塞的任务
- 无

### 高优先级风险项
- **R-001: Flutter 桌面端生态成熟度不足**（高）
  - 影响: TASK-00
  - 应对: 首发聚焦 Windows 平台，选用跨平台兼容性经验证的插件

- **R-003: 依赖链阻塞（TASK-00/01 阻塞后续）**（高）
  - 影响: 全部任务
  - 应对: 优先安排 TASK-00 和 TASK-01，DEV Agent 优先保障

- **R-005: Agent 输出质量波动导致交付延期**（高）
  - 影响: TASK-00/01/03/08
  - 应对: 关键任务设置 ARCH 代码审查环节，OWNER 最终验收

- **R-006: 多 Agent 协作缺乏 Flutter 桌面端经验**（高）
  - 影响: TASK-00, TASK-08
  - 应对: ARCH 提前做技术 Spikes 验证关键点，DEV Agent 参考验证结果开发

### 中优先级风险项
- **R-004: 并行开发协调不一致导致接口频繁变更**（中）
  - 影响: TASK-02, SUB 系列
  - 应对: Phase C 冻结 ModuleContract，变更走 ARCH 审查 + OWNER 审批流程

### 需要 OWNER 决策的事项
- 待 TASK-00 启动后陆续产生

---

## 更新记录

- **最后更新**: 2026-07-28
- **更新说明**: 初始化任务清单，基于 task_assignments.md 生成全部 15 个任务与 7 个里程碑
- **2026-07-28 更新**: 完成交互原型设计交付（`ametoolbox-prototype/`），覆盖 10 个页面与 36 条页面间交互，遵循 MD3 设计规范与项目约束，通过设计与就绪双重验证门
- **2026-07-28 更新**: 完成 TASK-01 本地持久化存储层实现与静态验证，总体进度 13%（2/15），M2 基础设施完成进入进行中
- **2026-07-28 更新**: 完成 TASK-02 模块管理系统实现，`flutter analyze` 与 `flutter test` 通过，ModuleContract 接口冻结待 OWNER + ARCH 审批，总体进度 20%（3/15），M3 核心能力层进入进行中
- **2026-07-28 更新**: 完成基础版 UI 开发，在交互原型基础上新增 6 个基础版页面（home-portrait-basic、counter-basic、timer-basic、checklist-basic、settings-basic、module-management-basic），增加功能交互与组件状态，通过 `supersedesPageId` 实现版本收敛，画布总计 16 页面，validate-design-workspace --expected-pages=16 与 validate-finish-readiness --check=all 均通过
- **2026-07-28 更新**: 完成 TASK-03 响应式布局引擎实现，`flutter analyze`、`flutter test`、`flutter build windows --debug` 均通过，UI 层约束检查通过（无 Platform.is*/dart:io 引用），总体进度 27%（4/15）
- **2026-07-28 更新**: 完成 TASK-04 主题与显示设置系统实现，`flutter analyze`、`flutter test`、`flutter build windows --debug` 均通过，UI 层约束检查通过（无 Platform.is*/dart:io 引用），总体进度 33%（5/15），M3 核心能力层待 TASK-07 完成后达到
