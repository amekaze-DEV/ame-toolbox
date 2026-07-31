# 多功能计算器模块 — 任务追踪清单

> **用途**: 子项目负责人与 Agent 日常任务跟踪
> **数据源**: `docs/calculator_plan.md`、`docs/calculator_spec.md`、`docs/calculator_design.md`
> **约束基线**: `../../project_constraints.md`、`../../modular_tool_app_spec.md`、`../../design.md`

---

## 项目状态面板

| 属性 | 值 |
|------|-----|
| **模块 ID** | `calculator` |
| **模块名称** | 多功能计算器 |
| **当前阶段** | Phase 1（基础设施与配置模型） |
| **总体进度** | 0% |
| **已完成任务数** | 0 / 38 |
| **阻塞任务数** | 0 |
| **下一里程碑** | M1 - 配置模型就绪 |

---

## 1. Phase 1: 基础设施与配置模型

### P1-T1: 更新 `pubspec.yaml` 依赖
- [ ] P1-T1: 更新 `pubspec.yaml` 依赖
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 已添加 `math_expressions`、`units_converter`、`intl`；`dio` 按需添加；`ametoolbox` path 依赖已配置
  - 参考: `calculator_spec.md` §2.2 / `calculator_plan.md` §2.1

### P1-T2: 定义 `CalculatorType` 枚举
- [ ] P1-T2: 定义 `CalculatorType` 枚举
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 包含 scientific、standardCubicToMass、unitConverter、geometry、radix、exchangeRate 6 个类型
  - 参考: `calculator_spec.md` §4.1

### P1-T3: 定义 `CalculatorConfig`
- [ ] P1-T3: 定义 `CalculatorConfig`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T2
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 含 toJson / fromJson / copyWith；默认 currentType=scientific、decimalPrecision=6、showFullKeyboard=true
  - 参考: `calculator_spec.md` §4.2

### P1-T4: 定义 `CalculationHistory`
- [ ] P1-T4: 定义 `CalculationHistory`
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 含 expression、result、timestamp、isError、angleMode；JSON 往返一致
  - 参考: `calculator_spec.md` §4.3

### P1-T5: 定义 `ExchangeRateCache`
- [ ] P1-T5: 定义 `ExchangeRateCache`
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 含 baseCurrency、rates、lastUpdated、sourceUrl；JSON 往返一致
  - 参考: `calculator_spec.md` §4.4

### P1-T6: 实现 `CalculatorConfigRepository`
- [ ] P1-T6: 实现 `CalculatorConfigRepository`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T3, P1-T4, P1-T5
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 封装 `StorageService.saveData/loadData`；业务数据 key 前缀 `module_calculator_`；首次读取返回默认配置
  - 参考: `calculator_design.md` §3.2 / `calculator_plan.md` §2.1

### P1-T7: 定义模块级 Riverpod Provider
- [ ] P1-T7: 定义模块级 Riverpod Provider
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T6
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: `calculatorConfigRepositoryProvider`、`calculatorConfigProvider` 可注入；配置变更即时持久化
  - 参考: `calculator_design.md` §2.1 / §2.3

### P1-T8: 配置独立运行入口主题
- [ ] P1-T8: 配置独立运行入口主题
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: `lib/main.dart` 使用 MD3 主题，`ProviderScope` 包裹；独立运行可显示模块主页框架
  - 参考: `calculator_plan.md` §2.1

---

## 2. Phase 2: 科学计算器（C-01）

### P2-T1: 集成 `math_expressions`
- [ ] P2-T1: 集成 `math_expressions`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T1
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: `ScientificCalculatorService` 封装表达式求值、函数、常数、错误处理
  - 参考: `calculator_spec.md` §3.1 / `calculator_design.md` ADR-CAL-001

### P2-T2: 表达式规范化
- [ ] P2-T2: 表达式规范化
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: `×`→`*`、`÷`→`/`、去除空格、百分号处理
  - 参考: `calculator_spec.md` §3.1.2

### P2-T3: 角度模式支持
- [ ] P2-T3: 角度模式支持
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: DEG/RAD 切换；三角函数按当前模式计算；反三角函数输出按当前模式表示
  - 参考: `calculator_spec.md` §3.1.7

