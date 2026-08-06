# AMEToolbox 项目约束性规范文件

> **文档类型**: Agent-Readable Constraint Specification
> **版本**: v1.0
> **日期**: 2026-07-28
> **来源**: `modular_tool_app_spec.md` v0.7 + `ametoolbox-project-init.html` 项目立项报告
> **状态**: 已定稿，约束双方（主项目底座 + 子项目模块）均须遵守

---

## 1. 项目标识

| 属性 | 值 |
|------|-----|
| 项目名称 | AMEToolbox（模块化工具 APP） |
| 英文名称 | AMEToolbox — Modular Tool Application |
| 项目代号 | AME-TOOL |
| 文档编号 | AME-PROJ-001 |
| 技术栈 | Flutter + Dart + Riverpod |
| UI 规范 | Google Material Design 3 (MD3) |
| 首发平台 | Windows |
| 架构模式 | 主项目（APP 底座）+ 子项目（功能模块）分层架构 |
| 状态管理 | Riverpod（编译时安全，无需 BuildContext，独立可测试） |
| 数据同步 | WebDAV 协议（RFC 4918），无内置用户体系 |
| 首版模块 | 计数器、计时器、检查表（3 个，均默认启用） |

---

## 2. 刚性技术约束（不可更改）

以下约束由需求方明确指定，主项目与子项目均须严格遵守，**不可更改**。

| 约束ID | 约束名称 | 要求 | 说明 | 违规示例 |
|--------|----------|------|------|----------|
| C-001 | UI 设计规范 | Google Material Design 3 (MD3) | 遵循 MD3 组件样式、动效规范、色彩系统 | 使用 Cupertino 风格组件 |
| C-002 | 技术架构 | Flutter | 使用 Flutter 跨平台框架，一套代码覆盖所有目标平台 | 引入平台原生代码（Kotlin/Swift） |
| C-003 | 多平台支持 | Windows、macOS、HarmonyOS、Android、iOS | 初始版本以 Windows 为首发平台；UI 层不使用任何平台专有 API，确保后续移植到其他平台时无需修改 UI 代码 | 在 UI 层使用 `Platform.isWindows` |
| C-004 | 输入方式适配 | 触控 + 键鼠双模式 | 所有交互组件同时适配触控操作（点击/滑动/长按）和桌面键鼠操作（点击/悬停/右键/键盘快捷键）。通过输入模式判定自动切换交互行为，用户无感 | 仅适配触控，键鼠下无法使用右键菜单 |
| C-005 | UI 可移植性 | UI 层与平台层完全解耦 | `lib/features/` 和 `lib/shared/` 下的所有 Widget 代码不含任何 `Platform.is*` 判断或 `dart:io` 平台 API 调用。平台差异通过 `lib/core/platform/` 抽象层注入 | 模块代码中直接调用 `Platform.isWindows` |
| C-006 | 用户体系 | 无内置用户体系 | AMEToolbox 自身不设登录/注册；数据以 WebDAV 账号维度存储，同一 WebDAV 账号（服务器地址+用户名+密码）下的所有设备共享同一套 APP 数据 | 引入 AMEToolbox 自有账号系统（如 Firebase Auth、自建登录） |
| C-007 | 数据同步 | WebDAV 协议 | 支持自建 WebDAV 服务器，适配工厂内网 | 依赖云端同步服务（如 iCloud、Google Drive） |
| C-008 | 状态管理 | Riverpod | 使用 `ConsumerWidget` + `ref.watch/read` 模式管理状态 | 使用 `setState` + `InheritedWidget` 或 GetX/Bloc 等其他方案 |
| C-009 | 布局适配 | 响应式断点机制 | 使用底座 `ResponsiveBuilder` 适配横竖屏，不使用自定义屏幕判定逻辑 | 固定宽度/高度，或自行计算横竖屏 |
| C-010 | 数据存储 | 通过 `StorageService` 抽象接口 | 所有数据读写通过 `StorageService` 抽象层，不得直接访问 Hive 或文件系统 | 直接调用 `File('path').readAsString()` |

---

## 3. UI 可移植性约束细则

为确保 UI 代码无需修改即可跨平台移植，所有代码（主项目 + 子项目）必须遵守以下规则：

| 规则ID | 规则 | 说明 | 违规示例 |
|--------|------|------|----------|
| P-001 | 禁止在 UI 层使用 `Platform.is*` | 平台判断通过 `PlatformInfo` 抽象注入 | `if (Platform.isWindows) Text('Win')` |
| P-002 | 禁止在 UI 层直接调用 `dart:io` | 文件/路径等操作通过 `StorageService` 抽象 | `File('path').readAsString()` |
| P-003 | 禁止使用平台专有插件 | 仅使用支持多平台的 Flutter 插件 | `windows_taskbar` 等专有插件 |
| P-004 | 尺寸单位使用逻辑像素 | 不使用物理像素或平台专有单位 | `MediaQuery.devicePixelRatio` 硬编码 |
| P-005 | 交互组件封装为自适应组件 | 同一组件根据 `InputMode` 自动调整交互行为 | 为触控和键鼠各写一套 Widget |

