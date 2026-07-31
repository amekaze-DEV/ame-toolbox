# 多功能计算器模块 — 开发测试计划（细化版）

> **文档类型**: 子项目开发与测试计划（Agent-Readable）
> **关联规范**: `calculator_spec.md`
> **模块 ID**: `calculator`
> **版本**: v1.1
> **状态**: 待开发

---

## 1. 计划概览

### 1.1 目标

在独立子项目 `modules/calculator/` 中完成多功能计算器的全部功能开发、单元测试与 Widget 测试，确保模块可脱离底座独立运行；最终通过 `ModuleContract` 接入主项目，**不修改底座 APP 代码**。

### 1.2 需求追溯与阶段映射

| 需求 ID | 需求摘要 | 负责阶段 |
|---------|----------|----------|
| [REQ-A3] / [REQ-A5] | 配置模型、不修改底座 | Phase 1 |
| [REQ-F1] | 科学计算器 | Phase 2 |
| [REQ-F2] / [REQ-F3] / [REQ-F4] | 标准立方米-质量、单位、几何 | Phase 3 |
| [REQ-F5] / [REQ-F6] | 进制、汇率 | Phase 4 |
| [REQ-A1] / [REQ-A2] / [REQ-A3] / [REQ-A4] | 布局、设置、首页仪表盘 | Phase 5 |
| [REQ-A5] | 模块契约接入 | Phase 6 |

### 1.3 阶段划分

| 阶段 | 目标 | 预计文件数 | 验收门槛 |
|------|------|-----------|----------|
| Phase 1 | 基础设施与配置模型 | 8+ | `flutter test` 通过，配置模型 JSON 往返一致 |
| Phase 2 | 科学计算器（P0） | 10+ | 12+ 项核心计算测试通过 |
| Phase 3 | 标准立方米-质量 / 单位 / 几何（P1） | 12+ | 三类服务测试通过 |
| Phase 4 | 进制与汇率（P2） | 8+ | 网络 mock 与进制测试通过 |
| Phase 5 | 布局、设置、首页仪表盘 | 10+ | Widget 测试覆盖横竖屏与设置持久化 |
| Phase 6 | 模块契约接入与集成验证 | - | 底座运行正常，仅注册表与 pubspec 变更 |

### 1.4 里程碑

| 里程碑 | 完成标志 | 阶段 |
|--------|----------|------|
| M1：配置模型就绪 | Phase 1 测试通过 | Phase 1 |
| M2：科学计算器可用 | Phase 2 测试通过 | Phase 2 |
| M3：P1 计算能力完成 | Phase 3 测试通过 | Phase 3 |
| M4：P2 计算能力完成 | Phase 4 测试通过 | Phase 4 |
| M5：UI/设置/首页完成 | Phase 5 测试通过 | Phase 5 |
| M6：集成验收通过 | Phase 6 检查项全部通过 | Phase 6 |

---

## 2. Phase 1：基础设施与配置模型

### 2.1 任务清单

| 任务 ID | 任务 | 优先级 | 需求追溯 | 说明 |
|---------|------|--------|----------|------|
| P1-T1 | 更新 `pubspec.yaml` 依赖 | P0 | [REQ-A5] | 添加 `math_expressions`、`units_converter`、`intl`；`dio` 按需添加 |
| P1-T2 | 定义 `CalculatorType` 枚举 | P0 | [REQ-F1]~[REQ-F6] | 6 个计算器类型 |
| P1-T3 | 定义 `CalculatorConfig` | P0 | [REQ-A3] / [REQ-A4] | 含 toJson / fromJson / copyWith |
| P1-T4 | 定义 `CalculationHistory` | P0 | [REQ-F1] | 历史记录模型，含 angleMode |
| P1-T5 | 定义 `ExchangeRateCache` | P1 | [REQ-F6] | 汇率缓存模型 |
| P1-T6 | 实现 `CalculatorConfigRepository` | P0 | [REQ-A3] / [REQ-A5] | 封装 `StorageService` 读写，业务数据 key 前缀 `module_calculator_` |
| P1-T7 | 定义模块级 Riverpod Provider | P0 | [REQ-A5] | `calculatorConfigProvider`、`calculatorConfigRepositoryProvider` |
| P1-T8 | 配置独立运行入口主题 | P1 | [REQ-A5] | `main.dart` 使用 MD3 主题，便于独立验证 |

