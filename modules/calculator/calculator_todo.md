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
| **当前阶段** | Phase 6（模块契约接入与集成验证） |
| **总体进度** | 93% |
| **已完成任务数** | 40 / 43 |
| **阻塞任务数** | 0 |
| **下一里程碑** | M6 - 集成验收通过 |

---

## 1. Phase 1: 基础设施与配置模型

### P1-T1: 更新 `pubspec.yaml` 依赖
- [x] P1-T1: 更新 `pubspec.yaml` 依赖
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: 已配置 `ametoolbox` path 依赖，并添加 `flutter_riverpod` ^2.5.1、`math_expressions` ^2.7.0、`units_converter` ^3.0.0、`intl` ^0.20.0；`flutter pub get` 成功
  - 验收标准摘要: 已添加 `math_expressions`、`units_converter`、`intl`；`dio` 按需添加；`ametoolbox` path 依赖已配置
  - 参考: `calculator_spec.md` §2.2 / `calculator_plan.md` §2.1

### P1-T2: 定义 `CalculatorType` 枚举
- [x] P1-T2: 定义 `CalculatorType` 枚举
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/models/calculator_type.dart` 已创建，包含 6 个类型及 displayName / value / fromString 扩展
  - 验收标准摘要: 包含 scientific、standardCubicToMass、unitConverter、geometry、radix、exchangeRate 6 个类型
  - 参考: `calculator_spec.md` §4.1

### P1-T3: 定义 `CalculatorConfig`
- [x] P1-T3: 定义 `CalculatorConfig`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T2
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/models/calculator_config.dart` 已创建，含 copyWith / toJson / fromJson / == / hashCode；默认值为 scientific / 6 / true
  - 验收标准摘要: 含 toJson / fromJson / copyWith；默认 currentType=scientific、decimalPrecision=6、showFullKeyboard=true
  - 参考: `calculator_spec.md` §4.2

### P1-T4: 定义 `CalculationHistory`
- [x] P1-T4: 定义 `CalculationHistory`
  - 优先级: P0
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/models/calculation_history.dart` 已创建，含 expression、result、timestamp、isError、angleMode 字段及 JSON 方法
  - 验收标准摘要: 含 expression、result、timestamp、isError、angleMode；JSON 往返一致
  - 参考: `calculator_spec.md` §4.3

### P1-T5: 定义 `ExchangeRateCache`
- [x] P1-T5: 定义 `ExchangeRateCache`
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/models/exchange_rate_cache.dart` 已创建，含 baseCurrency、rates、lastUpdated、sourceUrl 字段及 JSON 方法
  - 验收标准摘要: 含 baseCurrency、rates、lastUpdated、sourceUrl；JSON 往返一致
  - 参考: `calculator_spec.md` §4.4

### P1-T6: 实现 `CalculatorConfigRepository`
- [x] P1-T6: 实现 `CalculatorConfigRepository`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T3, P1-T4, P1-T5
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/data/calculator_config_repository.dart` 已创建，封装 `StorageService`，key 为 `module_calculator_config`，读取失败返回默认配置
  - 验收标准摘要: 封装 `StorageService.saveData/loadData`；业务数据 key 前缀 `module_calculator_`；首次读取返回默认配置
  - 参考: `calculator_design.md` §3.2 / `calculator_plan.md` §2.1

### P1-T7: 定义模块级 Riverpod Provider
- [x] P1-T7: 定义模块级 Riverpod Provider
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T6
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/providers/calculator_config_provider.dart` 与 `calculator_config_controller.dart` 已创建，支持配置变更即时持久化
  - 验收标准摘要: `calculatorConfigRepositoryProvider`、`calculatorConfigProvider` 可注入；配置变更即时持久化
  - 参考: `calculator_design.md` §2.1 / §2.3