---

## 4. 数据模型定义

### 4.1 ModuleDefinition（模块定义）

```dart
class ModuleDefinition {
  final String id;           // 唯一标识，如 "counter"
  final String name;         // 显示名称，如 "计数器"
  final String? description; // 一行简要说明
  final String iconName;     // MD3 图标标识
  final bool defaultEnabled; // 系统预设默认开关状态
}
```

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `id` | `String` | 模块唯一标识符 | `"counter"` |
| `name` | `String` | 模块显示名称 | `"计数器"` |
| `description` | `String?` | 一行简要说明 | `"产线计数、批次记录"` |
| `iconName` | `String` | MD3 图标标识符 | `"counter"` |
| `defaultEnabled` | `bool` | 系统预设默认开关状态 | `true` |

### 4.2 ModuleState（模块启用状态）

```dart
class ModuleState {
  final String moduleId;     // 关联 ModuleDefinition.id
  bool enabled;              // 当前是否启用
  int displayOrder;          // 在导航栏/主页中的排列顺序
}
```

| 字段 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `moduleId` | `String` | 关联 `ModuleDefinition.id` | `"counter"` |
| `enabled` | `bool` | 当前是否启用 | `true` |
| `displayOrder` | `int` | 在导航栏/主页中的排列顺序 | `0` |

### 4.3 LayoutConfig（布局配置）

```dart
class LayoutConfig {
  // ── 断点（横竖屏切换阈值）──
  bool autoBreakpoint;       // 自动断点模式，默认 true
  double breakpoint;         // 手动断点值（仅 autoBreakpoint=false 时生效），默认 1.20

  // ── DPI 缩放 ──
  bool autoDpi;              // 自动 DPI 模式，默认 true
  double dpiScale;           // 手动 DPI 缩放因子（仅 autoDpi=false 时生效），默认 1.0
}

// breakpoint 范围: 1.00 - 2.00, 步进 0.05
// dpiScale 范围: 0.8 - 1.5, 步进 0.1
```

| 字段 | 类型 | 范围 | 默认值 | 说明 |
|------|------|------|--------|------|
| `autoBreakpoint` | `bool` | `true`/`false` | `true` | 自动断点模式。开启时根据设备类型+屏幕物理尺寸自动计算最优断点值 |
| `breakpoint` | `double` | `1.00`-`2.00`（步进 0.05） | `1.20` | 手动断点值（仅 `autoBreakpoint=false` 时生效） |
| `autoDpi` | `bool` | `true`/`false` | `true` | 自动 DPI 模式。开启时桌面端根据系统 DPI 自动计算缩放 |
| `dpiScale` | `double` | `0.8`-`1.5`（步进 0.1） | `1.0` | 手动 DPI 缩放因子（仅 `autoDpi=false` 时生效） |

**自动断点策略**（`autoBreakpoint=true` 时）：
- 手机（短边 < 600dp）：`breakpoint = 1.00`（宽>高即横屏）
- 平板（短边 >= 600dp 且 < 840dp）：`breakpoint = 1.30`（需明显横宽才切横屏）
- 桌面窗口（任意）：`breakpoint = 1.20`（默认阈值，用户拖拽窗口时实时判定）

**自动 DPI 策略**（`autoDpi=true` 时）：
- 桌面端：`dpiScale = clamp(physicalDpi / 96.0, 0.8, 1.5)`
- 移动端：`dpiScale = 1.0`（Flutter 已处理设备像素密度，不做额外缩放）

### 4.4 InputMode（输入模式）

```dart
/// 当前活跃的输入方式，由 InputDetector 自动检测并切换
enum InputMode {
  touch,       // 触控模式：大点击区域、无悬停态、滑动手势优先
  mouse,       // 键鼠模式：精确点击、悬停高亮、右键菜单、键盘快捷键
}
```

| 枚举值 | 说明 | 交互特征 |
|--------|------|----------|
| `touch` | 触控模式 | 大点击区域（最小 48x48dp）、无悬停态、滑动手势优先、长按替代右键 |
| `mouse` | 键鼠模式 | 精确点击、悬停高亮、右键菜单、键盘快捷键、滚轮滚动 |

**判定策略**：
- 检测到 `PointerDownEvent` 且来源为 `touch` → 切换到 `touch`
- 检测到 `PointerHoverEvent` 或 `PointerDownEvent` 且来源为 `mouse` → 切换到 `mouse`
- 桌面平台（Windows/macOS）默认 `mouse`，移动平台（Android/iOS）默认 `touch`
- 首次输入事件后自动切换，之后跟随最近一次输入设备的类型
- 混合设备（如 Windows 触屏笔记本）：根据最近一次输入事件动态切换，防抖 300ms