### P2-T4: 结果格式化
- [ ] P2-T4: 结果格式化
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T2
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 精度、科学计数法、错误文案格式化；极小值自动转科学计数法
  - 参考: `calculator_spec.md` §3.1.4

### P2-T5: 历史记录管理
- [ ] P2-T5: 历史记录管理
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T4
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 添加、查询、清空、上限 20；仅保存成功计算
  - 参考: `calculator_spec.md` §3.1.6

### P2-T6: 科学计算器页面
- [ ] P2-T6: 科学计算器页面
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T4, P2-T5
  - 预估工时: 2 天
  - 状态: 待开始
  - 验收标准摘要: 显示区 + 键盘 + 类型切换；使用 `ConsumerWidget` + `ref.watch/read`
  - 参考: `calculator_spec.md` §5 / `calculator_plan.md` §3.2

### P2-T7: 历史详情页
- [ ] P2-T7: 历史详情页
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T5, P2-T6
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 竖屏全屏历史页；单击回填、长按/右键删除、顶部清空
  - 参考: `calculator_spec.md` §3.1.6

### P2-T8: 键盘布局
- [ ] P2-T8: 键盘布局
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T6
  - 预估工时: 2 天
  - 状态: 待开始
  - 验收标准摘要: 4 列竖版布局（上方高级算符/函数、左下数字区、基础算符围绕数字区上方一行及右侧一列）；完整键盘与精简键盘切换；`2nd` 第二功能面板
  - 参考: `calculator_spec.md` §3.1.5 / `calculator_design.md` ADR-CAL-005

### P2-T9: 错误文案本地化
- [ ] P2-T9: 错误文案本地化
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 覆盖除零、负数开平方、对数非正数、括号不匹配、语法错误、阶乘非法等场景
  - 参考: `calculator_spec.md` §3.1.8

---

## 3. Phase 3: 标准立方米-质量 / 单位 / 几何（C-02 / C-03 / C-04）

### P3-T1: 集成 `units_converter`
- [ ] P3-T1: 集成 `units_converter`
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T1
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: `UnitConverterService` 封装长度、重量、面积、体积、速度、时间、角度 7 类线性单位
  - 参考: `calculator_spec.md` §3.3 / `calculator_design.md` ADR-CAL-002

### P3-T2: 温度转换特殊处理
- [ ] P3-T2: 温度转换特殊处理
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T1
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 自研 °C/°F/K 公式，不依赖 `units_converter` 线性换算
  - 参考: `calculator_spec.md` §3.3.3

### P3-T3: 几何公式库
- [ ] P3-T3: 几何公式库
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: `GeometryService` 覆盖圆、矩形、长方体、圆柱、圆锥、球、圆筒、棱锥的面积/表面积/体积
  - 参考: `calculator_spec.md` §3.4

### P3-T4: 标准立方米-质量服务
- [ ] P3-T4: 标准立方米-质量服务
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 内置 7 种气体摩尔质量表；支持自定义摩尔质量/标准摩尔体积；双向换算与标准密度推导
  - 参考: `calculator_spec.md` §3.2 / `calculator_design.md` ADR-CAL-003

### P3-T5: 单位转换页面
- [ ] P3-T5: 单位转换页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T2
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 类别选择 + 双单位输入 + 交换按钮；实时换算
  - 参考: `calculator_spec.md` §3.3.2

### P3-T6: 几何计算页面
- [ ] P3-T6: 几何计算页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T3
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 几何体选择 + 动态字段 + 结果卡片 + 公式说明展开
  - 参考: `calculator_spec.md` §3.4.2

### P3-T7: 标准立方米-质量页面
- [ ] P3-T7: 标准立方米-质量页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T4
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 气体类型选择 + 摩尔质量/标准摩尔体积输入 + Nm³/质量双向换算
  - 参考: `calculator_spec.md` §3.2

### P3-T8: 输入校验与错误提示
- [ ] P3-T8: 输入校验与错误提示
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T4, P3-T5, P3-T6
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: M>0、Vm>0、尺寸>0、圆筒 R>r、棱锥 n≥3 等校验
  - 参考: `calculator_spec.md` §3.2.3 / §3.4.3

---

## 4. Phase 4: 进制与汇率（C-05 / C-06）