### P1-T8: 配置独立运行入口主题
- [x] P1-T8: 配置独立运行入口主题
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/main.dart` 已配置 MD3 主题与 `ProviderScope`，使用 `MemoryStorageService` 覆盖底座存储，独立运行入口可加载模块主页框架
  - 验收标准摘要: `lib/main.dart` 使用 MD3 主题，`ProviderScope` 包裹；独立运行可显示模块主页框架
  - 参考: `calculator_plan.md` §2.1

---

## 2. Phase 2: 科学计算器（C-01）

### P2-T1: 集成 `math_expressions`
- [x] P2-T1: 集成 `math_expressions`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T1
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/scientific_calculator_service.dart` 封装 `ShuntingYardParser`，覆盖表达式求值、函数注册、常数处理与错误映射
  - 验收标准摘要: `ScientificCalculatorService` 封装表达式求值、函数、常数、错误处理
  - 参考: `calculator_spec.md` §3.1 / `calculator_design.md` ADR-CAL-001

### P2-T2: 表达式规范化
- [x] P2-T2: 表达式规范化
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: 实现 `×`→`*`、`÷`→`/`、去除空格、科学计数法 `1e-12`→`(1*10^-12)`、自然常数 `e`→数值、百分号 `50%`→`(50/100)`
  - 验收标准摘要: `×`→`*`、`÷`→`/`、去除空格、百分号处理
  - 参考: `calculator_spec.md` §3.1.2

### P2-T3: 角度模式支持
- [x] P2-T3: 角度模式支持
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: 注册 `sin_deg`/`sin_rad` 等函数，通过 `applyAngleMode` 按 DEG/RAD 替换三角函数名；反三角函数输出按当前模式表示
  - 验收标准摘要: DEG/RAD 切换；三角函数按当前模式计算；反三角函数输出按当前模式表示
  - 参考: `calculator_spec.md` §3.1.7

### P2-T4: 结果格式化
- [x] P2-T4: 结果格式化
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T2
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `formatResult` 支持精度四舍五入、末尾 0 去除、科学计数法开关、极大/极小值自动转科学计数法
  - 验收标准摘要: 精度、科学计数法、错误文案格式化；极小值自动转科学计数法
  - 参考: `calculator_spec.md` §3.1.4

### P2-T5: 历史记录管理
- [x] P2-T5: 历史记录管理
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T4
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `ScientificCalculatorController` 实现历史记录添加、查询、单条删除、清空；仅保存成功计算；上限 20 条由 `CalculatorConfigController.addHistory` 截断
  - 验收标准摘要: 添加、查询、清空、上限 20；仅保存成功计算
  - 参考: `calculator_spec.md` §3.1.6

### P2-T6: 科学计算器页面
- [x] P2-T6: 科学计算器页面
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T4, P2-T5
  - 预估工时: 2 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/scientific_calculator_page.dart` 实现结果显示区、DEG/RAD 切换、历史缩略、4 列键盘；使用 `ConsumerStatefulWidget` + `ref.watch/read`
  - 验收标准摘要: 显示区 + 键盘 + 类型切换；使用 `ConsumerWidget` + `ref.watch/read`
  - 参考: `calculator_spec.md` §5 / `calculator_plan.md` §3.2

### P2-T7: 历史详情页
- [x] P2-T7: 历史详情页
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T5, P2-T6
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/history_page.dart` 实现竖屏全屏历史页，支持单击回填、长按删除、顶部清空全部
  - 验收标准摘要: 竖屏全屏历史页；单击回填、长按/右键删除、顶部清空
  - 参考: `calculator_spec.md` §3.1.6