### 4.5 ThemeConfig（主题配置）

```dart
enum ThemeMode { light, dark }

class ThemeConfig {
  ThemeMode mode;            // 明亮 / 暗黑，默认 light
  String accentColorHex;     // 强调色 HEX 值，默认 "#E85D04"
  double fontScale;          // 字体缩放因子，默认 1.0（范围 0.8-1.5，步进 0.1）
}
```

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `mode` | `ThemeMode` | `light` | 明亮/暗黑模式 |
| `accentColorHex` | `String` | `"#E85D04"` | 强调色 HEX 值，作为 MD3 种子色通过 `ColorScheme.fromSeed()` 生成完整色彩梯度 |
| `fontScale` | `double` | `1.0` | 字体缩放因子，范围 0.8-1.5，步进 0.1 |

**预设强调色**：

| 名称 | HEX 值 | 显示名 |
|------|--------|--------|
| `safety_orange` | `#E85D04` | 安全橙 |
| `industrial_blue` | `#1565C0` | 工业蓝 |
| `safety_green` | `#2D7D46` | 安全绿 |
| `warning_red` | `#C62828` | 警示红 |
| `purple` | `#6A1B9A` | 紫 |
| `yellow` | `#F9A825` | 黄 |

### 4.6 SyncConfig（同步配置）

```dart
enum SyncFrequency { manual, fiveMin, fifteenMin, sixtyMin }

class SyncConfig {
  bool enabled;               // 同步总开关，默认 false。关闭时设置页隐藏 WebDAV 相关选项
  String serverUrl;          // WebDAV 服务器地址
  String username;           // 用户名
  String passwordEncrypted;  // 密码（加密存储）
  SyncFrequency frequency;   // 自动同步频率，默认 fiveMin
  DateTime? lastSyncTime;    // 最近一次成功同步时间
  SyncStatus lastSyncStatus; // 最近一次同步状态
}

enum SyncStatus { idle, syncing, success, failed }
```

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | `bool` | `false` | 同步总开关，关闭时隐藏 WebDAV 相关选项 |
| `serverUrl` | `String` | — | WebDAV 服务器地址 |
| `username` | `String` | — | 用户名 |
| `passwordEncrypted` | `String` | — | 密码（使用 `flutter_secure_storage` 加密存储） |
| `frequency` | `SyncFrequency` | `fiveMin` | 自动同步频率 |
| `lastSyncTime` | `DateTime?` | `null` | 最近一次成功同步时间 |
| `lastSyncStatus` | `SyncStatus` | `idle` | 最近一次同步状态 |

### 4.7 DeviceInfoProvider（系统与设备信息抽象）

```dart
/// 系统与设备信息统一抽象，UI 层通过此接口获取设备/系统信息
/// 实现类在 lib/core/platform/ 下按平台分别实现，不暴露给 UI 层
abstract class DeviceInfoProvider {
  /// 设备唯一标识（用于 WebDAV 同步路径），首次启动生成后持久化
  String get deviceId;

  /// 操作系统名称（如 "Windows 11", "Android 14", "iOS 17"）
  String get osName;

  /// 操作系统版本号
  String get osVersion;

  /// 设备型号/名称（如 "Desktop-ABC123", "Pixel 8", "iPad Pro"）
  String get deviceModel;

  /// 应用版本号（如 "1.0.0"）
  String get appVersion;

  /// 应用构建号
  String get appBuildNumber;

  /// 屏幕物理 DPI（用于自动 DPI 缩放计算）
  double get physicalDpi;

  /// 屏幕物理对角线尺寸（英寸），无法获取时返回 null
  double? get physicalScreenSize;

  /// 设备支持的输入方式（纯触控 / 纯键鼠 / 混合）
  DeviceInputCapability get inputCapability;
}

/// 设备输入能力
enum DeviceInputCapability {
  touchOnly,     // 手机、平板（无键盘）
  mouseOnly,     // 传统桌面
  hybrid,        // 触屏笔记本、平板+键盘套
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `deviceId` | `String` | 设备唯一标识，优先使用平台原生标识，失败时自生成 UUID 并持久化 |
| `osName` | `String` | 操作系统名称，如 `"Windows 11"` |
| `osVersion` | `String` | 操作系统版本号 |
| `deviceModel` | `String` | 设备型号/名称 |
| `appVersion` | `String` | 应用版本号，统一使用 `package_info_plus` 获取 |
| `appBuildNumber` | `String` | 应用构建号 |
| `physicalDpi` | `double` | 屏幕物理 DPI，桌面端通过窗口 API 获取，移动端通过设备 API 获取 |
| `physicalScreenSize` | `double?` | 屏幕物理对角线尺寸（英寸） |
| `inputCapability` | `DeviceInputCapability` | 设备支持的输入方式 |

### 4.8 ModuleContract（模块契约接口）

```dart
/// 功能模块契约接口——子项目必须实现
/// 定义在 lib/core/modules/module_contract.dart
abstract class ModuleContract {
  /// 模块定义信息（id、名称、图标、默认开关）
  ModuleDefinition get definition;