### P4-T1: 进制转换服务
- [ ] P4-T1: 进制转换服务
  - 优先级: P2
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 二/八/十/十六互转；整数与有限小数；位运算（AND/OR/XOR/NOT/<< />>）
  - 参考: `calculator_spec.md` §3.5

### P4-T2: 汇率服务
- [ ] P4-T2: 汇率服务
  - 优先级: P2
  - 主导: DEV
  - 依赖: P1-T5
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: HTTP 请求、缓存、离线回退、自定义源 `{base}` 占位符替换
  - 参考: `calculator_spec.md` §3.6

### P4-T3: 进制转换页面
- [ ] P4-T3: 进制转换页面
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T1
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 四进制输入框实时同步 + 位运算界面
  - 参考: `calculator_spec.md` §3.5.3

### P4-T4: 汇率页面
- [ ] P4-T4: 汇率页面
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 货币选择 + 金额输入 + 刷新按钮 + 离线缓存提示
  - 参考: `calculator_spec.md` §3.6

### P4-T5: 汇率 HTTP 客户端
- [ ] P4-T5: 汇率 HTTP 客户端
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 使用 `dio`；支持自定义源；错误处理与超时
  - 参考: `calculator_spec.md` §3.6.2

### P4-T6: 汇率缓存持久化
- [ ] P4-T6: 汇率缓存持久化
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 通过 `StorageService` 保存；key `module_calculator_exchange_rates`
  - 参考: `calculator_spec.md` §9

---

## 5. Phase 5: 布局、设置、首页仪表盘

### P5-T1: 模块主页框架
- [ ] P5-T1: 模块主页框架
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 顶部选择器 + `ResponsiveBuilder` 切换横竖屏；使用 `ConsumerWidget`
  - 参考: `calculator_spec.md` §5.1 / §5.2

### P5-T2: 横竖屏布局
- [ ] P5-T2: 横竖屏布局
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T1
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 竖屏单列；横屏双列；`historyPanelOnLeft` 控制左右交换
  - 参考: `calculator_spec.md` §5.1

### P5-T3: 历史面板
- [ ] P5-T3: 历史面板
  - 优先级: P1
  - 主导: DEV
  - 依赖: P5-T2, P2-T7
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 竖屏弹窗/页面；横屏固定面板；最近 20 条
  - 参考: `calculator_spec.md` §5.1

### P5-T4: 模块设置页
- [ ] P5-T4: 模块设置页
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 1.5 天
  - 状态: 待开始
  - 验收标准摘要: 小数精度、科学计数法、横屏布局、键盘显示、首页卡片、汇率源、进制位宽、清除历史
  - 参考: `calculator_spec.md` §6

### P5-T5: 首页快速计算器卡片
- [ ] P5-T5: 首页快速计算器卡片
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T6
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 模块摘要卡片 Widget；可独立开关；支持精简键盘；点击进入模块主页
  - 参考: `calculator_spec.md` §7.1

### P5-T6: 首页历史卡片
- [ ] P5-T6: 首页历史卡片
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T5, P5-T5
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 最近 3-5 条历史；点击进入模块并回填
  - 参考: `calculator_spec.md` §7.2

### P5-T7: 更新 `CalculatorModule`
- [ ] P5-T7: 更新 `CalculatorModule`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T1, P5-T4, P5-T5, P5-T6
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 接入 `summary`、`buildPage`、`buildSettingsPage`、`initialize`、`dispose`、`exportData`、`importData`
  - 参考: `calculator_spec.md` §8

### P5-T8: 键盘显示开关联动
- [ ] P5-T8: 键盘显示开关联动
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T8, P5-T4
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 关闭 `showFullKeyboard` 后数字键隐藏、算符键保留、页面正确刷新
  - 参考: `calculator_spec.md` §5.4

---

## 6. Phase 6: 模块契约接入与集成验证

### P6-T1: 独立运行验证
- [ ] P6-T1: 独立运行验证
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T7
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: `flutter test`、`flutter analyze`、`flutter build windows --debug` 通过
  - 参考: `calculator_plan.md` §7

### P6-T2: 主项目注册
- [ ] P6-T2: 主项目注册
  - 优先级: P0
  - 主导: DEV
  - 依赖: P6-T1
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 替换 `lib/core/modules/module_registry.dart` 中 calculator 占位模块；主项目 `pubspec.yaml` 添加模块依赖
  - 参考: `calculator_plan.md` §7.1

