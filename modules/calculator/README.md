# 多功能计算器模块

> **模块 ID**: `calculator`
> **模块名称**: 多功能计算器
> **模块类型**: 子项目（功能模块）
> **约束基线**: `project_constraints.md` + `modular_tool_app_spec.md` + `design.md`
> **规范文档**: `docs/calculator_spec.md`
> **设计规范**: `docs/calculator_design.md`
> **开发计划**: `docs/calculator_plan.md`
> **任务清单**: `calculator_todo.md`
> **版本**: v1.1
> **状态**: 需求与设计阶段已完成，待编码

---

## 1. 模块定位

多功能计算器是 AMEToolbox 的通用计算模块，面向工厂现场的高频换算与估算场景：
产线参数计算、工件几何量估算、气体流量质量换算、货币折算、进制换算等。
模块以**科学计算器**为核心，提供 6 类计算工具，统一在同一页面内切换。

---

## 2. 功能范围

| 编号 | 功能 | 说明 |
|------|------|------|
| C-01 | 科学计算器 | 表达式求值、函数、历史记录、竖版键盘 |
| C-02 | 标准立方米-质量转换 | 基于摩尔质量的气体 Nm³ ↔ 质量换算 |
| C-03 | 单位转换器 | 长度、重量、温度、面积、体积、速度、时间、角度等 8 类单位换算 |
| C-04 | 几何计算器 | 圆锥、圆柱、圆筒、方块、棱锥、方体等面积 / 表面积 / 体积计算 |
| C-05 | 进制转换器 | 二 / 八 / 十 / 十六进制互转、位运算 |
| C-06 | 汇率计算器 | 多货币换算，公开汇率源 + 离线缓存 |

---

## 3. 总体架构要求

1. **横竖屏适配**
   - 竖屏：上方显示计算结果及近期历史，右上角进入历史结果页（保存最近 20 条）。
   - 横屏：分两列显示，左列为计算器，右列为历史结果页面；支持设置交换左右位置。
2. **顶部控制区**
   - 左上角：切换计算器种类的下拉选择框。
   - 科学计数法开关。
   - 竖屏下布局不与历史页面入口拥挤。
3. **设置页选项**
   - 小数精度位数（0-10）。
   - 横屏左右布局切换开关。
   - 键盘显示开关（关闭后主画面隐藏数字键盘，仅保留算符按钮）。
4. **首页仪表盘**
   - 快速计算器卡片（可含/不含键盘）。
   - 最近计算历史卡片。
   - 两个卡片可独立开关并调整顺序。
5. **底座隔离**
   - 开发过程中不修改 APP 底座代码，仅通过 `ModuleContract` 接入。

---

## 4. 遵守的底座约束

| 约束 ID | 约束名称 | 模块落地方式 |
|---------|----------|--------------|
| C-001 | MD3 | 全部使用 `Theme.of(context).colorScheme` 与内置 MD3 组件 |
| C-003 / C-005 | UI 层无平台代码 | 不调用 `Platform.is*` / `dart:io`，通过 Provider 读取底座状态 |
| C-008 | Riverpod | 所有页面继承 `ConsumerWidget`，状态通过 `ref.watch/read` 访问 |
| C-009 | 响应式断点 | 使用底座 `ResponsiveBuilder` / `LayoutMode` 判定横竖屏 |
| C-010 | StorageService | 模块数据通过 `StorageService` 读写，key 前缀 `module_calculator_` |

---

## 5. 依赖

| 包名 | 用途 | 版本 | 许可 |
|------|------|------|------|
| `math_expressions` | 科学表达式解析与求值 | `^2.7.0` | MIT |
| `units_converter` | 线性单位换算 | `^3.0.0` | MIT |
| `intl` | 数字格式化 | `^0.20.0` | BSD-3 |
| `dio` | 汇率 HTTP 请求 | 底座版本 | MIT |
| `ametoolbox` | 复用底座 ModuleContract、StorageService、Provider 等 | path 依赖 | - |

---

## 6. 模块契约

本模块入口类 `CalculatorModule` 实现底座 `ModuleContract` 接口：

```dart
class CalculatorModule implements ModuleContract {
  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'calculator',
        name: '多功能计算器',
        description: '表达式计算、单位换算、几何与汇率计算',
        iconName: 'calculator',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) => const CalculatorHomePage();

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) => const CalculatorSettingsPage();

  @override
  ModuleSummary get summary => ...;

  @override
  Future<void> initialize(StorageService storage) async { ... }

  @override
  Future<void> dispose() async { ... }

  @override
  Map<String, dynamic> exportData() => ...;

  @override
  void importData(Map<String, dynamic> data) { ... }
}
```

---

## 7. 目录结构

```text
modules/calculator/
├── README.md                       # 本文件
├── pubspec.yaml                    # 模块依赖
├── analysis_options.yaml           # 静态分析配置
├── docs/
│   ├── calculator_spec.md          # 详细功能技术规范
│   ├── calculator_design.md        # 设计规范与 ADR
│   └── calculator_plan.md          # 开发测试计划
├── lib/
│   ├── main.dart                   # 独立运行入口
│   └── features/calculator/
│       ├── calculator_module.dart  # ModuleContract 入口
│       ├── models/                 # 数据模型
│       ├── data/                   # Repository（StorageService 封装）
│       ├── providers/              # Riverpod Provider
│       ├── services/               # 业务服务
│       ├── pages/                  # 页面
│       └── widgets/                # 模块私有组件
└── test/                           # 单元测试 / Widget 测试
```

---

## 8. 数据存储约定

- 模块业务数据统一通过 `StorageService` 读写。
- 业务数据 key 前缀：`module_calculator_`。
- 导出给 WebDAV 同步的数据结构：

```text
{
  'module_calculator_config': <CalculatorConfig>,
  'module_calculator_history': <List<CalculationHistory>>,
  'module_calculator_exchange_rates': <ExchangeRateCache>,
}
```

---

## 9. 验收标准

- [ ] 实现 `ModuleContract` 全部方法。
- [ ] 6 类计算器功能完整，符合 `docs/calculator_spec.md` 定义。
- [ ] 横竖屏布局切换正确，横屏历史面板位置可设置交换。
- [ ] 模块设置项生效并持久化。
- [ ] 首页仪表盘快速计算器和历史卡片可独立开关、调整顺序。
- [ ] 单元测试覆盖率 >= 80%，`flutter test` 全部通过。
- [ ] `flutter analyze` 无错误。
- [ ] `flutter build windows --debug` 成功。
- [ ] 不修改 APP 底座代码。

---

## 10. 开发指令

```bash
# 进入模块目录
cd modules/calculator

# 安装依赖
flutter pub get

# 运行测试
flutter test

# 静态分析
flutter analyze

# 独立运行验证
flutter run -d windows
```

---

## 11. 参考文档

- [project_constraints.md](../../project_constraints.md)
- [modular_tool_app_spec.md](../../modular_tool_app_spec.md)
- [design.md](../../design.md)
- [guide.md](../../guide.md)
- [task_assignments.md](../../task_assignments.md)