  /// 模块主页 Widget（用户点击导航栏后进入的页面）
  /// 必须是 ConsumerWidget，通过 ref 读取底座状态
  Widget buildPage(BuildContext context, WidgetRef ref);

  /// 主页卡片摘要数据（显示在主页模块卡片上）
  ModuleSummary get summary;

  /// 模块初始化（应用启动时调用，用于加载模块本地数据）
  Future<void> initialize(StorageService storage);

  /// 模块销毁清理（模块被关闭时调用）
  Future<void> dispose();

  /// 模块数据导出（用于 WebDAV 同步）
  /// 返回模块所有需要同步的数据，key 为数据标识
  Map<String, dynamic> exportData();

  /// 模块数据导入（用于 WebDAV 同步恢复）
  void importData(Map<String, dynamic> data);
}

/// 模块摘要数据
class ModuleSummary {
  final String label;   // 如 "今日产线计数"
  final String value;   // 如 "1,248"
  final String? unit;   // 如 "件"（可选）

  const ModuleSummary({required this.label, required this.value, this.unit});
}
```

| 方法/属性 | 返回类型 | 说明 |
|-----------|----------|------|
| `definition` | `ModuleDefinition` | 模块定义信息 |
| `buildPage()` | `Widget` | 模块主页 Widget，必须是 `ConsumerWidget` |
| `summary` | `ModuleSummary` | 主页卡片摘要数据 |
| `initialize()` | `Future<void>` | 模块初始化（应用启动时调用） |
| `dispose()` | `Future<void>` | 模块销毁清理（模块被关闭时调用） |
| `exportData()` | `Map<String, dynamic>` | 模块数据导出，用于 WebDAV 同步 |
| `importData()` | `void` | 模块数据导入，用于 WebDAV 同步恢复 |

### 4.9 预设模块清单

| id | name | description | iconName | defaultEnabled |
|----|------|-------------|----------|----------------|
| `counter` | 计数器 | 产线计数、批次记录 | `counter` | `true` |
| `timer` | 计时器 | 工序计时、节拍管控 | `timer` | `true` |
| `checklist` | 检查表 | 设备点检、安全巡检 | `checklist` | `true` |

> **注**: 首发版本预设 3 个模块，均默认启用。模块清单设计为可增减——后续版本可通过更新预设清单代码新增模块，或通过模块管理页面关闭不需要的模块。模块图标暂用标识符占位，后续映射到 MD3 Icons。

---

## 5. 项目结构规范

### 5.1 主项目（APP 底座）目录结构

```
lib/
├── main.dart                          # 应用入口，ProviderScope 包裹
├── app.dart                           # MaterialApp 配置、主题注入、输入模式注入
├── core/
│   ├── constants.dart                 # 预设常量（强调色列表、默认配置值）
│   ├── providers/                     # Riverpod Provider 定义（全局状态声明）
│   │   ├── platform_provider.dart     # PlatformInfo + DeviceInfoProvider 注入
│   │   ├── storage_provider.dart      # StorageService 注入
│   │   ├── theme_provider.dart        # ThemeController 状态
│   │   ├── layout_provider.dart       # LayoutController 状态
│   │   ├── input_provider.dart        # InputController 状态
│   │   └── sync_provider.dart         # SyncService 状态
│   ├── modules/                       # 模块契约层（底座定义，子项目实现）
│   │   ├── module_contract.dart       # ModuleContract 抽象接口
│   │   └── module_registry.dart       # 模块注册表
│   ├── platform/
│   │   ├── platform_info.dart         # 平台信息抽象接口
│   │   ├── platform_info_impl.dart    # 平台检测实现（基于 dart:io，不暴露给 UI 层）
│   │   ├── device_info_provider.dart  # 系统与设备信息抽象接口
│   │   ├── windows_device_info.dart   # Windows 实现
│   │   ├── macos_device_info.dart     # macOS 实现
│   │   ├── android_device_info.dart   # Android 实现
│   │   ├── ios_device_info.dart       # iOS 实现
│   │   └── ohos_device_info.dart      # HarmonyOS 实现
│   ├── input/
│   │   ├── input_controller.dart      # 输入模式状态管理 (ChangeNotifier)
│   │   ├── input_detector.dart        # Pointer 事件监听，自动判定 touch/mouse
│   │   └── input_mode_scope.dart      # InheritedWidget，向子树注入当前 InputMode
│   ├── theme/
│   │   ├── theme_controller.dart      # 主题状态管理 (ChangeNotifier)
│   │   ├── md3_color_scheme.dart      # MD3 ColorScheme 生成器
│   │   └── dpi_scaler.dart            # DPI 缩放 Widget
│   ├── layout/
│   │   ├── layout_controller.dart     # 布局模式判定与状态 (ChangeNotifier)
│   │   └── responsive_builder.dart    # 响应式布局 Widget
│   ├── storage/
│   │   ├── storage_service.dart       # 本地持久化抽象接口
│   │   └── hive_storage.dart          # Hive 实现
│   ├── sync/
│   │   ├── webdav_client.dart         # WebDAV 协议客户端
│   │   ├── sync_service.dart          # 同步调度逻辑
│   │   └── conflict_resolver.dart     # 冲突解决策略
│   └── models/
│       ├── module_definition.dart
│       ├── module_state.dart
│       ├── module_summary.dart
│       ├── layout_config.dart
│       ├── input_mode.dart
│       ├── theme_config.dart
│       └── sync_config.dart
├── features/
│   ├── home/
│   │   ├── home_page.dart             # ConsumerWidget
│   │   ├── module_card_widget.dart    # 自适应模块卡片
│   │   └── sync_status_widget.dart
│   ├── module_management/
│   │   └── module_management_page.dart
│   └── settings/
│       ├── settings_page.dart
│       ├── theme_settings_page.dart
│       ├── layout_settings_page.dart
│       └── sync_settings_page.dart
└── shared/                            # 底座共享组件（子项目可复用）
    ├── widgets/
    │   ├── adaptive_button.dart
    │   ├── adaptive_list_tile.dart
    │   ├── md3_switch.dart
    │   ├── md3_slider.dart
    │   └── settings_list_tile.dart
    └── utils/
        ├── aspect_ratio_helper.dart
        └── input_mode_helper.dart