### P2-T8: 键盘布局
- [x] P2-T8: 键盘布局
  - 优先级: P0
  - 主导: DEV
  - 依赖: P2-T6
  - 预估工时: 2 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/widgets/scientific_keypad.dart` 实现 4 列竖版布局，上方高级算符/函数、左下基础算符、右下数字区，支持 `2nd` 第二功能面板与完整/精简键盘切换
  - 验收标准摘要: 4 列竖版布局（上方高级算符/函数、左下数字区、基础算符围绕数字区上方一行及右侧一列）；完整键盘与精简键盘切换；`2nd` 第二功能面板
  - 参考: `calculator_spec.md` §3.1.5 / `calculator_design.md` ADR-CAL-005

### P2-T9: 错误文案本地化
- [x] P2-T9: 错误文案本地化
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T1
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `ScientificCalculatorService` 覆盖除零、负数开平方、对数非正数、括号不匹配、语法错误、阶乘非法等中文错误文案
  - 验收标准摘要: 覆盖除零、负数开平方、对数非正数、括号不匹配、语法错误、阶乘非法等场景
  - 参考: `calculator_spec.md` §3.1.8

---

## 3. Phase 3: 标准立方米-质量 / 单位 / 几何（C-02 / C-03 / C-04）

### P3-T1: 集成 `units_converter`
- [x] P3-T1: 集成 `units_converter`
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T1
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/unit_converter_service.dart` 封装 `units_converter`，覆盖长度、重量、面积、体积、速度 5 类线性单位；时间、角度使用自研线性系数
  - 验收标准摘要: `UnitConverterService` 封装长度、重量、面积、体积、速度、时间、角度 7 类线性单位
  - 参考: `calculator_spec.md` §3.3 / `calculator_design.md` ADR-CAL-002

### P3-T2: 温度转换特殊处理
- [x] P3-T2: 温度转换特殊处理
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T1
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `UnitConverterService._convertTemperature` 实现 °C/°F/K 自研公式，不经过线性换算
  - 验收标准摘要: 自研 °C/°F/K 公式，不依赖 `units_converter` 线性换算
  - 参考: `calculator_spec.md` §3.3.3

### P3-T3: 几何公式库
- [x] P3-T3: 几何公式库
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/geometry_service.dart` 覆盖圆、矩形、长方体、圆柱、圆锥、球、圆筒、棱锥 8 种几何体的面积/表面积/体积计算
  - 验收标准摘要: `GeometryService` 覆盖圆、矩形、长方体、圆柱、圆锥、球、圆筒、棱锥的面积/表面积/体积
  - 参考: `calculator_spec.md` §3.4

### P3-T4: 标准立方米-质量服务
- [x] P3-T4: 标准立方米-质量服务
  - 优先级: P1
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/standard_cubic_mass_service.dart` 内置 7 种气体摩尔质量，支持自定义摩尔质量/标准摩尔体积、双向换算与标准密度推导
  - 验收标准摘要: 内置 7 种气体摩尔质量表；支持自定义摩尔质量/标准摩尔体积；双向换算与标准密度推导
  - 参考: `calculator_spec.md` §3.2 / `calculator_design.md` ADR-CAL-003

### P3-T5: 单位转换页面
- [x] P3-T5: 单位转换页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T2
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/unit_converter_page.dart` 实现类别选择、双单位输入、交换按钮与实时换算
  - 验收标准摘要: 类别选择 + 双单位输入 + 交换按钮；实时换算
  - 参考: `calculator_spec.md` §3.3.2

### P3-T6: 几何计算页面
- [x] P3-T6: 几何计算页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T3
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/geometry_page.dart` 实现几何体选择、动态字段、结果卡片与公式说明展开
  - 验收标准摘要: 几何体选择 + 动态字段 + 结果卡片 + 公式说明展开
  - 参考: `calculator_spec.md` §3.4.2