### 2.2 新增 / 修改文件

```text
modules/calculator/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   └── features/calculator/
│       ├── models/
│       │   ├── calculator_type.dart
│       │   ├── calculator_config.dart
│       │   ├── calculation_history.dart
│       │   └── exchange_rate_cache.dart
│       ├── data/
│       │   └── calculator_config_repository.dart
│       └── providers/
│           └── calculator_config_provider.dart
```

### 2.3 单元测试

```text
test/
├── models/
│   ├── calculator_config_test.dart
│   └── calculation_history_test.dart
└── data/
    └── calculator_config_repository_test.dart
```

**测试用例**：

- [ ] `CalculatorConfig` 默认构造包含正确默认值（currentType=scientific，decimalPrecision=6，showFullKeyboard=true）。
- [ ] `CalculatorConfig` JSON 序列化 / 反序列化往返一致。
- [ ] `CalculatorConfig.copyWith` 修改单个字段不影响其他字段。
- [ ] 历史记录列表超过 20 条时截断为最新 20 条。
- [ ] Repository 首次读取时返回默认配置。
- [ ] Repository 写入配置后再次读取恢复。
- [ ] Repository 写入历史后再次读取保留顺序。

### 2.4 验收门槛

- `flutter test` 全部通过。
- `flutter analyze` 无错误。

---

## 3. Phase 2：科学计算器（C-01）

### 3.1 任务清单

| 任务 ID | 任务 | 需求追溯 | 说明 |
|---------|------|----------|------|
| P2-T1 | 集成 `math_expressions` | [REQ-F1] | 封装 `ScientificCalculatorService` |
| P2-T2 | 表达式规范化 | [REQ-F1] | `×` → `*`、`÷` → `/`、去除空格、百分号处理 |
| P2-T3 | 角度模式支持 | [REQ-F1] | DEG/RAD 切换，三角函数角度转换 |
| P2-T4 | 结果格式化 | [REQ-A3] | 精度、科学计数法、错误处理 |
| P2-T5 | 历史记录管理 | [REQ-F1] | 添加、查询、清空、上限 20 |
| P2-T6 | 科学计算器页面 | [REQ-F1] | 显示区 + 键盘 + 类型切换 |
| P2-T7 | 历史详情页 | [REQ-A1] | 竖屏全屏历史页 |
| P2-T8 | 键盘布局 | [REQ-A3] | 完整键盘与精简键盘 |
| P2-T9 | 错误文案本地化 | [REQ-F1] | 统一错误提示 |

### 3.2 新增 / 修改文件

```text
lib/features/calculator/
├── services/
│   ├── scientific_calculator_service.dart
│   └── expression_formatter.dart
├── providers/
│   └── scientific_calculator_provider.dart
├── pages/
│   ├── scientific_calculator_page.dart
│   └── history_page.dart
└── widgets/
│   ├── scientific_keypad.dart
│   ├── expression_display.dart
│   └── history_list.dart
```

### 3.3 单元测试

| 测试文件 | 覆盖内容 |
|----------|----------|
| `scientific_calculator_service_test.dart` | 四则运算、函数、括号、错误、角度模式 |
| `expression_formatter_test.dart` | 精度、科学计数法、Error 显示 |
| `history_manager_test.dart` | 增删、上限、回填 |

**测试用例**：

- [ ] `1+2*3` = 7
- [ ] `(1+2)*3` = 9
- [ ] `2^10` = 1024
- [ ] `sqrt(16)` = 4
- [ ] `sin(30)`（DEG）≈ 0.5
- [ ] `sin(pi/2)`（RAD）≈ 1
- [ ] `log(100)` = 2
- [ ] `ln(e)` = 1
- [ ] `fac(5)` = 120
- [ ] `sqrt(-1)` 抛出错误
- [ ] `1/0` 抛出错误
- [ ] `1++2` 抛出错误
- [ ] 科学计数法显示 `123456789` 为 `1.234568E+8`
- [ ] 添加 25 条历史后保留最近 20 条。

### 3.4 验收门槛

- 12+ 项科学计算测试通过。
- 竖屏历史页可进入、可清空、可点击回填。

---

## 4. Phase 3：标准立方米-质量 / 单位 / 几何（C-02 / C-03 / C-04）

### 4.1 任务清单