# ── 子项目（功能模块）──
modules/                                # 子项目根目录，与 lib/ 同级
├── counter/                            # 计数器模块
│   ├── README.md                       # 模块需求说明（引用本规格为约束基线）
│   ├── pubspec.yaml                    # 模块依赖（可选）
│   ├── lib/
│   │   ├── counter_module.dart         # 实现 ModuleContract 入口
│   │   ├── counter_page.dart           # 模块主页 (ConsumerWidget)
│   │   ├── counter_store.dart          # 模块数据模型 + 存储逻辑
│   │   └── widgets/                    # 模块私有组件
│   └── test/
│       └── counter_test.dart           # 模块单元测试
├── timer/
│   ├── README.md
│   ├── lib/
│   │   ├── timer_module.dart
│   │   └── ...
│   └── test/
└── checklist/
    ├── README.md
    ├── lib/
    │   ├── checklist_module.dart
    │   └── ...
    └── test/

# ── 平台专属入口（不含 UI 逻辑，仅配置和注册）──
windows/                               # Windows 平台配置 (首发)
macos/                                 # macOS 平台配置
android/                               # Android 平台配置
ios/                                   # iOS 平台配置
ohos/                                  # HarmonyOS 平台配置（待 Flutter 鸿蒙支持成熟）
```

### 5.2 子项目目录结构规范

```
modules/<module_id>/
├── README.md                       # 模块需求说明（引用底座规格为约束基线）
├── pubspec.yaml                    # 模块依赖（可选，也可共用主项目 pubspec）
├── lib/
│   ├── <module_id>_module.dart     # 实现 ModuleContract 入口
│   ├── <module_id>_page.dart       # 模块主页 (ConsumerWidget)
│   ├── <module_id>_store.dart      # 模块数据模型 + 存储逻辑
│   └── widgets/                    # 模块私有组件
└── test/
    └── <module_id>_test.dart       # 模块单元测试