### P3-T7: 标准立方米-质量页面
- [x] P3-T7: 标准立方米-质量页面
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T4
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/standard_cubic_mass_page.dart` 实现气体类型选择、摩尔质量/标准摩尔体积输入、Nm³/质量双向换算与推导密度显示
  - 验收标准摘要: 气体类型选择 + 摩尔质量/标准摩尔体积输入 + Nm³/质量双向换算
  - 参考: `calculator_spec.md` §3.2

### P3-T8: 输入校验与错误提示
- [x] P3-T8: 输入校验与错误提示
  - 优先级: P1
  - 主导: DEV
  - 依赖: P3-T4, P3-T5, P3-T6
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `GeometryService` 校验尺寸>0、圆筒 R>r、棱锥 n≥3 且整数；`StandardCubicMassService` 校验 M>0、Vm>0、体积/质量≥0；错误通过控制器 `error` 暴露给页面
  - 验收标准摘要: M>0、Vm>0、尺寸>0、圆筒 R>r、棱锥 n≥3 等校验
  - 参考: `calculator_spec.md` §3.2.3 / §3.4.3

---

## 4. Phase 4: 进制与汇率（C-05 / C-06）

### P4-T1: 进制转换服务
- [x] P4-T1: 进制转换服务
  - 优先级: P2
  - 主导: DEV
  - 依赖: 无
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/radix_converter_service.dart` 实现二/八/十/十六互转、整数与有限小数转换、6 种位运算；支持负数与小数截断提示
  - 验收标准摘要: 二/八/十/十六互转；整数与有限小数；位运算（AND/OR/XOR/NOT/<< />>）
  - 参考: `calculator_spec.md` §3.5

### P4-T2: 汇率服务
- [x] P4-T2: 汇率服务
  - 优先级: P2
  - 主导: DEV
  - 依赖: P1-T5
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/exchange_rate_service.dart` 封装 HTTP 请求、缓存读取、离线回退与货币换算；支持自定义源 `{base}` 占位符
  - 验收标准摘要: HTTP 请求、缓存、离线回退、自定义源 `{base}` 占位符替换
  - 参考: `calculator_spec.md` §3.6

### P4-T3: 进制转换页面
- [x] P4-T3: 进制转换页面
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T1
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/radix_converter_page.dart` 实现四进制输入框实时同步、位运算界面；`RadixConverterController` 管理状态与历史记录
  - 验收标准摘要: 四进制输入框实时同步 + 位运算界面
  - 参考: `calculator_spec.md` §3.5.3

### P4-T4: 汇率页面
- [x] P4-T4: 汇率页面
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/exchange_rate_page.dart` 实现货币选择、金额输入、手动刷新、离线缓存提示与实时换算；`ExchangeRateController` 无缓存时自动刷新并持久化
  - 验收标准摘要: 货币选择 + 金额输入 + 刷新按钮 + 离线缓存提示
  - 参考: `calculator_spec.md` §3.6

### P4-T5: 汇率 HTTP 客户端
- [x] P4-T5: 汇率 HTTP 客户端
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/services/exchange_rate_client.dart` 使用 `dio` 请求公开或自定义汇率源，支持 `{base}` 占位符替换、超时与错误处理
  - 验收标准摘要: 使用 `dio`；支持自定义源；错误处理与超时
  - 参考: `calculator_spec.md` §3.6.2

### P4-T6: 汇率缓存持久化
- [x] P4-T6: 汇率缓存持久化
  - 优先级: P2
  - 主导: DEV
  - 依赖: P4-T2
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `CalculatorConfigController.setExchangeRates` 通过 `StorageService` 将汇率缓存持久化到 `module_calculator_config`
  - 验收标准摘要: 通过 `StorageService` 保存；key `module_calculator_exchange_rates`
  - 参考: `calculator_spec.md` §9

---

## 5. Phase 5: 布局、设置、首页仪表盘