| 任务 ID | 任务 | 需求追溯 | 说明 |
|---------|------|----------|------|
| P3-T1 | 集成 `units_converter` | [REQ-F3] | 封装 `UnitConverterService`，覆盖 7 类线性单位 |
| P3-T2 | 温度转换特殊处理 | [REQ-F3] | 自研 °C/°F/K 公式 |
| P3-T3 | 几何公式库 | [REQ-F4] | 圆、矩形、长方体、圆柱、圆锥、球、圆筒、棱锥 |
| P3-T4 | 标准立方米-质量服务 | [REQ-F2] | 内置气体摩尔质量表 + 自定义摩尔质量/标准摩尔体积 + 单位换算 |
| P3-T5 | 单位转换页面 | [REQ-F3] | 类别选择 + 双单位输入 + 交换按钮 |
| P3-T6 | 几何计算页面 | [REQ-F4] | 几何体选择 + 动态字段 + 公式说明 |
| P3-T7 | 标准立方米-质量页面 | [REQ-F2] | 气体类型选择 + 摩尔质量/标准摩尔体积 + Nm³/质量双向换算 |
| P3-T8 | 输入校验与错误提示 | [REQ-F2] / [REQ-F4] | 摩尔质量 > 0、Vm > 0、尺寸 > 0、R>r 等 |

### 4.2 新增 / 修改文件

```text
lib/features/calculator/
├── services/
│   ├── unit_converter_service.dart
│   ├── geometry_service.dart
│   └── standard_cubic_mass_service.dart
├── pages/
│   ├── unit_converter_page.dart
│   ├── geometry_calculator_page.dart
│   └── standard_cubic_mass_page.dart
└── widgets/
│   ├── unit_selector.dart
│   ├── geometry_input_form.dart
│   └── gas_selector.dart
```

### 4.3 单元测试

| 测试文件 | 覆盖内容 |
|----------|----------|
| `unit_converter_service_test.dart` | 长度、重量、温度、面积、体积、速度、时间、角度 |
| `geometry_service_test.dart` | 各几何体面积 / 体积 / 表面积 |
| `standard_cubic_mass_service_test.dart` | 内置气体摩尔质量、自定义摩尔质量/Vm、单位换算 |

**测试用例**：

- [ ] 1 m = 100 cm
- [ ] 1 kg = 1000 g
- [ ] 0 °C = 32 °F = 273.15 K
- [ ] 100 °C = 212 °F
- [ ] 半径 2 的圆面积 ≈ 12.566
- [ ] 半径 2 的圆周长 ≈ 12.566
- [ ] 圆柱 r=3, h=5 体积 ≈ 141.372
- [ ] 圆柱 r=3, h=5 表面积 ≈ 150.796
- [ ] 球 r=3 体积 ≈ 113.097
- [ ] 1 Nm³ 甲烷（M=16.04, Vm=22.414）≈ 0.716 kg
- [ ] 1 Nm³ 空气（M=28.97, Vm=22.414）≈ 1.293 kg
- [ ] 1000 L 甲烷 ≈ 0.716 kg
- [ ] 10 kg 甲烷 ≈ 13.97 Nm³
- [ ] 自定义 M=30 g/mol, Vm=24 L/mol，2 Nm³ = 2.5 kg
- [ ] 推导标准密度 ρ = M / Vm 计算正确

### 4.4 验收门槛

- 三类服务测试全部通过。
- 三个页面可在独立运行入口切换并正确计算。

---

## 5. Phase 4：进制与汇率（C-05 / C-06）

### 5.1 任务清单

| 任务 ID | 任务 | 需求追溯 | 说明 |
|---------|------|----------|------|
| P4-T1 | 进制转换服务 | [REQ-F5] | 二 / 八 / 十 / 十六互转、位运算 |
| P4-T2 | 汇率服务 | [REQ-F6] | HTTP 请求、缓存、离线回退 |
| P4-T3 | 进制转换页面 | [REQ-F5] | 四进制输入 + 位运算 |
| P4-T4 | 汇率页面 | [REQ-F6] | 货币选择 + 刷新按钮 |
| P4-T5 | 汇率 HTTP 客户端 | [REQ-F6] | 使用 `dio`，支持自定义源 |
| P4-T6 | 汇率缓存持久化 | [REQ-F6] | 通过 `StorageService` 保存 |

### 5.2 新增 / 修改文件