```

> **注**: 子项目代码物理上位于 `modules/` 目录，通过主项目 `pubspec.yaml` 的 path 依赖或直接 import 引入。模块代码不直接访问 `lib/core/` 之外的底座私有实现，仅通过 `ModuleContract` 接口和 `StorageService` 抽象与底座交互。

---

## 6. 模块契约约束清单

子项目必须遵守以下约束清单（源自 `ModuleContract` 接口定义及第 3.9 节）：

| 约束ID | 约束 | 要求 | 违规示例 |
|--------|------|------|----------|
| M-001 | 技术栈 | Flutter + Riverpod | 使用 GetX / Bloc 等其他状态管理 |
| M-002 | UI 规范 | Material Design 3 | 使用 Cupertino 风格组件 |
| M-003 | 状态管理 | `ConsumerWidget` + `ref.watch/read` | 使用 `setState` + `InheritedWidget` |
| M-004 | 平台抽象 | 不使用 `Platform.is*` / `dart:io` | 模块代码中直接调用 `Platform.isWindows` |
| M-005 | 输入适配 | 使用 `AdaptiveButton` / `AdaptiveListTile` | 直接使用 `IconButton` / `ListTile` |
| M-006 | 主题 | 使用 `Theme.of(context)` 获取配色 | 硬编码颜色值 |
| M-007 | 布局适配 | 使用 `ResponsiveBuilder` 适配横竖屏 | 固定宽度/高度 |
| M-008 | 数据存储 | 通过 `StorageService` 抽象接口 | 直接读写文件系统 |
| M-009 | 数据同步 | 实现 `exportData` / `importData` | 自行实现同步逻辑 |
| M-010 | 图标 | MD3 Material Symbols | 使用自定义图片图标 |
| M-011 | 包依赖 | 仅依赖底座已声明的依赖 + `pubspec.yaml` 中声明的跨平台包 | 依赖平台专有插件 |

---

## 7. 子项目约束基线

所有子项目必须遵守以下约束基线（源自第 8.2 节）：

| 约束项 | 要求 | 参考章节 |
|--------|------|----------|
| 技术栈 | Flutter + Dart，不得引入平台原生代码 | 第 2 节 |
| UI 规范 | Material Design 3，使用底座主题令牌 | 第 3.5 节 |
| 状态管理 | Riverpod，通过 `WidgetRef` 读取底座状态 | 第 5 节 TASK-00 |
| 模块接口 | 实现 `ModuleContract` 抽象类 | 第 3.9 节 |
| 数据存储 | 通过 `StorageService` 抽象层，不得直接访问 Hive | 第 5 节 TASK-01 |
| 平台适配 | 禁止平台判断代码，使用 `DeviceInfoProvider` 获取设备信息 | 第 3.8 节 |
| 输入适配 | 使用底座自适应组件（`AdaptiveButton` 等），不得硬编码触控/键鼠逻辑 | 第 5 节 TASK-08 |
| 布局适配 | 使用底座响应式断点，不得自定义屏幕判定逻辑 | 第 5 节 TASK-03 |
| 数据同步 | 通过 `exportData()` / `importData()` 参与同步，不得自行实现同步逻辑 | 第 3.9 节 |

---

## 8. 开放问题与决策记录

以下问题已在项目过程中提出并确认。标注"已关闭"的问题不再需要讨论，标注"未关闭"的问题需后续确认。

| # | 问题 | 影响任务 | 当前状态 | 决策/假设 |
|---|------|----------|----------|-----------|
| Q1 | 预设模块清单是否确认为 6 个？是否需要增减？ | TASK-02, TASK-05 | **已关闭** | 首发 3 个模块（计数器、计时器、检查表），均默认启用，后续可增减 |
| Q2 | 模块图标准确使用哪套图标库？Material Symbols 还是自定义？ | TASK-02 | **未关闭** | 暂用 MD3 Material Symbols，待最终确认 |
| Q3 | 横屏时导航栏是否从底部切换为侧边 NavigationRail？ | TASK-05 | **已关闭** | 横屏左侧，竖屏底部，空间不足时可滚动 |
| Q4 | WebDAV 后台同步是否需要支持应用未启动时触发？ | TASK-07 | **未关闭** | 当前假设：仅支持前台 Timer，不支持后台 |
| Q5 | 状态管理方案选择 Provider 还是 Riverpod？ | TASK-00 | **已关闭** | 选择 Riverpod，编译时安全 + 无需 BuildContext + 独立可测试 |
| Q6 | 各功能模块的摘要数据接口何时定义？ | TASK-05 | **未关闭** | 当前用占位数据，接口已预留 |
| Q7 | 设备标识方案：ANDROID_ID 还是自生成 UUID？ | TASK-00, TASK-07 | **已关闭** | 通过 `DeviceInfoProvider` 抽象层统一获取，各平台优先使用原生标识，失败时自生成 UUID 持久化 |
| Q8 | Windows 窗口最小尺寸确认为多少？是否需要支持全屏模式？ | TASK-00 | **未关闭** | 假设：最小 400x600，支持自由缩放和最大化 |
| Q9 | 鸿蒙平台是否使用 OpenHarmony Flutter 分支还是等待官方支持？ | TASK-00 | **未关闭** | Phase 4 再定，当前不影响 Windows 开发 |
| Q10 | 键盘快捷键列表是否需要扩充或自定义？ | TASK-08 | **未关闭** | 使用当前 5 组（Esc、Ctrl+S、Ctrl+,、Alt+Left、Tab），后续可扩展 |
| Q11 | Windows 上是否需要系统托盘 (System Tray) 功能？ | TASK-00 | **未关闭** | 首版不做，后续按需添加 |
| Q12 | macOS 平台是否需要支持 Touch Bar？ | TASK-08 | **未关闭** | 不支持，保持与 Windows 一致的交互 |
| Q13 | 横竖屏断点和 DPI 是否支持自动/手动切换？ | TASK-03, TASK-04 | **已关闭** | 均支持自动（默认）和手动模式，自动断点按设备类型判定，自动 DPI 桌面端按系统 DPI 计算 |
| Q14 | 未来新增模块时，是否需要支持模块热更新/远程下载？还是仅通过 App 版本更新？ | TASK-02 | **未关闭** | 仅通过 App 版本更新，模块清单随版本发布 |
| Q15 | 子项目是否需要独立 Git 仓库还是采用 Monorepo 子目录管理？ | 第 8 节 | **未关闭** | 采用 Monorepo 子目录（`modules/`），通过 path 依赖引入 |
| Q16 | 设置页分区结构如何组织？同步和模块设置是否需要总开关？ | TASK-06 | **已关闭** | 分为全局设置、同步设置、模块设置三大分区；同步设置和模块设置各带总开关，关闭时隐藏子项 |
| Q17 | 字体大小是否需要作为全局设置项？范围和步进如何？ | TASK-04, TASK-06 | **已关闭** | 已定，fontScale 0.8-1.5，步进 0.1，见 ThemeConfig |

---

## 9. 角色定义与分工

> 项目性质：**个人项目 + AI Agent 协作**。由 1 名人类开发者担任项目负责人，联合 4 个专业化 AI Agent 协同完成全部工作。角色缩写命名供 Agent 自动解析与分工调度使用。

### 9.1 角色职责矩阵

| 角色 | 缩写 | 类型 | 职责描述 |
|------|------|------|----------|
| **项目负责人** (Owner) | OWNER | 人类 | 最终决策者。负责产品方向、需求确认、优先级排序、里程碑审批、代码最终审查与合并、验收签署 |
| **架构师 Agent** (Architect Agent) | ARCH | AI Agent | 技术架构师。负责技术方案设计、`ModuleContract` 接口定义、技术约束落地检查、代码审查、设计方案评审 |
| **开发 Agent** (Developer Agent) | DEV | AI Agent | 全栈开发。负责 APP 底座开发（TASK-00 ~ TASK-08）+ 功能模块开发（计数器/计时器/检查表），编写单元测试 |
| **质量保障 Agent** (QA Agent) | QA | AI Agent | 质量保障。负责测试计划制定、集成测试用例编写、约束合规性检查、Bug 跟踪与回归测试、测试报告生成 |
| **运维 Agent** (Ops Agent) | OPS | AI Agent | 开发运维。负责 CI/CD 流水线配置、多平台构建管理、版本发布、构建产物管理 |

### 9.2 RACI 责任分配矩阵

| 任务 | OWNER | ARCH | DEV | QA | OPS |
|------|-------|------|-----|-----|-----|
| TASK-00 项目初始化 | A | C | R | I | C |
| TASK-01 存储层 | A | C | R | I | I |
| TASK-02 模块管理 | A | C | R | I | I |
| TASK-03 布局引擎 | A | C | R | I | I |
| TASK-04 主题系统 | A | C | R | I | I |
| TASK-05 导航与主页 | A | C | R | I | I |
| TASK-06 设置页 | A | I | R | I | I |
| TASK-07 WebDAV 同步 | A | C | R | C | I |
| TASK-08 输入适配 | A | C | R | I | I |
| 计数器模块 | A | C | R | C | I |
| 计时器模块 | A | C | R | C | I |
| 检查表模块 | A | C | R | C | I |
| 集成测试 | A | C | C | R | I |
| CI/CD 流水线 | A | C | I | I | R |
| 版本发布 v1.0 | A | C | C | C | R |

> 图例: R = 负责执行 (Responsible), A = 批准决策 (Accountable), C = 咨询 (Consulted), I = 知情 (Informed)
>
> 说明：OWNER 作为唯一人类角色，对所有任务拥有最终批准权（A）；AI Agent 按专业领域承担执行（R）和咨询（C）职责。

### 9.3 各阶段角色投入

| 阶段 | OWNER | ARCH | DEV | QA | OPS |
|------|-------|------|-----|-----|-----|
| Phase A (基础设施) | 高 | 高 | 高 | 低 | 中 |
| Phase B (核心能力) | 中 | 高 | 高 | 低 | 低 |
| Phase C (模块管理) | 中 | 高 | 高 | 中 | 低 |
| Phase D (导航主页) | 高 | 中 | 高 | 中 | 低 |
| Phase E (设置页) | 中 | 中 | 高 | 中 | 中 |
| Phase F (子项目) | 中 | 中 | 高 | 中 | 低 |
| Phase G (集成验收) | 高 | 中 | 中 | 高 | 高 |

> 投入等级：高（核心驱动，大量参与）/ 中（常规协作，定期参与）/ 低（少量介入，按需响应）

---

## 10. 版本管理规则

### 10.1 版本号规范

| 版本号 | 格式 | 说明 |
|--------|------|------|
| 主项目版本 (App Version) | `MAJOR.MINOR.PATCH` | 随 App 整体发布递增。新增模块或底座能力更新时递增 |
| 模块版本 | 各子项目独立维护 | 在 `README.md` 中独立维护版本号。模块变更需同步更新主项目模块清单 |
| 契约版本 | 与 `ModuleContract` 接口版本绑定 | 接口变更属于破坏性变更，需主项目 MINOR 版本递增并通知所有子项目适配 |

### 10.2 发布规则

| 操作 | 版本变更 | 说明 |
|------|----------|------|
| 新增模块 | 主项目 PATCH 递增 | 在 `module_registry.dart` 注册新模块 |
| 移除模块 | 主项目 MINOR 递增 | 从注册表移除，保留已存储数据（向下兼容） |
| 契约变更 | 主项目 MINOR 递增 | 所有已注册子项目须同步适配 |
| Bug 修复 | 主项目 PATCH 递增 | 不涉及接口变更 |
| 底座能力新增 | 主项目 MINOR 递增 | 保持 `ModuleContract` 向下兼容 |

### 10.3 模块清单管理

- 模块清单随 App 版本发布，**不支持单独模块热更新**
- 新增模块流程：在 `module_registry.dart` 注册 + App 版本 PATCH 递增
- 移除模块流程：从注册表移除 + App 版本 MINOR 递增（向下兼容，保留已存储数据）
- 契约变更流程：App 版本 MINOR 递增，所有已注册子项目须同步适配

### 10.4 平台发布阶段

| 阶段 | 平台 | 版本要求 | 说明 |
|------|------|----------|------|
| Phase 1 (首发) | Windows | v1.0 | 桌面键鼠操作为主，窗口可自由缩放，验证 UI 可移植性 |
| Phase 2 | Android + iOS | v1.x | 触控操作为主，验证移动端布局适配和触控交互 |
| Phase 3 | macOS | v1.x | 桌面键鼠 + 触控板，与 Windows 共享桌面端逻辑 |
| Phase 4 | HarmonyOS (鸿蒙) | v2.x | 依赖 Flutter 鸿蒙生态成熟度，可能需要 ohos flutter 分支 |

---

## 附录 A：关键常量定义

```dart
class AppConstants {
  // ── 预设强调色 ──
  static const List<({String name, String hex, String displayName})> presetColors = [
    (name: 'safety_orange',  hex: '#E85D04', displayName: '安全橙'),
    (name: 'industrial_blue', hex: '#1565C0', displayName: '工业蓝'),
    (name: 'safety_green',   hex: '#2D7D46', displayName: '安全绿'),
    (name: 'warning_red',    hex: '#C62828', displayName: '警示红'),
    (name: 'purple',         hex: '#6A1B9A', displayName: '紫'),
    (name: 'yellow',         hex: '#F9A825', displayName: '黄'),
  ];