### P5-T1: 模块主页框架
- [x] P5-T1: 模块主页框架
  - 优先级: P0
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/calculator_page.dart` 实现顶部计算器类型选择器与 `ResponsiveBuilder` 横竖屏入口
  - 验收标准摘要: 顶部选择器 + `ResponsiveBuilder` 切换横竖屏；使用 `ConsumerWidget`
  - 参考: `calculator_spec.md` §5.1 / §5.2

### P5-T2: 横竖屏布局
- [x] P5-T2: 横竖屏布局
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T1
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: 竖屏单列显示当前计算器，横屏双列展示历史面板，支持 `historyPanelOnLeft` 左右交换
  - 验收标准摘要: 竖屏单列；横屏双列；`historyPanelOnLeft` 控制左右交换
  - 参考: `calculator_spec.md` §5.1

### P5-T3: 历史面板
- [x] P5-T3: 历史面板
  - 优先级: P1
  - 主导: DEV
  - 依赖: P5-T2, P2-T7
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/widgets/calculator_history_panel.dart` 实现横屏固定面板；竖屏通过 `history_page.dart` 全屏查看，最近 20 条
  - 验收标准摘要: 竖屏弹窗/页面；横屏固定面板；最近 20 条
  - 参考: `calculator_spec.md` §5.1

### P5-T4: 模块设置页
- [x] P5-T4: 模块设置页
  - 优先级: P1
  - 主导: DEV
  - 依赖: P1-T7
  - 预估工时: 1.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/pages/calculator_settings_page.dart` 实现小数精度、科学计数法、横屏布局、键盘显示、首页卡片、汇率源、进制位宽、清除历史等设置项
  - 验收标准摘要: 小数精度、科学计数法、横屏布局、键盘显示、首页卡片、汇率源、进制位宽、清除历史
  - 参考: `calculator_spec.md` §6

### P5-T5: 首页快速计算器卡片
- [x] P5-T5: 首页快速计算器卡片
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T6
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/widgets/calculator_dashboard_quick_calc_card.dart` 实现可开关的快速计算器卡片，支持精简算符栏
  - 验收标准摘要: 模块摘要卡片 Widget；可独立开关；支持精简键盘；点击进入模块主页
  - 参考: `calculator_spec.md` §7.1

### P5-T6: 首页历史卡片
- [x] P5-T6: 首页历史卡片
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T5, P5-T5
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/widgets/calculator_dashboard_history_card.dart` 实现最近历史卡片，点击可进入模块
  - 验收标准摘要: 最近 3-5 条历史；点击进入模块并回填
  - 参考: `calculator_spec.md` §7.2

### P5-T7: 更新 `CalculatorModule`
- [x] P5-T7: 更新 `CalculatorModule`
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T1, P5-T4, P5-T5, P5-T6
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/calculator_module.dart` 接入 `summary`、`buildPage`、`buildSettingsPage`、`buildDashboardWidgets`、`initialize`、`dispose`、`exportData`、`importData`
  - 验收标准摘要: 接入 `summary`、`buildPage`、`buildSettingsPage`、`initialize`、`dispose`、`exportData`、`importData`
  - 参考: `calculator_spec.md` §8

### P5-T8: 键盘显示开关联动
- [x] P5-T8: 键盘显示开关联动
  - 优先级: P1
  - 主导: DEV
  - 依赖: P2-T8, P5-T4
  - 预估工时: 0.5 天
  - 状态: 已完成
  - 实际结果: `lib/features/calculator/widgets/scientific_keypad.dart` 根据 `showFullKeyboard` 动态切换完整/精简键盘布局；`calculator_dashboard_quick_calc_card.dart` 同步显示精简算符栏
  - 验收标准摘要: 关闭 `showFullKeyboard` 后数字键隐藏、算符键保留、页面正确刷新
  - 参考: `calculator_spec.md` §5.4

---

## 6. Phase 6: 模块契约接入与集成验证

### P6-T1: 独立运行验证
- [x] P6-T1: 独立运行验证
  - 优先级: P0
  - 主导: DEV
  - 依赖: P5-T7
  - 预估工时: 1 天
  - 状态: 已完成
  - 实际结果: `flutter analyze` 0 问题；`flutter test` 276 通过 1 跳过；`flutter build windows --debug` 成功生成 `build\\windows\\x64\\runner\\Debug\\calculator_module.exe`
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