```text
lib/features/calculator/
├── services/
│   ├── radix_converter_service.dart
│   └── exchange_rate_service.dart
├── pages/
│   ├── radix_converter_page.dart
│   └── exchange_rate_page.dart
└── widgets/
│   ├── radix_display.dart
│   └── currency_selector.dart
```

### 5.3 单元测试

| 测试文件 | 覆盖内容 |
|----------|----------|
| `radix_converter_service_test.dart` | 进制互转、位运算、错误输入 |
| `exchange_rate_service_test.dart` | Mock 网络、缓存读取、离线使用 |

**测试用例**：

- [ ] `0b1010` = 十进制 10 = 八进制 `0o12` = 十六进制 `0xA`
- [ ] `0xFF` 与 `0x0F` 按位与 = `0x0F`
- [ ] `0xFF` 按位取反（8 位）= `0x00`
- [ ] 十进制 0.5 转二进制 = `0b0.1`
- [ ] 自定义汇率源地址 `{base}` 被正确替换为 `USD`。
- [ ] 网络失败时返回缓存汇率并标记离线。
- [ ] 无缓存且网络失败时返回错误状态。

### 5.4 验收门槛

- 进制与汇率服务测试通过。
- 汇率页面可手动刷新，离线时显示缓存提示。

---

## 6. Phase 5：布局、设置、首页仪表盘

### 6.1 任务清单

| 任务 ID | 任务 | 需求追溯 | 说明 |
|---------|------|----------|------|
| P5-T1 | 模块主页框架 | [REQ-A1] / [REQ-A2] | 顶部选择器 + `ResponsiveBuilder` 切换横竖屏 |
| P5-T2 | 横竖屏布局 | [REQ-A1] | 竖屏单列、横屏双列可交换 |
| P5-T3 | 历史面板 | [REQ-A1] | 竖屏弹窗/页面、横屏固定面板 |
| P5-T4 | 模块设置页 | [REQ-A3] / [REQ-A4] | `CalculatorModule.buildSettingsPage` |
| P5-T5 | 首页快速计算器卡片 | [REQ-A4] | 模块摘要卡片 Widget |
| P5-T6 | 首页历史卡片 | [REQ-A4] | 最近历史展示 Widget |
| P5-T7 | 更新 `CalculatorModule` | [REQ-A5] | 接入 summary、buildPage、buildSettingsPage、import/export |
| P5-T8 | 键盘显示开关联动 | [REQ-A3] | 隐藏数字键后页面正确刷新 |

### 6.2 新增 / 修改文件

```text
lib/features/calculator/
├── calculator_module.dart          # 模块契约入口
├── pages/
│   ├── calculator_home_page.dart   # 模块主页
│   ├── history_page.dart           # 历史详情页
│   └── settings_page.dart          # 模块设置页
├── widgets/
│   ├── calculator_type_selector.dart
│   ├── result_display.dart
│   ├── landscape_layout.dart
│   ├── portrait_layout.dart
│   ├── history_panel.dart
│   ├── quick_calculator_card.dart
│   └── recent_history_card.dart
└── providers/
    └── calculator_config_provider.dart
```

### 6.3 Widget / 集成测试

| 测试文件 | 覆盖内容 |
|----------|----------|
| `calculator_home_page_test.dart` | 切换计算器类型、横竖屏布局、历史入口 |
| `settings_page_test.dart` | 设置项变更持久化 |
| `quick_calculator_card_test.dart` | 首页卡片计算与回填 |
| `recent_history_card_test.dart` | 首页历史展示 |

**测试用例**：

- [ ] 切换计算器类型后页面主体变更。
- [ ] 横屏下显示两列布局，历史面板在右侧。
- [ ] 设置 `historyPanelOnLeft=true` 后横屏历史面板在左侧。
- [ ] 竖屏下科学计算器显示历史入口按钮，横屏不显示。
- [ ] 修改小数精度后，计算结果按新精度显示。
- [ ] 关闭“键盘显示”后，数字键隐藏，算符键保留。
- [ ] 首页快速计算器卡片输入 `2+3` 显示结果 `5`。
- [ ] 首页历史卡片显示最近历史并支持点击进入模块。

### 6.4 验收门槛

- Widget 测试覆盖竖屏、横屏、设置持久化、首页卡片。
- 模块在独立运行入口可完整运行所有计算器。

---

## 7. Phase 6：模块契约接入与集成验证