  // ── 默认配置 ──
  static const bool defaultAutoBreakpoint = true;
  static const bool defaultAutoDpi = true;
  static const double defaultBreakpoint = 1.20;
  static const double defaultDpiScale = 1.0;

  // ── 断点范围 ──
  static const double minBreakpoint = 1.00;
  static const double maxBreakpoint = 2.00;
  static const double breakpointStep = 0.05;

  // ── DPI 范围 ──
  static const double minDpiScale = 0.8;
  static const double maxDpiScale = 1.5;
  static const double dpiStep = 0.1;

  // ── 自动断点判定阈值（按设备短边 dp 划分）──
  static const double phoneMaxShortSide = 600;
  static const double tabletMaxShortSide = 840;
  static const double autoBreakpointPhone = 1.00;
  static const double autoBreakpointTablet = 1.30;
  static const double autoBreakpointDesktop = 1.20;

  // ── 自动 DPI 基准 ──
  static const double desktopBaseDpi = 96.0;
}
```

## 附录 B：交互行为差异对照表

| 交互元素 | 触控模式 (touch) | 键鼠模式 (mouse) |
|----------|------------------|------------------|
| 按钮最小尺寸 | 48x48 dp | 默认尺寸 |
| 列表项高度 | >= 56 dp | >= 48 dp |
| 卡片点击区域 | 整个卡片可点击 | 整个卡片可点击，hover 时边框高亮 |
| 右键菜单 | 不支持（长按替代） | 支持，右键弹出上下文菜单 |
| 滚动方式 | 惯性滑动 | 滚轮滚动 |
| 文本选择 | 长按选择 | 鼠标拖选 |
| 悬停反馈 | 无 | 背景色变化 / 阴影加深 / 边框高亮 |
| 键盘快捷键 | 不适用 | 支持（如 Ctrl+S 同步, Esc 返回） |

## 附录 C：键盘快捷键定义（键鼠模式专用）

| 快捷键 | 功能 | 适用页面 |
|--------|------|----------|
| `Esc` | 返回上一页 | 所有子页面 |
| `Ctrl+S` | 立即同步 | 主页 / 设置页 |
| `Ctrl+,` | 打开设置 | 主页 |
| `Alt+Left` | 导航后退 | 所有页面 |
| `Tab` / `Shift+Tab` | 焦点切换 | 所有页面 |

> 键盘快捷键通过 `Shortcuts` + `Actions` Widget 实现，仅在 `InputMode.mouse` 下激活。触控模式下快捷键不注册，避免影响虚拟键盘行为。