### P6-T3: 集成测试
- [ ] P6-T3: 集成测试
  - 优先级: P0
  - 主导: QA
  - 依赖: P6-T2
  - 预估工时: 1 天
  - 状态: 待开始
  - 验收标准摘要: 导航栏显示、主页卡片、横竖屏切换、设置页入口、WebDAV 同步导入导出、不修改底座其他代码
  - 参考: `calculator_plan.md` §7.2

### P6-T4: OWNER 验收
- [ ] P6-T4: OWNER 验收
  - 优先级: P0
  - 主导: OWNER
  - 依赖: P6-T3
  - 预估工时: 0.5 天
  - 状态: 待开始
  - 验收标准摘要: 全部验收标准通过；`git diff` 仅 `module_registry.dart` 与主项目 `pubspec.yaml` 变更
  - 参考: `README.md` §9

---

## 7. 里程碑追踪

- [ ] **M1: 配置模型就绪**
  - 目标日期: Phase 1 完成
  - 验收条件: P1-T1 ~ P1-T8 完成，`flutter test` 通过，配置模型 JSON 往返一致
  - 状态: 未达到

- [ ] **M2: 科学计算器可用**
  - 目标日期: Phase 2 完成
  - 验收条件: P2-T1 ~ P2-T9 完成，12+ 项核心计算测试通过
  - 状态: 未达到

- [ ] **M3: P1 计算能力完成**
  - 目标日期: Phase 3 完成
  - 验收条件: P3-T1 ~ P3-T8 完成，标准立方米-质量、单位、几何服务测试通过
  - 状态: 未达到

- [ ] **M4: P2 计算能力完成**
  - 目标日期: Phase 4 完成
  - 验收条件: P4-T1 ~ P4-T6 完成，进制与汇率服务测试通过
  - 状态: 未达到

- [ ] **M5: UI/设置/首页完成**
  - 目标日期: Phase 5 完成
  - 验收条件: P5-T1 ~ P5-T8 完成，Widget 测试覆盖横竖屏与设置持久化
  - 状态: 未达到

- [ ] **M6: 集成验收通过**
  - 目标日期: Phase 6 完成
  - 验收条件: P6-T1 ~ P6-T4 完成，底座运行正常，仅注册表与 pubspec 变更
  - 状态: 未达到

---

## 8. 本周任务

> 当前聚焦任务，用于快速查看与每日更新

- [ ] **Phase 1 启动：基础设施与配置模型**
  - 优先级: P0
  - 状态: 待开始
  - 负责人: DEV
  - 交付物: `pubspec.yaml`、模型、`CalculatorConfigRepository`、Provider、`main.dart`
  - 前置条件: 无（子项目可在底座完成后独立开发）
  - 下一步: 完成 P1-T1 ~ P1-T8 后进入 Phase 2

---

## 9. 阻塞与风险

### 当前阻塞的任务
- 无

### 高优先级风险项
- **R-CAL-001: `math_expressions` 对中文符号或特定函数支持不足**（中）
  - 影响: P2-T1, P2-T2
  - 应对: `ScientificCalculatorService` 封装层做符号规范化与错误兜底

- **R-CAL-002: 公开汇率 API 不稳定或限流**（中）
  - 影响: P4-T2, P4-T4
  - 应对: 支持自定义源 + 离线缓存；默认源可替换

- **R-CAL-003: 横竖屏布局复杂，Widget 测试覆盖不足**（中）
  - 影响: P5-T2, P5-T3
  - 应对: 使用底座 `ResponsiveBuilder`，为 portrait/landscape 分别写 Widget 测试

### 中优先级风险项
- **R-CAL-004: 模块合并后 import 路径错误**（中）
  - 影响: P6-T2
  - 应对: 模块内部统一使用 `package:ametoolbox/...` 引用底座，避免相对路径跨包

### 需要 OWNER 决策的事项
- 无

---

## 10. 更新记录

- **最后更新**: 2026-07-31
- **更新说明**: 按 `calculator_plan.md` 拆分 Phase 1-6 任务，建立子项目独立 todo 清单，对齐 `guide.md` 七步工作流与 `project_constraints.md` 模块契约约束
- **2026-07-31**: 文件重命名为 `calculator_todo.md`，与主线 `todo.md` 作命名区分