### 7.1 合并清单

1. 保持 `modules/calculator/` 子项目目录不变，通过主项目 `pubspec.yaml` 的 path 依赖引入：
   ```yaml
   dependencies:
     calculator:
       path: modules/calculator
   ```
2. 修改主项目 `lib/core/modules/module_registry.dart`，将 `calculator` 占位模块替换为 `CalculatorModule()`。
3. 在主项目 `pubspec.yaml` 中添加模块新增依赖（`math_expressions`、`units_converter`、`intl`；`dio` 按需）。
4. 确认模块 import 路径：模块内部统一使用 `package:ametoolbox/...` 访问底座，使用相对路径访问模块内部文件；合并后无需移动模块源码。

> **约束**：除 `module_registry.dart` 与主项目 `pubspec.yaml` 外，不得修改底座其他任何文件。

### 7.2 集成测试

| 检查项 | 验证方式 | 需求追溯 |
|--------|----------|----------|
| 模块出现在导航栏 | 启动 App，检查导航栏是否有“多功能计算器” | [REQ-A5] |
| 模块主页可进入 | 点击导航栏项，进入模块主页 | [REQ-A5] |
| 横竖屏切换 | 拖拽窗口改变宽高比，检查布局切换 | [REQ-A1] |
| 设置页可进入 | 设置 → 模块设置 → 多功能计算器 | [REQ-A3] |
| 首页卡片显示 | 主页显示快速计算器 / 历史卡片 | [REQ-A4] |
| WebDAV 同步 | 触发同步后，模块配置与历史被导出 / 导入 | [REQ-A5] |
| 不修改底座代码 | 对比 `git diff`，仅注册表与 pubspec 变更 | [REQ-A5] |

### 7.3 验收门槛

- 集成测试 7 项全部通过。
- `flutter build windows --debug` 成功。

---

## 8. 角色分工（RACI）

| 任务 | OWNER | ARCH | DEV | QA |
|------|-------|------|-----|-----|
| 需求细化与规范编写 | A | C | R | C |
| Phase 1 基础设施 | I | C | R | C |
| Phase 2 科学计算器 | A | C | R | C |
| Phase 3 单位 / 几何 / 标准立方米-质量 | A | I | R | C |
| Phase 4 进制 / 汇率 | A | I | R | C |
| Phase 5 布局与设置 | A | C | R | C |
| Phase 6 集成验证 | A | C | C | R |

> A=Accountable, R=Responsible, C=Consulted, I=Informed

---

## 9. 风险与应对

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| `math_expressions` 不支持 `×`、`÷` 等显示符号 | 中 | 高 | 在 `ScientificCalculatorService` 前做符号规范化 |
| `units_converter` 温度换算精度问题 | 低 | 中 | 温度完全自研，不依赖包的线性换算 |
| 公开汇率 API 不稳定或限流 | 中 | 中 | 支持自定义源，离线缓存兜底，默认源可替换 |
| 横竖屏布局复杂，Widget 测试覆盖不足 | 中 | 中 | 使用 `ResponsiveBuilder`，为两种布局写独立 Widget 测试 |
| 模块依赖与底座版本冲突 | 低 | 低 | 隔离环境先验证 `pubspec.lock`，合并前检查版本兼容性 |
| `CalculatorModule` 合并后 import 路径错误 | 中 | 中 | 模块内部统一使用 `package:ametoolbox/...` 引用底座，避免相对路径跨包 |

---

## 10. 测试策略总结

| 测试层级 | 工具 | 覆盖范围 | 目标 |
|----------|------|----------|------|
| 单元测试 | `flutter_test` | Services、Models、Repository | 覆盖率 ≥ 80% |
| Widget 测试 | `flutter_test` | Pages、Cards、Layout | 覆盖主要交互路径 |
| 集成测试 | 手动 + `flutter drive`（可选） | 底座导航、设置、同步 | Phase 6 检查项 |
| 静态分析 | `flutter analyze` | 全模块 | 0 错误、0 警告 |

---

## 11. 开发环境指令

```bash
# 进入隔离开发环境
cd modules/calculator

# 安装依赖
flutter pub get

# 运行单元测试与 Widget 测试
flutter test

# 静态分析
flutter analyze

# 独立运行（Windows 调试）
flutter run -d windows

# 构建验证
flutter build windows --debug
```