- [x] **M1: 配置模型就绪**
  - 目标日期: Phase 1 完成
  - 验收条件: P1-T1 ~ P1-T8 完成，`flutter test` 通过，配置模型 JSON 往返一致
  - 状态: 已达到

- [x] **M2: 科学计算器可用**
  - 目标日期: Phase 2 完成
  - 验收条件: P2-T1 ~ P2-T9 完成，12+ 项核心计算测试通过
  - 状态: 已达到

- [x] **M3: P1 计算能力完成**
  - 目标日期: Phase 3 完成
  - 验收条件: P3-T1 ~ P3-T8 完成，标准立方米-质量、单位、几何服务测试通过
  - 状态: 已达到

- [x] **M4: P2 计算能力完成**
  - 目标日期: Phase 4 完成
  - 验收条件: P4-T1 ~ P4-T6 完成，进制与汇率服务测试通过
  - 状态: 已达到

- [x] **M5: UI/设置/首页完成**
  - 目标日期: Phase 5 完成
  - 验收条件: P5-T1 ~ P5-T8 完成，Widget 测试覆盖横竖屏与设置持久化
  - 状态: 已达到

- [ ] **M6: 集成验收通过**
  - 目标日期: Phase 6 完成
  - 验收条件: P6-T1 ~ P6-T4 完成，底座运行正常，仅注册表与 pubspec 变更
  - 状态: 未达到

---

## 8. 本周任务

> 当前聚焦任务，用于快速查看与每日更新

- [x] **Phase 6-T1 完成：独立运行验证**
  - 优先级: P0
  - 状态: 已完成
  - 负责人: DEV
  - 交付物: `flutter analyze` 0 问题、`flutter test` 276 通过 1 跳过、`flutter build windows --debug` 通过
  - 前置条件: Phase 5 完成
  - 下一步: 进入 P6-T2（主项目注册）

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

- **最后更新**: 2026-08-05
- **更新说明**: Phase 6-T1 独立运行验证完成；`flutter analyze` 0 问题，`flutter test` 276 通过 1 跳过，`flutter build windows --debug` 成功生成 `calculator_module.exe`；项目状态进入 Phase 6（模块契约接入与集成验证），进度 40 / 43（93%）
- **2026-08-05**: Phase 5（P5-T1 ~ P5-T8）全部完成；实现模块主页框架、横竖屏布局、历史面板、模块设置页、首页快速计算器/历史卡片、`CalculatorModule` 契约更新与键盘显示开关联动；修复 `summary` 默认返回值与新增测试断言不一致的问题；`flutter analyze` 0 问题，`flutter test` 276 通过 1 跳过（行覆盖率 ≥80%）
- **2026-08-03**: Phase 4（P4-T1 ~ P4-T6）全部完成；修复 `ExchangeRateController` 无缓存时无法立即换算的问题（新增 `didInitialize` 自动刷新）；修复 `RadixConverterController` 位运算测试与默认十进制进制的对齐问题（切换进制时自动转换操作数值）；`flutter analyze` 0 问题，`flutter test` 237 通过 1 跳过，行覆盖率 82.99%（≥80%）
- **2026-08-01**: Phase 3（P3-T1 ~ P3-T8）全部完成并通过 `flutter analyze` / `flutter test` 验证；修正控制器测试中断言类型（字符串结果误用 `closeTo` 数值比较）
- **2026-08-01**: Phase 2（P2-T1 ~ P2-T9）全部完成并通过 `flutter analyze` / `flutter test` 验证；修复 `ContextModel` 未注入 `pi` 与 `e` 导致的 RAD 三角函数及 `ln(e)` 失败；移除调试 `print`
- **2026-07-31**: 按 `calculator_plan.md` 拆分 Phase 1-6 任务，建立子项目独立 todo 清单，对齐 `guide.md` 七步工作流与 `project_constraints.md` 模块契约约束
- **2026-07-31**: 文件重命名为 `calculator_todo.md`，与主线 `todo.md` 作命名区分