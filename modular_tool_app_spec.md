# 模块化工具 APP — 开发规格文档

> **文档类型**: Agent-Readable Development Spec
> **版本**: v0.7 (初稿 + 多平台 + 布局适配 + 模块调整 + 设备信息抽象 + Riverpod + 项目管理 + 设置页重构)
> **日期**: 2026-07-28
> **原始 PRD**: `modular_tool_app_prd.html` (含可交互原型)
> **状态**: 框架层规格 + 项目管理规范，功能模块待补充

---

## 目录

- [1. 产品概览](#1-产品概览)
- [2. 技术约束（刚性）](#2-技术约束刚性)
- [3. 数据模型](#3-数据模型)
- [4. 项目结构建议](#4-项目结构建议)
- [5. 任务拆解](#5-任务拆解)
  - [TASK-00: 项目初始化与基础架构](#task-00-项目初始化与基础架构)
  - [TASK-01: 本地持久化存储层](#task-01-本地持久化存储层)
  - [TASK-02: 模块管理系统](#task-02-模块管理系统)
  - [TASK-03: 响应式布局引擎](#task-03-响应式布局引擎)
  - [TASK-04: 主题与显示设置系统](#task-04-主题与显示设置系统)
  - [TASK-05: 导航与主页](#task-05-导航与主页)
  - [TASK-06: 设置页](#task-06-设置页)
  - [TASK-07: WebDAV 数据同步](#task-07-webdav-数据同步)
  - [TASK-08: 输入模式适配（触控与键鼠）](#task-08-输入模式适配触控与键鼠)
- [6. 任务依赖图](#6-任务依赖图)
- [7. 开放问题](#7-开放问题)
- [8. 项目管理](#8-项目管理)

---

## 1. 产品概览

### 产品定位

面向工厂工人及管理者的模块化工具应用。用户按岗位需要自行启用功能模块，通过 WebDAV 实现无账号体系下的数据同步，全面适配工厂多样的硬件环境与光照条件。

### 核心痛点

| 痛点 | 具体表现 | 影响 |
|------|----------|------|
| 工具分散 | 工人需在多个 App 或纸质表单间切换 | 操作效率低，容易遗漏步骤 |
| 岗位差异大 | 不同岗位需要的工具组合完全不同 | 固定功能应用无法满足 |
| 设备碎片化 | 手机、平板、工业终端，尺寸方向各异 | 现有应用适配差，横竖屏切换错乱 |
| 数据无法归档 | 纸质表单无法数字化保存 | 数据丢失，无法追溯与分析 |

### 需求目标

| 目标 | 衡量方式 |
|------|----------|
| 统一工具平台 | 单一 App 内按需开启功能模块 |
| 多平台覆盖 | 同一套 UI 代码在 Windows、macOS、鸿蒙、Android、iOS 上运行，无需修改 |
| 适配多样硬件 | 手机竖屏、平板横屏、工业终端、桌面窗口均正确布局 |
| 输入方式兼容 | 触控操作和键鼠操作均可完整使用所有功能 |
| 适应工厂光照 | 明暗主题切换 + 配色调整，强光/昏暗均可阅读 |
| 无账号数据同步 | WebDAV 协议同步，不依赖云端账号 |

### 范围说明

本项目采用**主项目 + 子项目**架构：

- **主项目（APP 底座）**：本规格文档覆盖的内容。包括模块管理、导航结构、响应式布局、主题系统、数据同步、平台抽象层、输入适配。主项目定义模块契约接口（第 3.9 节），所有功能模块必须遵守。
- **子项目（功能模块）**：计数器、计时器、检查表等各功能模块。每个模块作为独立子项目，拥有自己的需求文档、开发规划和验收标准。子项目设计必须服从 APP 底座的约束（技术栈、UI 规范、状态管理、平台抽象、输入适配），通过实现模块契约接口接入主项目。

子项目在主项目框架确认后单独编写需求规格，但必须引用本文档作为约束基线。

---

## 2. 技术约束（刚性）

以下约束由需求方明确指定，不可更改：

| 约束项 | 要求 | 说明 |
|--------|------|------|
| UI 设计规范 | Google Material Design 3 (MD3) | 遵循 MD3 组件样式、动效规范、色彩系统 |
| 技术架构 | Flutter | 使用 Flutter 跨平台框架，一套代码覆盖所有目标平台 |
| 多平台支持 | Windows、macOS、鸿蒙 (HarmonyOS)、Android、iOS | 初始版本以 **Windows 为首发平台**进行开发，UI 层不使用任何平台专有 API，确保后续移植到其他平台时无需修改 UI 代码 |
| 输入方式适配 | 触控 + 键鼠双模式 | 所有交互组件同时适配触控操作（点击/滑动/长按）和桌面键鼠操作（点击/悬停/右键/键盘快捷键）。通过输入模式判定自动切换交互行为，用户无感 |
| UI 可移植性 | UI 层与平台层完全解耦 | `lib/features/` 和 `lib/shared/` 下的所有 Widget 代码不含任何 `Platform.is*` 判断或 `dart:io` 平台 API 调用。平台差异通过 `lib/core/platform/` 抽象层注入 |
| 用户体系 | 无用户体系 | 不设登录/注册，无账号概念，数据以设备维度存储 |
| 数据同步 | WebDAV 协议 | 支持自建 WebDAV 服务器，适配工厂内网 |

### 2.1 平台优先级与发布节奏

| 阶段 | 平台 | 说明 |
|------|------|------|
| Phase 1 (首发) | Windows | 桌面键鼠操作为主，窗口可自由缩放，验证 UI 可移植性 |
| Phase 2 | Android + iOS | 触控操作为主，验证移动端布局适配和触控交互 |
| Phase 3 | macOS | 桌面键鼠 + 触控板，与 Windows 共享桌面端逻辑 |
| Phase 4 | HarmonyOS (鸿蒙) | 依赖 Flutter 鸿蒙生态成熟度，可能需要 ohos flutter 分支 |

### 2.2 UI 可移植性约束细则

为确保 UI 代码无需修改即可跨平台移植，遵循以下规则：

| 规则 | 说明 | 违规示例 |
|------|------|----------|
| 禁止在 UI 层使用 `Platform.is*` | 平台判断通过 `PlatformInfo` 抽象注入 | `if (Platform.isWindows) Text('Win')` |
| 禁止在 UI 层直接调用 `dart:io` | 文件/路径等操作通过 `StorageService` 抽象 | `File('path').readAsString()` |
| 禁止使用平台专有插件 | 仅使用支持多平台的 Flutter 插件 | `windows_taskbar` 等专有插件 |
| 尺寸单位使用逻辑像素 | 不使用物理像素或平台专有单位 | `MediaQuery.devicePixelRatio` 硬编码 |
| 交互组件封装为自适应组件 | 同一组件根据 `InputMode` 自动调整交互行为 | 为触控和键鼠各写一套 Widget |

---

## 3. 数据模型

所有模型使用 Dart 类定义，持久化到本地 SQLite / SharedPreferences / Hive（由 TASK-01 选定）。

### 3.1 ModuleDefinition（模块定义）

```dart
class ModuleDefinition {
  final String id;           // 唯一标识，如 "counter"
  final String name;         // 显示名称，如 "计数器"
  final String? description; // 一行简要说明
  final String iconName;     // MD3 图标标识
  final bool defaultEnabled; // 系统预设默认开关状态
}
```

### 3.2 ModuleState（模块启用状态）

```dart
class ModuleState {
  final String moduleId;     // 关联 ModuleDefinition.id
  bool enabled;              // 当前是否启用
  int displayOrder;          // 在导航栏/主页中的排列顺序
}
```

### 3.3 LayoutConfig（布局配置）

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
//
// 自动断点策略 (autoBreakpoint=true 时):
//   LayoutController 根据设备类型 + 屏幕物理尺寸自动计算最优断点值
//   手机 (短边 < 600dp): breakpoint = 1.00  ← 宽>高 即横屏
//   平板 (短边 >= 600dp 且 < 840dp): breakpoint = 1.30  ← 需明显横宽才切横屏
//   桌面窗口 (任意): breakpoint = 1.20  ← 默认阈值，用户拖拽窗口时实时判定
//
// 自动 DPI 策略 (autoDpi=true 时):
//   通过 DeviceInfoProvider.physicalDpi 获取屏幕物理 DPI，计算缩放因子
//   桌面端: dpiScale = clamp(physicalDpi / desktopBaseDpi, 0.8, 1.5)
//   移动端: dpiScale = 1.0 (Flutter 已处理设备像素密度，不做额外缩放)
//
// 手动模式 (auto*=false 时):
//   用户通过设置页滑块直接指定 breakpoint / dpiScale 值
//   手动值持久化，切回自动模式后恢复自动计算
```

### 3.4 InputMode（输入模式）

```dart
/// 当前活跃的输入方式，由 InputDetector 自动检测并切换
enum InputMode {
  touch,       // 触控模式：大点击区域、无悬停态、滑动手势优先
  mouse,       // 键鼠模式：精确点击、悬停高亮、右键菜单、键盘快捷键
}

/// 输入模式判定策略：
/// - 检测到 PointerDownEvent 且来源为 touch → 切换到 touch
/// - 检测到 PointerHoverEvent 或 PointerDownEvent 且来源为 mouse → 切换到 mouse
/// - 桌面平台 (Windows/macOS) 默认 mouse，移动平台 (Android/iOS) 默认 touch
/// - 首次输入事件后自动切换，之后跟随最近一次输入设备的类型
/// - 支持混合设备（如 Windows 触屏笔记本）：根据最近一次输入事件动态切换
```

### 3.5 ThemeConfig（主题配置）

```dart
enum ThemeMode { light, dark }

class ThemeConfig {
  ThemeMode mode;            // 明亮 / 暗黑，默认 light
  String accentColorHex;     // 强调色 HEX 值，默认 "#E85D04"
  double fontScale;          // 字体缩放因子，默认 1.0（范围 0.8-1.5，步进 0.1）
}

// 预设强调色:
// 安全橙 #E85D04 | 工业蓝 #1565C0 | 安全绿 #2D7D46
// 警示红 #C62828 | 紫 #6A1B9A     | 黄 #F9A825
//
// fontScale 说明:
//   1.0 = 系统默认字体大小
//   < 1.0 = 缩小字体（适合大屏桌面端信息密集场景）
//   > 1.0 = 放大字体（适合小屏移动端或视力辅助）
//   通过 MediaQuery.textScaleFactor 或 TextTheme 复制时乘以 fontScale 实现
```

### 3.6 SyncConfig（同步配置）

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

### 3.7 预设模块清单

| id | name | description | iconName | defaultEnabled |
|----|------|-------------|----------|----------------|
| `counter` | 计数器 | 产线计数、批次记录 | `counter` | `true` |
| `timer` | 计时器 | 工序计时、节拍管控 | `timer` | `true` |
| `checklist` | 检查表 | 设备点检、安全巡检 | `checklist` | `true` |

> **注**: 首发版本预设 3 个模块，均默认启用。模块清单设计为可增减——后续版本可通过更新预设清单代码新增模块，或通过模块管理页面关闭不需要的模块。模块图标暂用标识符占位，后续映射到 MD3 Icons。

### 3.8 DeviceInfoProvider（系统与设备信息抽象）

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

/// 各平台实现说明:
/// ┌─────────────┬──────────────────────────────────────────────────────────┐
/// │ 平台        │ 实现方式                                                  │
/// ├─────────────┼──────────────────────────────────────────────────────────┤
/// │ Windows     │ deviceId: 注册表 MachineGuid 或自生成 UUID                │
/// │             │ osName/Version: dart:io Platform.operatingSystem          │
/// │             │ deviceModel: 主机名 或 WMI 查询                            │
/// │             │ physicalDpi: window_manager + GetDpiForWindow API         │
/// ├─────────────┼──────────────────────────────────────────────────────────┤
/// │ macOS       │ deviceId: IOPlatformUUID                                  │
/// │             │ osName/Version: Platform.operatingSystem                  │
/// │             │ deviceModel: sysctl hw.model                              │
/// │             │ physicalDpi: NSScreen backingScaleFactor * 96             │
/// ├─────────────┼──────────────────────────────────────────────────────────┤
/// │ Android     │ deviceId: Settings.Secure.ANDROID_ID 或自生成 UUID         │
/// │             │ osName/Version: android.os.Build.VERSION                  │
/// │             │ deviceModel: android.os.Build.MODEL / MANUFACTURER        │
/// │             │ physicalDpi: displayMetrics.densityDpi                    │
/// ├─────────────┼──────────────────────────────────────────────────────────┤
/// │ iOS         │ deviceId: UIDevice.identifierForVendor 或自生成 UUID       │
/// │             │ osName/Version: UIDevice.systemName / systemVersion       │
/// │             │ deviceModel: UIDevice.model / machineIdentifier           │
/// │             │ physicalDpi: UIScreen.scale * 96 (按设备型号查表)          │
/// ├─────────────┼──────────────────────────────────────────────────────────┤
/// │ HarmonyOS   │ deviceId: 系统分布式设备标识 或自生成 UUID                   │
/// │             │ osName/Version: ohos 参数                                  │
/// │             │ deviceModel: 设备信息 API                                   │
/// │             │ physicalDpi: 屏幕配置 API                                   │
/// └─────────────┴──────────────────────────────────────────────────────────┘
///
/// 统一策略:
/// - deviceId: 优先使用平台原生标识，获取失败时自生成 UUID 并持久化到本地
/// - appVersion/buildNumber: 所有平台统一使用 package_info_plus 获取
/// - physicalDpi: 桌面端通过窗口 API 获取，移动端通过设备 API 获取
/// - inputCapability: 桌面默认 hybrid（Windows 触屏）/ mouseOnly，移动默认 touchOnly
```

### 3.9 ModuleContract（模块契约接口）

APP 底座定义的模块契约，所有功能模块子项目必须实现此接口才能接入主项目。契约确保模块与底座在 UI 规范、状态管理、平台抽象、输入适配等方面保持一致。

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

**子项目必须遵守的约束清单:**

| 约束 | 要求 | 违规示例 |
|------|------|----------|
| 技术栈 | Flutter + Riverpod | 使用 GetX / Bloc 等其他状态管理 |
| UI 规范 | Material Design 3 | 使用 Cupertino 风格组件 |
| 状态管理 | `ConsumerWidget` + `ref.watch/read` | 使用 `setState` + `InheritedWidget` |
| 平台抽象 | 不使用 `Platform.is*` / `dart:io` | 模块代码中直接调用 `Platform.isWindows` |
| 输入适配 | 使用 `AdaptiveButton` / `AdaptiveListTile` | 直接使用 `IconButton` / `ListTile` |
| 主题 | 使用 `Theme.of(context)` 获取配色 | 硬编码颜色值 |
| 布局适配 | 使用 `ResponsiveBuilder` 适配横竖屏 | 固定宽度 / 高度 |
| 数据存储 | 通过 `StorageService` 抽象接口 | 直接读写文件系统 |
| 数据同步 | 实现 `exportData` / `importData` | 自行实现同步逻辑 |
| 图标 | MD3 Material Symbols | 使用自定义图片图标 |
| 包依赖 | 仅依赖底座已声明的依赖 + `pubspec.yaml` 中声明的跨平台包 | 依赖平台专有插件 |

**模块注册机制:**

```dart
// lib/core/modules/module_registry.dart

/// 模块注册表——底座启动时扫描并注册所有模块
class ModuleRegistry {
  /// 注册所有模块（新增模块时在此添加）
  static List<ModuleContract> registerAll() {
    return [
      CounterModule(),      // 来自子项目 modules/counter
      TimerModule(),        // 来自子项目 modules/timer
      ChecklistModule(),    // 来自子项目 modules/checklist
      // 新增模块在此追加...
    ];
  }
}

// 模块注册时机：main() 中 StorageService.init() 之后
// 底座遍历注册表，调用每个模块的 initialize()，
// 然后根据 ModuleState.enabled 决定是否在导航栏和主页显示
```

**子项目目录结构规范:**

```
modules/                                # 子项目根目录（与 lib/ 同级）
├── counter/                            # 计数器模块子项目
│   ├── README.md                       # 模块需求说明（引用底座规格为约束基线）
│   ├── pubspec.yaml                    # 模块依赖（可选，也可共用主项目 pubspec）
│   ├── lib/
│   │   ├── counter_module.dart         # 实现 ModuleContract 入口
│   │   ├── counter_page.dart           # 模块主页 (ConsumerWidget)
│   │   ├── counter_store.dart          # 模块数据模型 + 存储逻辑
│   │   └── widgets/                    # 模块私有组件
│   └── test/
│       └── counter_test.dart           # 模块单元测试
├── timer/
│   ├── lib/
│   │   ├── timer_module.dart
│   │   └── ...
│   └── ...
└── checklist/
    └── ...
```

> **注**: 子项目代码物理上位于 `modules/` 目录，通过主项目 `pubspec.yaml` 的 path 依赖或直接 import 引入。模块代码不直接访问 `lib/core/` 之外的底座私有实现，仅通过 `ModuleContract` 接口和 `StorageService` 抽象与底座交互。

---

## 4. 项目结构

### 4.1 主项目（APP 底座）

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
│   │   ├── module_contract.dart       # ModuleContract 抽象接口（第 3.9 节）
│   │   └── module_registry.dart       # 模块注册表
│   ├── platform/
│   │   ├── platform_info.dart         # 平台信息抽象接口（运行平台、是否桌面端）
│   │   ├── platform_info_impl.dart    # 平台检测实现（基于 dart:io，不暴露给 UI 层）
│   │   ├── device_info_provider.dart  # 系统与设备信息抽象接口（第 3.8 节）
│   │   ├── windows_device_info.dart   # Windows 实现
│   │   ├── macos_device_info.dart     # macOS 实现
│   │   ├── android_device_info.dart   # Android 实现
│   │   ├── ios_device_info.dart       # iOS 实现
│   │   └── ohos_device_info.dart      # HarmonyOS 实现
│   ├── input/
│   │   ├── input_controller.dart      # 输入模式状态管理 (ChangeNotifier，被 Riverpod 托管)
│   │   ├── input_detector.dart        # Pointer 事件监听，自动判定 touch/mouse
│   │   └── input_mode_scope.dart      # InheritedWidget，向子树注入当前 InputMode
│   ├── theme/
│   │   ├── theme_controller.dart      # 主题状态管理 (ChangeNotifier，被 Riverpod 托管)
│   │   ├── md3_color_scheme.dart      # MD3 ColorScheme 生成器
│   │   └── dpi_scaler.dart            # DPI 缩放 Widget
│   ├── layout/
│   │   ├── layout_controller.dart     # 布局模式判定与状态 (ChangeNotifier，被 Riverpod 托管)
│   │   └── responsive_builder.dart    # 响应式布局 Widget
│   ├── storage/
│   │   ├── storage_service.dart       # 本地持久化抽象接口
│   │   └── hive_storage.dart          # Hive 实现（或其他选定方案）
│   ├── sync/
│   │   ├── webdav_client.dart         # WebDAV 协议客户端
│   │   ├── sync_service.dart          # 同步调度逻辑（调用各模块 exportData/importData）
│   │   └── conflict_resolver.dart     # 冲突解决策略
│   └── models/
│       ├── module_definition.dart
│       ├── module_state.dart
│       ├── module_summary.dart        # 模块摘要数据（第 3.9 节）
│       ├── layout_config.dart
│       ├── input_mode.dart
│       ├── theme_config.dart
│       └── sync_config.dart
├── features/
│   ├── home/
│   │   ├── home_page.dart             # ConsumerWidget，通过 ref 读取状态
│   │   ├── module_card_widget.dart    # 自适应：触控用大卡片，键鼠用紧凑卡片+悬停
│   │   └── sync_status_widget.dart
│   ├── module_management/
│   │   └── module_management_page.dart
│   ├── settings/
│   │   ├── settings_page.dart
│   │   ├── theme_settings_page.dart
│   │   ├── layout_settings_page.dart
│   │   └── sync_settings_page.dart
└── shared/                            # 底座共享组件（子项目可复用）
    ├── widgets/
    │   ├── adaptive_button.dart       # 自适应按钮：触控大点击域 / 键鼠精确+悬停
    │   ├── adaptive_list_tile.dart    # 自适应列表项：触控大高度 / 键鼠紧凑+右键
│   │   ├── md3_switch.dart            # MD3 风格 Switch
│   │   ├── md3_slider.dart            # MD3 风格 Slider
│   │   └── settings_list_tile.dart    # 设置项通用组件
│   └── utils/
│       ├── aspect_ratio_helper.dart   # 宽高比计算工具
│       └── input_mode_helper.dart     # 输入模式查询工具

# ── 子项目（功能模块）──
modules/                                # 子项目根目录，与 lib/ 同级
├── counter/                            # 计数器模块
│   ├── README.md                       # 模块需求说明（引用本规格为约束基线）
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
ohos/                                  # HarmonyOS 平台配置 (待 Flutter 鸿蒙支持成熟)
```

### 4.2 子项目（功能模块）

子项目位于 `modules/` 目录下，每个模块是一个独立目录，包含自己的 `README.md` 需求说明和完整的 `lib/` + `test/` 结构。子项目通过实现 `ModuleContract` 接口接入主项目，开发流程见第 8 节。

---

## 5. 任务拆解

每个任务卡片包含：**概述 → 依赖 → 验收标准 → 技术细节 → 涉及文件**。
Agent 可按 TASK 编号顺序领取，确保依赖项已完成。

---

### TASK-00: 项目初始化与基础架构

| 属性 | 值 |
|------|-----|
| **ID** | TASK-00 |
| **优先级** | P0 (阻塞) |
| **依赖** | 无 |
| **预估复杂度** | 低 |
| **状态** | 待开发 |

#### 概述

初始化 Flutter 项目，配置 Windows 桌面端为首发平台，搭建 MD3 主题骨架、平台抽象层（含平台信息与系统设备信息抽象）、基础导航框架，为后续所有任务提供运行基础。UI 层从第一天起即与平台层解耦，确保后续移植到其他平台时无需修改 `lib/features/` 和 `lib/shared/` 下的任何代码。

#### 验收标准

- [ ] `flutter create --platforms=windows` 生成的项目可成功编译运行（Windows 桌面端）
- [ ] `main.dart` 使用 `MaterialApp.router` 或 `MaterialApp` 配置 MD3 主题
- [ ] 应用启动后显示空白 Scaffold 页面，无崩溃
- [ ] 项目目录结构符合第 4 节定义的 `lib/` 布局，包含 `core/platform/` 和 `core/input/` 目录
- [ ] `pubspec.yaml` 中已添加基础依赖（见下方依赖清单）
- [ ] 已配置 `core/constants.dart`，包含预设强调色列表和默认配置值
- [ ] `PlatformInfo` 抽象接口已定义，UI 层通过此接口查询平台信息，不直接调用 `Platform.is*`
- [ ] `DeviceInfoProvider` 抽象接口已定义（见第 3.8 节），UI 层通过此接口获取设备 ID、OS 版本、DPI 等信息
- [ ] Windows 平台的 `DeviceInfoProvider` 实现类已完成，可正确返回 deviceId、osName、osVersion、deviceModel、physicalDpi
- [ ] `deviceId` 获取逻辑：优先读取平台原生标识，失败时自生成 UUID 并持久化到 `flutter_secure_storage`
- [ ] 其他平台（macOS/Android/iOS/HarmonyOS）的 `DeviceInfoProvider` 实现类预留接口，Phase 2-4 开发时填充
- [ ] Windows 窗口最小尺寸已设置（建议 400x600），窗口可自由缩放
- [ ] 验证：在 `lib/features/` 和 `lib/shared/` 目录下搜索不到 `Platform.is` 或 `dart:io` 引用

#### 技术细节

**pubspec.yaml 依赖清单:**

```yaml
dependencies:
  flutter:
    sdk: flutter
  # 状态管理
  flutter_riverpod: ^2.5.0     # Riverpod（编译时安全，无需 BuildContext，独立可测试）
  # 本地存储
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  # WebDAV
  webdav_client: ^2.0.0     # 或自行实现
  # 加密
  flutter_secure_storage: ^9.0.0
  # 路径
  path_provider: ^2.1.0
  # 系统与设备信息（跨平台）
  device_info_plus: ^10.0.0    # 设备信息（OS版本、型号等）
  package_info_plus: ^8.0.0    # 应用版本信息
  # 桌面窗口管理
  window_manager: ^0.3.7       # Windows/macOS 窗口管理（DPI、窗口尺寸）

# Flutter 桌面端需要启用对应平台
# flutter config --enable-windows-desktop  (Flutter 3.x 已默认启用)
# device_info_plus 和 package_info_plus 均支持全平台，不违反可移植性
```

**PlatformInfo 抽象接口:**

```dart
/// 平台信息抽象，UI 层通过此接口获取平台特征
/// 实现类在 lib/core/platform/platform_info_impl.dart 中使用 dart:io
abstract class PlatformInfo {
  /// 当前运行平台
  AppPlatform get currentPlatform;

  /// 是否为桌面端 (Windows / macOS)
  bool get isDesktop;

  /// 是否为移动端 (Android / iOS / HarmonyOS)
  bool get isMobile;

  /// 默认输入模式（桌面端为 mouse，移动端为 touch）
  InputMode get defaultInputMode;
}

enum AppPlatform { windows, macos, android, ios, harmonyos, web }
```

**DeviceInfoProvider 抽象接口（详见第 3.8 节）:**

```dart
/// 系统与设备信息抽象，UI 层通过此接口获取设备 ID、OS 版本、DPI 等
/// 各平台实现类在 lib/core/platform/ 下，按条件导入
abstract class DeviceInfoProvider {
  String get deviceId;                    // 设备唯一标识
  String get osName;                      // 操作系统名称
  String get osVersion;                   // 操作系统版本
  String get deviceModel;                 // 设备型号
  String get appVersion;                  // 应用版本号
  String get appBuildNumber;              // 应用构建号
  double get physicalDpi;                 // 屏幕物理 DPI
  double? get physicalScreenSize;         // 屏幕物理尺寸（英寸）
  DeviceInputCapability get inputCapability; // 设备输入能力
}
```

**Windows 平台 DeviceInfoProvider 实现要点:**

```dart
// lib/core/platform/windows_device_info.dart
// 通过条件导入，仅在 Windows 平台编译

class WindowsDeviceInfoProvider implements DeviceInfoProvider {
  @override
  String get deviceId {
    // 1. 优先从 flutter_secure_storage 读取已持久化的 ID
    // 2. 若无，读取 Windows 注册表 HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid
    // 3. 注册表读取失败 → 生成 UUID 并持久化
  }

  @override
  String get osName => 'Windows';

  @override
  String get osVersion {
    // Platform.operatingSystemVersion 返回如 "10.0.22631.0"
    // 解析版本号映射为 "Windows 10" / "Windows 11"（Build >= 22000 为 Win11）
  }

  @override
  String get deviceModel {
    // 通过 platform.environment['COMPUTERNAME'] 获取主机名
    // 或 WMI 查询 Win32_ComputerSystem.Manufacturer + Model
  }

  @override
  double get physicalDpi {
    // 通过 window_manager 获取窗口 DPI
    // 或调用 GetDpiForWindow / GetDpiForSystem API
    // 返回逻辑 DPI（96 = 100%, 144 = 150%）
  }

  @override
  String get appVersion {
    // 通过 package_info_plus PackageInfo.fromPlatform() 获取
  }
}
```

**条件导入实现（各平台自动选择实现类）:**

```dart
// lib/core/platform/device_info_provider.dart
export 'device_info_provider_interface.dart'
    if (dart.library.io) 'device_info_provider_factory.dart';

// device_info_provider_factory.dart
import 'package:flutter/foundation.dart';

DeviceInfoProvider createDeviceInfoProvider() {
  if (kIsWeb) return WebDeviceInfoProvider();
  if (Platform.isWindows) return WindowsDeviceInfoProvider();
  if (Platform.isMacOS) return MacosDeviceInfoProvider();
  if (Platform.isAndroid) return AndroidDeviceInfoProvider();
  if (Platform.isIOS) return IosDeviceInfoProvider();
  // HarmonyOS 分支: if (Platform.isOHOS) return OhosDeviceInfoProvider();
  throw UnsupportedError('Unsupported platform');
}
```

**Riverpod 状态管理架构:**

```dart
// lib/main.dart — 应用入口，ProviderScope 包裹整个应用
void main() {
  runApp(const ProviderScope(child: ModularToolApp()));
}

// lib/core/providers/platform_provider.dart
final platformInfoProvider = Provider<PlatformInfo>((ref) {
  return PlatformInfoImpl();
});

final deviceInfoProvider = Provider<DeviceInfoProvider>((ref) {
  return createDeviceInfoProvider();  // 条件导入，按平台返回实现
});

// lib/core/providers/storage_provider.dart
final storageServiceProvider = Provider<StorageService>((ref) {
  final storage = HiveStorage();
  storage.init();
  return storage;
});

// lib/core/providers/theme_provider.dart
final themeControllerProvider =
    ChangeNotifierProvider<ThemeController>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeController(storage.getThemeConfig(), storage);
});

// lib/core/providers/layout_provider.dart
final layoutControllerProvider =
    ChangeNotifierProvider<LayoutController>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final platformInfo = ref.watch(platformInfoProvider);
  return LayoutController(storage.getLayoutConfig(), platformInfo, storage);
});

// lib/core/providers/input_provider.dart
final inputControllerProvider =
    ChangeNotifierProvider<InputController>((ref) {
  final platformInfo = ref.watch(platformInfoProvider);
  return InputController(platformInfo);
});

// lib/core/providers/sync_provider.dart
final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final deviceInfo = ref.watch(deviceInfoProvider);
  return SyncService(storage, deviceInfo);
});
```

**Riverpod 消费方式:**

```dart
// Widget 通过 ConsumerWidget + ref 读取状态
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutMode = ref.watch(layoutControllerProvider).currentMode;
    final modules = ref.watch(storageServiceProvider).getEnabledModules();

    return ResponsiveBuilder(
      portraitBuilder: (context) => _buildPortrait(modules),
      landscapeBuilder: (context) => _buildLandscape(modules),
    );
  }
}

// 仅读取一次（不监听变化）的场景
void _onModuleToggled(WidgetRef ref, String moduleId, bool enabled) {
  ref.read(storageServiceProvider).setModuleEnabled(moduleId, enabled);
}
```

**选择 Riverpod 的理由（Agent 驱动开发视角）:**
- 编译时安全：Provider 类型在编译期检查，Agent 修改代码时类型错误立即可见
- 无需 BuildContext：`core/` 层 Controller 可在无 Widget 环境下单元测试
- 依赖图显式：Provider 之间的依赖通过 `ref.watch` 链式声明，依赖关系一目了然
- autoDispose：防止 Agent 编写代码时意外引入内存泄漏

**Windows 窗口配置:**

在 `windows/runner/main.cpp` 或通过 `window_manager` 插件设置窗口最小尺寸和标题。若使用 `window_manager`，需在 `pubspec.yaml` 中添加（注意：此插件支持 Windows/macOS/Linux，不违反可移植性）：

```yaml
  window_manager: ^0.3.7   # 桌面窗口管理，支持 Windows/macOS
```

**constants.dart 关键内容:**

```dart
class AppConstants {
  static const List<({String name, String hex, String displayName})> presetColors = [
    (name: 'safety_orange',  hex: '#E85D04', displayName: '安全橙'),
    (name: 'industrial_blue', hex: '#1565C0', displayName: '工业蓝'),
    (name: 'safety_green',   hex: '#2D7D46', displayName: '安全绿'),
    (name: 'warning_red',    hex: '#C62828', displayName: '警示红'),
    (name: 'purple',         hex: '#6A1B9A', displayName: '紫'),
    (name: 'yellow',         hex: '#F9A825', displayName: '黄'),
  ];

  // ── 默认配置 ──
  static const bool defaultAutoBreakpoint = true;   // 默认自动断点
  static const bool defaultAutoDpi = true;           // 默认自动 DPI
  static const double defaultBreakpoint = 1.20;      // 手动断点默认值
  static const double defaultDpiScale = 1.0;         // 手动 DPI 默认值

  // ── 断点范围 ──
  static const double minBreakpoint = 1.00;
  static const double maxBreakpoint = 2.00;
  static const double breakpointStep = 0.05;

  // ── DPI 范围 ──
  static const double minDpiScale = 0.8;
  static const double maxDpiScale = 1.5;
  static const double dpiStep = 0.1;

  // ── 自动断点判定阈值（按设备短边 dp 划分）──
  static const double phoneMaxShortSide = 600;       // 短边 < 600dp → 手机
  static const double tabletMaxShortSide = 840;      // 600-840dp → 平板，>= 840dp → 桌面
  static const double autoBreakpointPhone = 1.00;    // 手机自动断点
  static const double autoBreakpointTablet = 1.30;   // 平板自动断点
  static const double autoBreakpointDesktop = 1.20;  // 桌面自动断点

  // ── 自动 DPI 基准 ──
  static const double desktopBaseDpi = 96.0;         // Windows/macOS 系统基准 DPI
}
```

#### 涉及文件

- `pubspec.yaml`
- `lib/main.dart`
- `lib/app.dart`
- `lib/core/constants.dart`
- `lib/core/providers/platform_provider.dart`
- `lib/core/providers/storage_provider.dart`
- `lib/core/providers/theme_provider.dart`
- `lib/core/providers/layout_provider.dart`
- `lib/core/providers/input_provider.dart`
- `lib/core/providers/sync_provider.dart`
- `lib/core/platform/platform_info.dart`
- `lib/core/platform/platform_info_impl.dart`
- `lib/core/platform/device_info_provider.dart` (抽象接口)
- `lib/core/platform/windows_device_info.dart` (Windows 实现)
- `lib/core/platform/macos_device_info.dart` (macOS 实现，预留)
- `lib/core/platform/android_device_info.dart` (Android 实现，预留)
- `lib/core/platform/ios_device_info.dart` (iOS 实现，预留)
- `lib/core/platform/ohos_device_info.dart` (HarmonyOS 实现，预留)
- `lib/core/input/input_controller.dart`
- `lib/core/input/input_mode_scope.dart`
- `windows/runner/` (Windows 平台配置)

---

### TASK-01: 本地持久化存储层

| 属性 | 值 |
|------|-----|
| **ID** | TASK-01 |
| **优先级** | P0 (阻塞) |
| **依赖** | TASK-00 |
| **预估复杂度** | 中 |
| **状态** | 待开发 |

#### 概述

实现本地持久化存储服务，提供统一的读写接口供所有配置和状态数据使用。包括模块状态、布局配置、主题配置、同步配置的增删改查。

#### 验收标准

- [ ] `StorageService` 抽象接口定义完整，覆盖所有数据模型的 CRUD
- [ ] Hive 实现类 `HiveStorage` 可正确读写所有数据模型
- [ ] 预设模块清单在首次启动时自动初始化写入
- [ ] 应用重启后，上次保存的所有配置均可正确恢复
- [ ] 密码字段使用 `flutter_secure_storage` 加密存储，不以明文出现在 Hive 中
- [ ] 提供 `init()` 方法，在 `main()` 中调用完成初始化

#### 技术细节

**StorageService 接口:**

```dart
abstract class StorageService {
  Future<void> init();

  // Module
  List<ModuleDefinition> getAllModuleDefinitions();
  List<ModuleState> getEnabledModules();
  Future<void> setModuleEnabled(String moduleId, bool enabled);
  Future<void> setModuleOrder(String moduleId, int order);

  // Layout
  LayoutConfig getLayoutConfig();
  Future<void> updateLayoutConfig(LayoutConfig config);

  // Theme
  ThemeConfig getThemeConfig();
  Future<void> updateThemeConfig(ThemeConfig config);

  // Sync
  SyncConfig? getSyncConfig();
  Future<void> updateSyncConfig(SyncConfig config);
  Future<void> updateSyncStatus(SyncStatus status, DateTime time);

  // Generic data (for module records)
  Future<void> saveData(String key, Map<String, dynamic> data);
  Map<String, dynamic>? loadData(String key);
  Future<void> deleteData(String key);
}
```

**首次初始化逻辑:**

首次启动时检测本地是否已有模块定义数据。若无，则按第 3.7 节预设清单写入 3 个 `ModuleDefinition` 和对应的 `ModuleState`（3 个模块均 `enabled = true`，`displayOrder` 按列表顺序赋值 0-2）。同时写入默认 `LayoutConfig`、`ThemeConfig`。

#### 涉及文件

- `lib/core/storage/storage_service.dart`
- `lib/core/storage/hive_storage.dart`
- `lib/core/models/*.dart` (所有数据模型类)

---

### TASK-02: 模块管理系统

| 属性 | 值 |
|------|-----|
| **ID** | TASK-02 |
| **优先级** | P1 |
| **依赖** | TASK-00, TASK-01 |
| **预估复杂度** | 中 |
| **状态** | 待开发 |

#### 概述

实现模块管理页面，用户可查看所有可用模块并通过开关启用/关闭各模块。开关状态持久化，变更即时影响导航栏和主页。

#### 验收标准

- [ ] 模块管理页面显示所有预设模块（图标 + 名称 + 描述 + Switch 开关）
- [ ] Switch 状态与 `ModuleState.enabled` 双向绑定
- [ ] 点击 Switch 即时切换状态，300ms 过渡动效，无需额外保存操作
- [ ] 页面底部显示"当前已启用 N 个模块"实时计数
- [ ] 开关状态写入本地存储，应用重启后保持
- [ ] 开关状态变更后，通过状态管理通知主页和导航栏更新（即使主页未打开，下次打开时也反映最新状态）
- [ ] 遵循 MD3 Switch 组件视觉规范

#### 技术细节

**页面结构（从上至下）:**

1. TopAppBar: 标题"模块管理"，左侧返回按钮
2. 分组标签: "可用模块（共 N 个）"
3. 模块列表: 每行 = 图标 + 名称/描述 + MD3 Switch

**状态通知:**

模块开关变更后，调用 `StorageService.setModuleEnabled()`，同时通过 Riverpod 通知 `HomePage` 和导航栏重建。Widget 使用 `ref.watch(storageServiceProvider)` 监听变更，被关闭模块的卡片以淡出动画移除，被开启的以淡入动画出现。

#### 涉及文件

- `lib/features/module_management/module_management_page.dart`
- `lib/shared/widgets/md3_switch.dart`
- `lib/core/storage/storage_service.dart` (已有接口，此处调用)

---

### TASK-03: 响应式布局引擎

| 属性 | 值 |
|------|-----|
| **ID** | TASK-03 |
| **优先级** | P0 (阻塞) |
| **依赖** | TASK-00, TASK-01 |
| **预估复杂度** | 高 |
| **状态** | 待开发 |

#### 概述

实现响应式布局判定引擎：实时监听屏幕尺寸变化（包括设备旋转和**桌面窗口缩放**），根据宽高比与断点值判定横屏/竖屏模式，并暴露布局模式供所有页面消费。断点值支持**自动检测**和**手动指定**两种模式。同时实现 DPI 缩放机制，同样支持自动/手动两种模式。布局规则不区分平台，仅依据宽高比判定，确保同一套逻辑在 Windows 窗口和手机屏幕上均生效。

#### 验收标准

- [ ] `LayoutController` 监听 `MediaQuery` 尺寸变化，实时计算宽高比
- [ ] 宽高比 >= 断点值 → 横屏模式（`LayoutMode.landscape`）；< 断点值 → 竖屏模式（`LayoutMode.portrait`）
- [ ] **自动断点模式**（`autoBreakpoint=true`，默认）：根据屏幕短边 dp 自动选择断点值，无需用户干预
- [ ] **手动断点模式**（`autoBreakpoint=false`）：使用用户在设置页配置的 `breakpoint` 值
- [ ] 断点值从 `LayoutConfig` 读取，`LayoutController` 根据模式决定使用自动计算值还是手动值
- [ ] 布局模式切换在 300ms 内完成，附带平滑过渡动画
- [ ] `ResponsiveBuilder` Widget 根据 `LayoutMode` 返回不同 Widget 子树
- [ ] **自动 DPI 模式**（`autoDpi=true`，默认）：桌面端根据系统 DPI 自动计算缩放，移动端保持 1.0
- [ ] **手动 DPI 模式**（`autoDpi=false`）：使用用户配置的 `dpiScale` 值
- [ ] DPI 缩放通过 `MediaQuery` 注入 `textScaleFactor` 实现，范围 0.8-1.5
- [ ] 设备旋转时布局正确切换，无错乱
- [ ] **Windows 桌面端：用户拖拽窗口改变尺寸时，宽高比跨越断点值时布局自动切换**
- [ ] **Windows 桌面端：窗口极小尺寸（如 400x600）时竖屏布局可用，窗口拉宽（如 1200x600）时横屏布局生效**
- [ ] 布局判定逻辑中不含任何 `Platform.is*` 调用，纯基于 `MediaQuery` 数据和 `PlatformInfo` 抽象

#### 技术细节

**布局判定逻辑:**

```dart
enum LayoutMode { portrait, landscape }

// 判定规则:
// 1. 获取当前生效的断点值:
//    if (config.autoBreakpoint) effectiveBp = _computeAutoBreakpoint(shortestSide)
//    else                        effectiveBp = config.breakpoint
// 2. aspectRatio = screenWidth / screenHeight
//    if aspectRatio >= effectiveBp → landscape
//    else → portrait

// 竖屏渲染规则: 卡片单列纵向排布 (ListView)
// 横屏渲染规则: 卡片双列网格排布 (GridView, crossAxisCount=2)
```

**LayoutController 核心逻辑:**

```dart
class LayoutController extends ChangeNotifier {
  final LayoutConfig _config;
  final PlatformInfo _platformInfo;

  LayoutMode _currentMode = LayoutMode.portrait;
  double _effectiveBreakpoint = AppConstants.defaultBreakpoint;

  LayoutMode get currentMode => _currentMode;
  double get effectiveBreakpoint => _effectiveBreakpoint;
  bool get isAutoBreakpoint => _config.autoBreakpoint;

  /// 根据 MediaQuery 数据更新布局判定
  void updateFromMediaQuery(MediaQueryData mq) {
    final aspectRatio = mq.size.width / mq.size.height;
    final shortestSide = mq.size.shortestSide;

    // 计算生效断点
    if (_config.autoBreakpoint) {
      _effectiveBreakpoint = _computeAutoBreakpoint(shortestSide);
    } else {
      _effectiveBreakpoint = _config.breakpoint;
    }

    final newMode = aspectRatio >= _effectiveBreakpoint
        ? LayoutMode.landscape
        : LayoutMode.portrait;

    if (newMode != _currentMode) {
      _currentMode = newMode;
      notifyListeners();
    }
  }

  /// 自动断点计算：根据短边 dp 判定设备类型
  double _computeAutoBreakpoint(double shortestSide) {
    if (_platformInfo.isDesktop) {
      return AppConstants.autoBreakpointDesktop;  // 1.20
    } else if (shortestSide < AppConstants.phoneMaxShortSide) {
      return AppConstants.autoBreakpointPhone;    // 1.00
    } else {
      return AppConstants.autoBreakpointTablet;   // 1.30
    }
  }

  /// 切换自动/手动模式时重新计算
  void onConfigChanged(LayoutConfig newConfig) {
    // config 更新后，下次 updateFromMediaQuery 会使用新模式
    notifyListeners();
  }
}
```

**ResponsiveBuilder 用法:**

```dart
ResponsiveBuilder(
  portraitBuilder: (context) => ListView(...),
  landscapeBuilder: (context) => GridView.count(crossAxisCount: 2, ...),
)
```

**DPI 缩放:**

```dart
/// 在 MaterialApp builder 中注入 DPI 缩放
Widget builder(BuildContext context, Widget? child) {
  final layoutConfig = layoutController.config;
  double effectiveDpi;

  if (layoutConfig.autoDpi) {
    // 自动 DPI：通过 DeviceInfoProvider 获取物理 DPI，计算缩放因子
    if (platformInfo.isDesktop) {
      final physicalDpi = deviceInfoProvider.physicalDpi;
      effectiveDpi = (physicalDpi / AppConstants.desktopBaseDpi)
          .clamp(AppConstants.minDpiScale, AppConstants.maxDpiScale);
    } else {
      effectiveDpi = 1.0;  // 移动端不做额外缩放
    }
  } else {
    effectiveDpi = layoutConfig.dpiScale;
  }

  return MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(
        MediaQuery.textScalerOf(context).scale(1) * effectiveDpi
      ),
    ),
    child: child!,
  );
}
```

DPI 缩放仅影响文字和基于文字尺寸的组件，不影响固定像素尺寸的元素（如图标）。

#### 涉及文件

- `lib/core/layout/layout_controller.dart`
- `lib/core/layout/responsive_builder.dart`
- `lib/shared/utils/aspect_ratio_helper.dart`

---

### TASK-04: 主题与显示设置系统

| 属性 | 值 |
|------|-----|
| **ID** | TASK-04 |
| **优先级** | P1 |
| **依赖** | TASK-00, TASK-01 |
| **预估复杂度** | 高 |
| **状态** | 待开发 |

#### 概述

实现 MD3 主题系统：支持明亮/暗黑模式切换、6 种预设强调色选择、DPI 缩放调节（含自动/手动切换）、横竖屏断点调节（含自动/手动切换）。所有配置即时生效并持久化。主题相关设置（明暗、强调色、DPI）在主题设置页；布局相关设置（断点自动/手动、DPI 自动/手动）在布局与显示设置页。

#### 验收标准

- [ ] `ThemeController` 管理当前主题状态，通过 Riverpod (`themeControllerProvider`) 暴露
- [ ] 明亮模式：浅色背景 + 深色文字；暗黑模式：深色背景 + 浅色文字
- [ ] 强调色作为 MD3 种子色，通过 `ColorScheme.fromSeed()` 生成完整色彩梯度
- [ ] 强调色变更后，应用栏、按钮、Switch 激活态、导航栏高亮等元素实时更新
- [ ] 主题切换有 300ms 平滑过渡
- [ ] **主题设置页面**包含五个区域：主题选择卡片、强调色色块、DPI 缩放区、字体大小区、实时预览区
- [ ] **DPI 缩放区**含自动/手动开关（MD3 Switch）：开启时显示"自动"标签且滑块禁用，关闭时滑块可拖动
- [ ] **字体大小区**含 MD3 Slider（0.8x-1.5x，步进 0.1），实时预览文字大小变化，默认 1.0x
- [ ] **布局与显示设置页面**包含断点调节区：含自动/手动开关，手动模式下显示断点滑块（1.00-2.00，步进 0.05）
- [ ] **断点自动模式**开启时，显示当前自动计算的断点值（只读），并标注设备类型（手机/平板/桌面）
- [ ] 两个页面的 DPI 设置联动：在主题页切换 DPI 自动/手动，布局页同步显示
- [ ] 页面底部有实时预览区，展示当前配置下的按钮和文字效果
- [ ] 所有配置写入本地存储，应用重启后恢复

#### 技术细节

**MD3 ColorScheme 生成:**

```dart
ColorScheme lightScheme = ColorScheme.fromSeed(
  seedColor: Color(hexToColor(themeConfig.accentColorHex)),
  brightness: Brightness.light,
);

ColorScheme darkScheme = ColorScheme.fromSeed(
  seedColor: Color(hexToColor(themeConfig.accentColorHex)),
  brightness: Brightness.dark,
);
```

**主题设置页面结构:**

1. 明暗主题选择区：两个预览卡片，展示明亮/暗黑模式视觉，点击切换
2. 强调色选择区：6 个圆形色块，点击选择，选中态显示边框
3. DPI 缩放区：
   - 顶部一行：标签"DPI 缩放" + 右侧 MD3 Switch（自动/手动）
   - 自动模式：显示"自动 (1.0x)"只读文本，滑块隐藏或禁用
   - 手动模式：MD3 Slider + 实时数值显示（0.8x - 1.5x）
4. 字体大小区：
   - 标签"字体大小" + 当前值显示（如"1.0x"）
   - MD3 Slider（0.8x - 1.5x，步进 0.1），拖动时实时预览
   - 底部说明："1.0x = 系统默认，> 1.0 放大字体，< 1.0 缩小字体"
5. 实时预览区：展示标题文字 + 主按钮效果（含当前字体缩放）

**布局与显示设置页面结构:**

1. 横竖屏断点区：
   - 顶部一行：标签"横竖屏断点" + 右侧 MD3 Switch（自动/手动）
   - 自动模式：显示"自动 · {设备类型} · {当前断点值}"（如"自动 · 桌面 · 1.20"），只读
   - 手动模式：MD3 Slider（1.00-2.00，步进 0.05）+ 实时数值显示
   - 底部说明文字："宽高比 ≥ 断点值时切换为横屏布局"
2. DPI 缩放区（与主题页联动，内容同上）

**DPI 自动/手动切换逻辑:**

```dart
// DPI 区域 Widget
Widget _buildDpiSection(BuildContext context, LayoutConfig config) {
  return Column(
    children: [
      Row(
        children: [
          Text('DPI 缩放'),
          Spacer(),
          Text(config.autoDpi ? '自动' : '手动'),
          MD3Switch(
            value: config.autoDpi,
            onChanged: (v) => updateLayoutConfig(
              config..autoDpi = v,
            ),
          ),
        ],
      ),
      if (config.autoDpi)
        Text('自动 (${_effectiveDpiLabel})x')  // 只读，显示自动计算结果
      else
        MD3Slider(
          value: config.dpiScale,
          min: AppConstants.minDpiScale,
          max: AppConstants.maxDpiScale,
          divisions: ((AppConstants.maxDpiScale - AppConstants.minDpiScale) /
                      AppConstants.dpiStep).round(),
          label: '${config.dpiScale.toStringAsFixed(1)}x',
          onChanged: (v) => updateLayoutConfig(config..dpiScale = v),
        ),
    ],
  );
}
```

#### 涉及文件

- `lib/core/theme/theme_controller.dart`
- `lib/core/theme/md3_color_scheme.dart`
- `lib/features/settings/theme_settings_page.dart`
- `lib/features/settings/layout_settings_page.dart`
- `lib/shared/widgets/md3_slider.dart`

---

### TASK-05: 导航与主页

| 属性 | 值 |
|------|-----|
| **ID** | TASK-05 |
| **优先级** | P1 |
| **依赖** | TASK-01, TASK-02, TASK-03 |
| **预估复杂度** | 高 |
| **状态** | 待开发 |

#### 概述

实现应用主页和自适应导航栏。主页展示已启用模块的摘要卡片，导航栏在主页和各已启用模块间切换。导航栏位置根据布局模式自动切换：竖屏时在底部，横屏时在左侧。右上角设置入口。当已启用模块较多导致导航栏空间不足时，提供滚动显示功能，确保所有模块均可访问。

#### 验收标准

- [ ] 主页为应用默认入口页面
- [ ] 顶部应用栏：左侧应用名称，右上角设置图标（点击进入设置页）
- [ ] 模块卡片区域仅展示已启用模块，每个卡片含图标、名称、摘要数据
- [ ] 卡片排列方式根据 `LayoutMode` 自动切换：竖屏单列、横屏双列网格
- [ ] 同步状态卡片固定在模块卡片列表最底部（最后位置）
- [ ] 同步状态卡片显示：绿色圆点 + "数据已同步 · HH:MM"（或同步中/失败状态）
- [ ] 导航栏第一项固定为"主页"，后续项为已启用模块（按 `displayOrder` 排列）
- [ ] 点击导航栏项切换页面，当前项高亮（强调色指示器）
- [ ] 模块启用/停用变更后，卡片列表和导航栏实时更新
- [ ] **竖屏模式（portrait）：导航栏在底部，图标 + 文字水平排列**
- [ ] **横屏模式（landscape）：导航栏在左侧，图标 + 文字垂直排列，设置入口移至导航栏底部**
- [ ] 横竖屏切换时导航栏位置平滑过渡，当前选中项保持
- [ ] 导航栏组件通过 `ResponsiveBuilder` 根据 `LayoutMode` 切换，不使用 `Platform.is*` 判定
- [ ] **导航栏空间不足时滚动显示**：竖屏底部导航栏可水平滚动，横屏左侧导航栏可垂直滚动
- [ ] 滚动时当前选中项自动滚动到可见区域
- [ ] 触控模式下支持惯性滑动，键鼠模式下支持滚轮滚动
- [ ] 滚动区域不遮挡设置入口（竖屏设置入口在 AppBar 右上角，横屏设置入口在导航栏底部固定位置）

#### 技术细节

**竖屏页面结构（导航栏在底部）:**

```
┌─────────────────────────┐
│  AppBar: 🏭 工具台                           ⚙️ │  ← 主页右上角设置入口
├─────────────────────────┤
│  ┌───────────────────┐      │
│  │ 🔢 计数器    1,248                   │     │ ← 模块卡片（单列）
│  └───────────────────┘      │
│  ┌───────────────────┐      │
│  │ ⏱️ 计时器    02:34                   │      │
│  └───────────────────┘      │
│  ┌───────────────────┐      │
│  │ ✅ 检查表     3/5                   │      │
│  └───────────────────┘      │
│  ┌───────────────────┐      │
│  │ 🟢 已同步 · 10:42                  │      │  ← 同步状态卡片（固定最后）
│  └───────────────────┘      │
├─────────────────────────┤
│ 🏠主页  🔢  ⏱️  ✅                              │  ← 底部导航栏 (BottomNavigationBar)
└─────────────────────────┘
```

**横屏页面结构（导航栏在左侧）:**

```
┌───┬──────────────────────────────┐
│      │  AppBar: 🏭 工具台       ⚙️  │← 设置入口在主页右上角    │
│  🏠  ├──────────────────────────────┤
│ 主页 │  ┌─────────┐  ┌─────────┐            │
│      │  │🔢 计数器 │  │⏱️ 计时器│   │  ← 双列网格
│  🔢  │  │  1,248  │  │  02:34  │   │
│ 计数 │  └─────────┘  └─────────┘            │
│      │  ┌─────────┐  ┌─────────┐            │
│  ⏱️  │  │✅ 检查表 │  │🟢 已同步 │   │
│ 计时 │  │   3/5   │  │  10:42  │   │
│      │  └─────────┘  └─────────┘   │
│  ✅  │                                                           │
│ 检查 │                                                            │
│      │                                                            │
│      │                                                            │
└───┴──────────────────────────────┘
  ↑ NavigationRail (左侧)
```

**导航栏自适应实现:**

```dart
// HomePage 继承 ConsumerWidget，通过 ref 读取布局状态和模块列表
class HomePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutController = ref.watch(layoutControllerProvider);
    final selectedIndex = ref.watch(_selectedNavIndexProvider);
    final navItems = ref.watch(navItemsProvider);

    // 使用 ResponsiveBuilder 根据 LayoutMode 切换导航栏
    return ResponsiveBuilder(
      portraitBuilder: (context) => _BottomNavScaffold(
        items: navItems,
        currentIndex: selectedIndex,
        onItemSelected: (i) => ref.read(_selectedNavIndexProvider.notifier).state = i,
        body: content,
      ),
      landscapeBuilder: (context) => _RailNavScaffold(
        items: navItems,
        currentIndex: selectedIndex,
        onItemSelected: (i) => ref.read(_selectedNavIndexProvider.notifier).state = i,
        body: content,
      ),
    );
  }
}

// 选中项索引用 StateProvider 管理
final _selectedNavIndexProvider = StateProvider<int>((ref) => 0);

// 竖屏：底部导航栏（可水平滚动）
class _BottomNavScaffold extends StatelessWidget {
  // 使用 Scaffold + 自定义底部导航栏
  // 设置入口保留在 AppBar 右上角 (actions)
  // 导航项超出屏幕宽度时启用 SingleChildScrollView 水平滚动
  // 每项固定宽度 72dp，选中态有强调色指示条
  // 触控模式: BouncingScrollPhysics 惯性滑动
  // 键鼠模式: ClampingScrollPhysics + 滚轮支持
}

// 横屏：左侧导航栏（可垂直滚动）
class _RailNavScaffold extends StatelessWidget {
  // 使用 Row 包裹 导航栏 + Expanded(content)
  // 导航项高度 72dp，超出屏幕高度时启用垂直滚动
  // 设置入口固定在导航栏底部（不参与滚动）
  // 滚动区域 = Expanded(SingleChildScrollView)
  // 底部设置图标 = Column[ 滚动区域, 设置图标 ]
  // 键鼠模式下导航项支持 hover 高亮
}
```

**导航栏滚动实现:**

```dart
/// 竖屏底部导航栏（可水平滚动）
class ScrollableBottomNav extends StatefulWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  // 每项固定宽度 72dp（图标32 + 文字 + padding）
  static const double itemWidth = 72.0;
  static const double itemHeight = 60.0;
}

class _ScrollableBottomNavState extends State<ScrollableBottomNav> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(ScrollableBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 选中项变化时，自动滚动到可见区域
    if (widget.currentIndex != oldWidget.currentIndex) {
      _ensureVisible(widget.currentIndex);
    }
  }

  void _ensureVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      final viewportWidth = _controller.position.viewportDimension;
      final itemOffset = index * ScrollableBottomNav.itemWidth;
      final itemEnd = itemOffset + ScrollableBottomNav.itemWidth;
      final currentOffset = _controller.offset;
      final currentEnd = currentOffset + viewportWidth;

      if (itemOffset < currentOffset) {
        _controller.animateTo(itemOffset,
            duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      } else if (itemEnd > currentEnd) {
        _controller.animateTo(itemEnd - viewportWidth,
            duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);
    return SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      // 触控: 惯性滑动; 键鼠: 精确滚动 + 滚轮
      physics: inputMode == InputMode.touch
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      child: Row(
        children: List.generate(widget.items.length, (i) {
          return _NavItemButton(
            item: widget.items[i],
            selected: i == widget.currentIndex,
            onTap: () => widget.onItemSelected(i),
          );
        }),
      ),
    );
  }
}

/// 横屏左侧导航栏（可垂直滚动，设置入口固定底部）
class ScrollableRailNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // 滚动区域（导航项）
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              physics: inputMode == InputMode.touch
                  ? const BouncingScrollPhysics()
                  : const ClampingScrollPhysics(),
              child: Column(
                children: List.generate(items.length, (i) {
                  return _RailNavItemButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onItemSelected(i),
                  );
                }),
              ),
            ),
          ),
          // 设置入口（固定在底部，不参与滚动）
          _RailNavItemButton(
            item: NavItem(
                icon: Icons.settings, label: '设置', moduleId: 'settings'),
            selected: false,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}
```

**导航项数据结构:**

```dart
class NavItem {
  final IconData icon;
  final String label;
  final String moduleId;  // "home" 或模块 id

  const NavItem({required this.icon, required this.label, required this.moduleId});
}

// 第一项固定为主页:
// NavItem(icon: Icons.home, label: '主页', moduleId: 'home')
// 后续项从已启用模块列表生成
```

**横竖屏切换时的状态保持:**

切换布局模式时，当前选中的导航项索引（`selectedIndex`）保持不变。底部导航栏和左侧导航栏共享同一份 `navItems` 数据和 `selectedIndex` 状态，切换后用户仍在同一页面，仅导航栏位置和形态变化。

**摘要数据获取:**

各模块卡片显示的摘要数据（如计数器显示今日计数）由各模块自行提供。当前框架阶段，卡片显示占位数据即可。定义 `ModuleSummaryProvider` 接口，后续各功能模块实现此接口提供真实数据：

```dart
abstract class ModuleSummaryProvider {
  String get summaryLabel;   // 如 "今日产线计数"
  String get summaryValue;   // 如 "1,248"
}
```

#### 涉及文件

- `lib/features/home/home_page.dart`
- `lib/features/home/module_card_widget.dart`
- `lib/features/home/sync_status_widget.dart`

---

### TASK-06: 设置页

| 属性 | 值 |
|------|-----|
| **ID** | TASK-06 |
| **优先级** | P2 |
| **依赖** | TASK-01, TASK-02, TASK-04, TASK-07 |
| **预估复杂度** | 中 |
| **状态** | 待开发 |

#### 概述

设置页分为三大分区：**全局设置**、**同步设置**、**模块设置**。同步设置和模块设置各带总开关，关闭开关时折叠隐藏对应分区的所有子选项。MD3 分组列表布局，每项显示当前配置摘要值，点击进入对应子页面。

#### 页面结构

```
设置页
├── 全局设置（始终展开）
│   ├── 主题与配色      → ThemeSettingsPage
│   ├── 布局与显示      → LayoutSettingsPage
│   ├── 字体大小        → FontSizeSettingsPage（内联滑块）
│   └── 关于应用        → AboutPage（可选）
│
├── 同步设置（带总开关 Switch）
│   │  [开关关闭] → 仅显示开关行，下方所有子项隐藏
│   │  [开关开启] → 展开下方子项：
│   ├── WebDAV 服务器   → 服务器地址配置（内联输入或子页面）
│   ├── 账号凭据        → 用户名 / 密码配置
│   ├── 同步频率        → 下拉选择（手动 / 5min / 15min / 60min）
│   ├── 立即同步        → 触发按钮 + 状态显示
│   └── 同步状态        → "已连接 · HH:MM" 或 "未配置" 或 "同步中…"
│
└── 模块设置（带总开关 Switch）
    │  [开关关闭] → 仅显示开关行，下方所有子项隐藏
    │  [开关开启] → 展开各模块条目：
    ├── 计数器          → 模块开关 + 模块专属设置入口
    ├── 计时器          → 模块开关 + 模块专属设置入口
    └── 检查表          → 模块开关 + 模块专属设置入口
```

#### 验收标准

**全局设置:**
- [ ] 全局设置分区始终展开，不设总开关
- [ ] 主题与配色项右侧显示摘要 "{mode} · {colorName}"，点击跳转 ThemeSettingsPage
- [ ] 布局与显示项右侧显示摘要 "断点 {自动|bp} · DPI {自动|dpi}x"，点击跳转 LayoutSettingsPage
- [ ] 字体大小项内联显示当前缩放值（如 "1.0x"），点击展开滑块（0.8-1.5，步进 0.1），实时预览
- [ ] 关于应用项右侧显示 "v{version}"，点击进入 AboutPage（可选）

**同步设置:**
- [ ] 同步设置分区头部带 MD3 Switch 总开关，默认关闭
- [ ] 开关关闭时：仅显示开关行，WebDAV 相关子项全部隐藏（不渲染，非折叠）
- [ ] 开关开启时：展开 WebDAV 配置子项，自动尝试读取已有配置填充
- [ ] WebDAV 服务器地址项：点击可内联编辑或跳转子页面输入
- [ ] 账号凭据项：用户名明文显示，密码以 "•••••" 掩码显示，点击进入编辑
- [ ] 同步频率项：右侧下拉选择（手动 / 5min / 15min / 60min），默认 5min
- [ ] 立即同步项：按钮样式，点击触发同步，同步中显示 "同步中…" 并禁用按钮
- [ ] 同步状态项：显示 "已连接 · HH:MM" 或 "未配置" 或 "同步失败 · 原因"
- [ ] 关闭同步开关时弹出确认对话框："关闭同步将停止自动同步，已同步数据保留在本地。确定关闭？"
- [ ] SyncConfig.enabled = false 时，SyncService 停止自动同步定时器

**模块设置:**
- [ ] 模块设置分区头部带 MD3 Switch 总开关，默认开启
- [ ] 开关关闭时：仅显示开关行，各模块条目全部隐藏（不渲染）
- [ ] 开关开启时：列出所有已注册模块，每项含模块图标 + 名称 + 独立开关
- [ ] 模块条目右侧的独立开关控制该模块在导航栏/主页的显示（ModuleState.enabled）
- [ ] 模块条目点击（非开关区域）进入该模块的专属设置页（由子项目提供，无专属设置则不跳转）
- [ ] 模块排序：通过长按拖拽调整 displayOrder（可选，首版可不做）
- [ ] 关闭模块总开关时弹出确认对话框："关闭模块设置后，所有模块将从导航栏隐藏。确定关闭？"

**通用:**
- [ ] 点击设置项有 MD3 ripple 涟漪效果
- [ ] 子页面修改配置后返回，设置项摘要值实时更新
- [ ] 分区标签为静态文本，不可点击
- [ ] 开关切换有 MD3 动画过渡

#### 技术细节

**分区与开关状态绑定:**

```dart
/// 设置页状态结构
class SettingsPageState {
  // 同步设置开关 — 对应 SyncConfig.enabled
  bool syncEnabled;         // 读取/写入 SyncConfig.enabled

  // 模块设置开关 — 独立于单个模块的 enabled，控制模块设置分区是否展开
  bool moduleSettingsEnabled; // 默认 true，持久化到 SharedPreferences
}
```

> **区分两个概念**：
> - `SyncConfig.enabled`：同步功能总开关，关闭后 WebDAV 子项隐藏 + SyncService 停止定时器
> - `moduleSettingsEnabled`：模块设置分区展开开关，关闭后仅隐藏设置页中的模块条目，不影响已启用模块的实际运行
> - 单个模块的 `ModuleState.enabled`：控制模块是否在导航栏/主页显示，在模块设置分区内独立切换

**设置项分组:**

| 分区 | 设置项 | 右侧摘要值格式 | 跳转目标 | 显示条件 |
|------|--------|---------------|----------|----------|
| 全局设置 | 主题与配色 | "{mode} · {colorName}" | ThemeSettingsPage | 始终显示 |
| 全局设置 | 布局与显示 | "断点 {自动\|bp} · DPI {自动\|dpi}x" | LayoutSettingsPage | 始终显示 |
| 全局设置 | 字体大小 | "{fontScale}x" | 内联滑块 | 始终显示 |
| 全局设置 | 关于应用 | "v{version}" | AboutPage | 始终显示 |
| 同步设置 | WebDAV 服务器 | "{url}" 或 "未配置" | ServerConfigPage | syncEnabled=true |
| 同步设置 | 账号凭据 | "{username}" | CredentialPage | syncEnabled=true |
| 同步设置 | 同步频率 | "{frequency}" | 内联下拉 | syncEnabled=true |
| 同步设置 | 立即同步 | "同步中…" 或 按钮态 | 触发动作 | syncEnabled=true |
| 同步设置 | 同步状态 | "已连接 · HH:MM" 等 | 无 | syncEnabled=true |
| 模块设置 | {模块名} | 开/关 | 模块专属设置页 | moduleSettingsEnabled=true |

**开关交互流程:**

```
同步设置开关切换:
  OFF → ON:
    1. 展开子项列表（MD3 Expansion 动画）
    2. 读取 SyncConfig 填充已有值
    3. 启动 SyncService 自动同步定时器（如有有效配置）

  ON → OFF:
    1. 弹出确认对话框
    2. 用户确认 → 隐藏子项列表 → 停止 SyncService 定时器
    3. 用户取消 → 开关恢复 ON 状态

模块设置开关切换:
  OFF → ON:
    1. 展开模块列表（读取 module_registry 中所有已注册模块）
    2. 每个模块显示当前 ModuleState.enabled 状态

  ON → OFF:
    1. 弹出确认对话框
    2. 用户确认 → 隐藏模块列表（不影响模块实际运行状态）
    3. 用户取消 → 开关恢复 ON 状态
```

#### 涉及文件

- `lib/features/settings/settings_page.dart` — 主设置页，三大分区布局
- `lib/features/settings/widgets/settings_section.dart` — 分区容器组件（含可选开关头部）
- `lib/features/settings/widgets/settings_list_tile.dart` — 设置项条目组件
- `lib/features/settings/pages/theme_settings_page.dart` — 主题与配色子页面
- `lib/features/settings/pages/layout_settings_page.dart` — 布局与显示子页面
- `lib/features/settings/pages/sync_settings_page.dart` — WebDAV 同步配置子页面
- `lib/features/settings/pages/module_settings_page.dart` — 模块管理子页面

---

### TASK-07: WebDAV 数据同步

| 属性 | 值 |
|------|-----|
| **ID** | TASK-07 |
| **优先级** | P1 |
| **依赖** | TASK-00, TASK-01 |
| **预估复杂度** | 高 |
| **状态** | 待开发 |

#### 概述

实现基于 WebDAV 协议的数据同步系统。支持手动同步和自动定时同步，提供连接测试、同步状态反馈、冲突解决机制。

#### 验收标准

- [ ] WebDAV 配置页面包含：服务器地址、用户名、密码（密文）、自动同步频率下拉选择
- [ ] "测试连接"按钮发送 PROPFIND 请求验证连通性和凭据
- [ ] 连接成功显示绿色提示，失败显示红色提示并附带错误原因
- [ ] "立即同步"按钮触发同步流程：按钮变为"同步中…"并禁用，完成后恢复
- [ ] 同步完成后更新状态卡片："数据已同步 · HH:MM"
- [ ] 自动同步按配置频率在后台定时执行（5min / 15min / 60min）
- [ ] `SyncConfig.enabled = false` 时，自动同步定时器不启动；切换为 true 时启动
- [ ] 同步开关关闭期间，"立即同步"按钮也不可用（整个同步功能被禁用）
- [ ] 密码使用 `flutter_secure_storage` 加密存储
- [ ] 网络不可用时提示"网络不可用，请检查连接"，自动同步跳过本次
- [ ] 认证失败（401/403）时提示"认证失败，请检查用户名和密码"
- [ ] 服务器超时时提示"无法连接到服务器，请检查地址或网络"
- [ ] 数据冲突采用"最后修改时间优先"策略，旧版本自动归档
- [ ] 每个设备使用独立的 WebDAV 存储路径（基于设备标识）

#### 技术细节

**WebDAV 操作:**

| 操作 | HTTP 方法 | 说明 |
|------|-----------|------|
| 测试连接 | `PROPFIND` | 请求根目录属性，验证认证和连通性 |
| 上传数据 | `PUT` | 将本地数据 JSON 写入服务器文件 |
| 下载数据 | `GET` | 拉取服务器端最新数据 |
| 创建目录 | `MKCOL` | 为设备创建独立存储路径 |
| 列出文件 | `PROPFIND` | 获取服务器端文件列表 |

**同步流程:**

```
1. 读取本地所有数据 (StorageService)
2. 从 WebDAV 拉取服务器端数据 (GET)
3. 对比本地与服务器数据的 lastModified 时间戳
4. 本地较新 → 上传到服务器 (PUT)
5. 服务器较新 → 更新本地 (StorageService)
6. 两端均修改 → 保留较新版本，旧版本归档到 /archive/
7. 更新 lastSyncTime 和 lastSyncStatus
8. 通知 UI 更新同步状态卡片
```

**设备标识:**

无用户体系下，通过 `DeviceInfoProvider.deviceId` 获取设备唯一标识（见第 3.8 节抽象层）。该接口在各平台有独立实现，UI 层和同步层不直接调用平台专有 API：

```dart
// 同步服务中获取设备标识
final deviceId = deviceInfoProvider.deviceId;
// deviceId 由 DeviceInfoProvider 实现类提供:
//   Windows: 注册表 MachineGuid 或自生成 UUID
//   macOS:   IOPlatformUUID 或自生成 UUID
//   Android: Settings.Secure.ANDROID_ID 或自生成 UUID
//   iOS:     identifierForVendor 或自生成 UUID
//   HarmonyOS: 系统分布式设备标识 或自生成 UUID
// 所有平台: 获取失败时自生成 UUID 并持久化到 flutter_secure_storage
```

WebDAV 存储路径基于 deviceId：

```
{webdavUrl}/{deviceId}/data.json
{webdavUrl}/{deviceId}/config.json
{webdavUrl}/{deviceId}/archive/
```

**自动同步实现:**

使用 `Timer.periodic` 或 `workmanager` 后台任务，按 `SyncFrequency` 配置间隔触发同步。应用在前台时使用 `Timer.periodic`；后台同步为可选项（依赖平台限制）。

#### 涉及文件

- `lib/core/sync/webdav_client.dart`
- `lib/core/sync/sync_service.dart`
- `lib/core/sync/conflict_resolver.dart`
- `lib/features/settings/sync_settings_page.dart`

---

### TASK-08: 输入模式适配（触控与键鼠）

| 属性 | 值 |
|------|-----|
| **ID** | TASK-08 |
| **优先级** | P0 (阻塞) |
| **依赖** | TASK-00 |
| **预估复杂度** | 高 |
| **状态** | 待开发 |

#### 概述

实现输入模式自动检测与切换系统。通过监听 Pointer 事件判定当前输入设备类型（触控/键鼠），自动切换交互行为。所有自适应组件根据 `InputMode` 调整点击区域大小、悬停态、右键菜单、键盘快捷键等行为。确保 Windows 键鼠用户和移动端触控用户均获得原生级别的操作体验。

#### 验收标准

- [ ] `InputController` 通过 `Listener` Widget 监听全局 Pointer 事件，自动判定 `InputMode`
- [ ] 首次输入事件前，根据 `PlatformInfo.defaultInputMode` 设置初始模式
- [ ] 检测到 `PointerDownEvent` 且 `kind == PointerDeviceKind.touch` → 切换到 `InputMode.touch`
- [ ] 检测到 `PointerHoverEvent` 或 `PointerDownEvent` 且 `kind == PointerDeviceKind.mouse` → 切换到 `InputMode.mouse`
- [ ] 模式切换时通过 `InputModeScope` (InheritedWidget) 通知所有子树重建
- [ ] **触控模式行为**: 最小点击区域 48x48dp (MD3 规范)，无悬停态，列表项高度 >= 56dp，卡片可滑动操作
- [ ] **键鼠模式行为**: 精确点击区域，按钮和卡片支持 hover 高亮，列表项高度紧凑 (48dp)，支持右键上下文菜单
- [ ] `AdaptiveButton` 组件：触控模式使用 `minHeight: 48` 的 `FilledButton`，键鼠模式使用标准高度 + `MouseRegion` hover 效果
- [ ] `AdaptiveListTile` 组件：触控模式 `minVerticalPadding: 16`，键鼠模式 `minVerticalPadding: 8` + 右键菜单回调
- [ ] Windows 触屏笔记本场景：触控时自动切换到 touch 模式，切回鼠标时自动切换到 mouse 模式
- [ ] 自适应组件代码中不含 `Platform.is*` 调用，仅依赖 `InputMode` 判定
- [ ] 所有 `features/` 和 `shared/` 下的交互组件均使用自适应组件，不直接使用 `IconButton`/`TextButton` 等未适配组件

#### 技术细节

**输入模式检测架构:**

```dart
/// 在 MaterialApp builder 中注入全局 Listener
Widget builder(BuildContext context, Widget? child) {
  return ListenableBuilder(
    listenable: inputController,
    builder: (context, _) {
      return InputModeScope(
        mode: inputController.currentMode,
        child: Listener(
          onPointerDown: (event) => inputController.handlePointerDown(event),
          onPointerHover: (event) => inputController.handlePointerHover(event),
          child: child!,
        ),
      );
    },
  );
}
```

**InputController 核心逻辑:**

```dart
class InputController extends ChangeNotifier {
  InputMode _currentMode;
  DateTime _lastSwitchTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const _switchDebounce = Duration(milliseconds: 300);

  InputController(PlatformInfo platformInfo)
      : _currentMode = platformInfo.defaultInputMode;

  InputMode get currentMode => _currentMode;

  void handlePointerDown(PointerDownEvent event) {
    final newMode = event.kind == PointerDeviceKind.touch
        ? InputMode.touch
        : InputMode.mouse;
    _switchTo(newMode);
  }

  void handlePointerHover(PointerHoverEvent event) {
    // hover 事件只可能来自鼠标
    _switchTo(InputMode.mouse);
  }

  void _switchTo(InputMode newMode) {
    if (newMode == _currentMode) return;
    // 防抖：避免触屏笔记本上频繁切换
    final now = DateTime.now();
    if (now.difference(_lastSwitchTime) < _switchDebounce) return;

    _currentMode = newMode;
    _lastSwitchTime = now;
    notifyListeners();
  }
}
```

**自适应组件示例 — AdaptiveButton:**

```dart
class AdaptiveButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AdaptiveButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final inputMode = InputModeScope.of(context);

    if (inputMode == InputMode.touch) {
      // 触控模式：大点击区域
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon) : null,
        label: Text(label),
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      );
    } else {
      // 键鼠模式：精确点击 + hover 效果 (MD3 FilledButton 自带 hover)
      return FilledButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 18) : null,
        label: Text(label),
      );
    }
  }
}
```

**交互行为差异对照表:**

| 交互元素 | 触控模式 (touch) | 键鼠模式 (mouse) |
|----------|------------------|------------------|
| 按钮最小尺寸 | 48x48 dp | 默认尺寸 |
| 列表项高度 | >= 56 dp | >= 48 dp |
| 卡片点击区域 | 整个卡片可点击 | 整个卡片可点击，hover 时边框高亮 |
| 右键菜单 | 不支持（长按替代） | 支持，右键弹出上下文菜单 |
| 滚动方式 | 惯性滑动 | 滚轮滚动 |
| 文本选择 | 长按选择 | 鼠标拖选 |
| 悬停反馈 | 无 | 背景色变化 / 阴影加深 / 边框高亮 |
| 键盘快捷键 | 不适用 | 支持 (如 Ctrl+S 同步, Esc 返回) |

**键盘快捷键（键鼠模式专用）:**

| 快捷键 | 功能 | 适用页面 |
|--------|------|----------|
| `Esc` | 返回上一页 | 所有子页面 |
| `Ctrl+S` | 立即同步 | 主页 / 设置页 |
| `Ctrl+,` | 打开设置 | 主页 |
| `Alt+Left` | 导航后退 | 所有页面 |
| `Tab` / `Shift+Tab` | 焦点切换 | 所有页面 |

> 键盘快捷键通过 `Shortcuts` + `Actions` Widget 实现，仅在 `InputMode.mouse` 下激活。触控模式下快捷键不注册，避免影响虚拟键盘行为。

#### 涉及文件

- `lib/core/input/input_controller.dart`
- `lib/core/input/input_detector.dart`
- `lib/core/input/input_mode_scope.dart`
- `lib/shared/widgets/adaptive_button.dart`
- `lib/shared/widgets/adaptive_list_tile.dart`
- `lib/shared/utils/input_mode_helper.dart`

---

## 6. 任务依赖图

### 6.1 主项目（APP 底座）内部依赖

```
TASK-00 (项目初始化 + 平台抽象层)
  │
  ├──→ TASK-08 (输入模式适配) ← P0 阻塞，与 TASK-01 并行
  │
  ├──→ TASK-01 (存储层)
  │      │
  │      ├──→ TASK-02 (模块管理 + 契约接口冻结)
  │      │      │
  │      │      └──→ TASK-05 (导航与主页) ←── TASK-03 (响应式布局)
  │      │                 │                 ←── TASK-08 (输入适配，提供自适应组件)
  │      │                 │
  │      ├──→ TASK-03 (响应式布局)
  │      │
  │      ├──→ TASK-04 (主题系统)
  │      │      │
  │      │      └──→ TASK-06 (设置页)
  │      │
  │      └──→ TASK-07 (WebDAV 同步)
  │               │
  │               └──→ TASK-06 (设置页)
  │
  └──→ (所有任务均依赖 TASK-00)

可并行开发的任务组:
  • 组 A: TASK-01 + TASK-08 (均仅依赖 TASK-00，互相独立)
  • 组 B: TASK-02 + TASK-03 + TASK-04 + TASK-07 (均仅依赖 00+01，互相独立)
  • 组 C: TASK-05 (依赖 01+02+03+08)
  • 组 D: TASK-06 (依赖 01+02+04+07，最后开发)
```

### 6.2 主项目与子项目跨层依赖

```
Phase A: APP 底座（主项目）
  TASK-00 → TASK-01+08 → TASK-02+03+04+07 → TASK-05 → TASK-06
                                                      │
                                         底座交付 + ModuleContract 接口冻结
                                                      │
                                                      ↓
Phase B: 子项目并行开发（独立需求规格）
  ├── 计数器模块 ──┐
  ├── 计时器模块 ──┤  各子项目仅依赖冻结后的 ModuleContract
  └── 检查表模块 ──┘  互相无依赖，可并行
                      │
                      ↓
Phase C: 集成验收
  注册模块 → 集成测试 → 全平台验证 → 发布 v1.0
```

> **关键里程碑**: TASK-02 完成后 `ModuleContract` 接口冻结，子项目可提前进入需求编写和接口对齐阶段（Step 1-2），但编码开发（Step 3）须等 Phase A 全部完成。

### 推荐开发顺序

| 阶段 | 任务 | 项目层 | 说明 |
|------|------|--------|------|
| Phase 1 | TASK-00 → TASK-01 + TASK-08 (并行) | 主项目 | 基础设施 + 输入适配框架，阻塞所有后续任务 |
| Phase 2 | TASK-03 + TASK-04 + TASK-07 (并行) | 主项目 | 核心能力层，互相无依赖 |
| Phase 3 | TASK-02 | 主项目 | 模块管理 + 契约接口冻结（里程碑：子项目可开始需求编写） |
| Phase 4 | TASK-05 | 主项目 | 导航与主页（依赖模块管理 + 响应式布局 + 输入适配） |
| Phase 5 | TASK-06 | 主项目 | 设置页（依赖所有子页面就绪）→ **Phase A 完成** |
| Phase 6 | 计数器 + 计时器 + 检查表 (并行) | 子项目 | 各模块独立开发，实现 ModuleContract |
| Phase 7 | 集成测试 + 验收 | 跨层 | 注册模块、全平台验证、发布 v1.0 |

---

## 7. 开放问题

以下问题需与需求方确认后才能进入对应任务的开发：

| # | 问题 | 影响任务 | 当前假设 |
|---|------|----------|----------|
| Q1 | ~~预设模块清单是否确认为 6 个？是否需要增减？~~ **已确认：首发 3 个模块（计数器、计时器、检查表），均默认启用，后续可增减** | TASK-02, TASK-05 | 已定，3 个预设模块 |
| Q2 | 模块图标准确使用哪套图标库？Material Symbols 还是自定义？ | TASK-02 | 暂用 MD3 Material Symbols |
| Q3 | ~~横屏时导航栏是否从底部切换为侧边 NavigationRail？~~ **已确认：横屏左侧，竖屏底部，空间不足时可滚动** | TASK-05 | 已定，不再开放 |
| Q4 | WebDAV 后台同步是否需要支持应用未启动时触发？ | TASK-07 | 仅支持前台 Timer，不支持后台 |
| Q5 | ~~状态管理方案选择 Provider 还是 Riverpod？~~ **已确认：选择 Riverpod，编译时安全 + 无需 BuildContext + 独立可测试，更适合 Agent 驱动开发** | TASK-00 | 已定，使用 Riverpod |
| Q6 | 各功能模块（计数器等）的摘要数据接口何时定义？ | TASK-05 | 当前用占位数据，接口已预留 |
| Q7 | ~~设备标识方案：ANDROID_ID 还是自生成 UUID？~~ **已确认：通过 DeviceInfoProvider 抽象层统一获取，各平台优先使用原生标识，失败时自生成 UUID 持久化** | TASK-00, TASK-07 | 已定，见第 3.8 节 |
| Q8 | Windows 窗口最小尺寸确认为多少？是否需要支持全屏模式？ | TASK-00 | 最小 400x600，支持自由缩放和最大化 |
| Q9 | 鸿蒙平台是否使用 OpenHarmony Flutter 分支还是等待官方支持？ | TASK-00 | Phase 4 再定，当前不影响 Windows 开发 |
| Q10 | 键盘快捷键列表是否需要扩充或自定义？当前定义了 5 组。 | TASK-08 | 使用当前 5 组，后续可扩展 |
| Q11 | Windows 上是否需要系统托盘 (System Tray) 功能？ | TASK-00 | 首版不做，后续按需添加 |
| Q12 | macOS 平台是否需要支持 Touch Bar？ | TASK-08 | 不支持，保持与 Windows 一致的交互 |
| Q13 | ~~横竖屏断点和 DPI 是否支持自动/手动切换？~~ **已确认：均支持自动（默认）和手动模式，自动断点按设备类型判定，自动 DPI 桌面端按系统 DPI 计算** | TASK-03, TASK-04 | 已定，不再开放 |
| Q14 | 未来新增模块时，是否需要支持模块热更新/远程下载？还是仅通过 App 版本更新？ | TASK-02 | 仅通过 App 版本更新，模块清单随版本发布 |
| Q15 | 子项目是否需要独立 Git 仓库还是采用 Monorepo 子目录管理？ | 第 8 节 | 采用 Monorepo 子目录（`modules/`），通过 path 依赖引入 |
| Q16 | ~~设置页分区结构如何组织？同步和模块设置是否需要总开关？~~ **已确认：分为全局设置、同步设置、模块设置三大分区；同步设置和模块设置各带总开关，关闭时隐藏子项** | TASK-06 | 已定，见 TASK-06 |
| Q17 | 字体大小是否需要作为全局设置项？范围和步进如何？ | TASK-04, TASK-06 | 已定，fontScale 0.8-1.5，步进 0.1，见 ThemeConfig |

---

## 8. 项目管理

### 8.1 项目架构总览

本项目采用 **主项目 + 子项目** 的分层管理架构：

| 层级 | 项目 | 职责 | 规格文档 |
|------|------|------|----------|
| 主项目 | APP 底座 | 模块管理、导航结构、响应式布局、主题系统、数据同步、平台抽象、输入适配 | 本文档（`modular_tool_app_spec.md`） |
| 子项目 | 计数器模块 | 计数相关功能 | `modules/counter/README.md` |
| 子项目 | 计时器模块 | 计时相关功能 | `modules/timer/README.md` |
| 子项目 | 检查表模块 | 检查清单相关功能 | `modules/checklist/README.md` |

**核心原则**：子项目设计必须服从 APP 底座。底座定义契约接口和约束规范，子项目在约束范围内独立开发。

### 8.2 子项目约束基线

所有子项目必须遵守以下约束（引用本文档对应章节）：

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

### 8.3 子项目开发流程

每个子项目按以下流程独立开发：

```
┌─────────────────────────────────────────────────────┐
│  Step 1: 需求编写                                     │
│  • 在 modules/<module>/README.md 编写模块需求         │
│  • 引用本文档作为约束基线                              │
│  • 定义模块功能范围、数据模型、验收标准                  │
│  • 确认模块 definition（id、名称、图标、默认开关）       │
└──────────────────────┬──────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│  Step 2: 接口对齐                                     │
│  • 确认 ModuleContract 实现方案                        │
│  • 确认 ModuleSummary 数据结构                        │
│  • 确认 exportData/importData 数据格式                │
│  • 与底座 StorageService 确认存储 key 命名空间          │
└──────────────────────┬──────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│  Step 3: 独立开发                                     │
│  • 实现 ModuleContract 入口类                         │
│  • 开发模块主页 (ConsumerWidget)                      │
│  • 实现模块数据模型和存储逻辑                           │
│  • 开发模块私有组件                                    │
│  • 编写单元测试                                       │
└──────────────────────┬──────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│  Step 4: 集成测试                                     │
│  • 在主项目 module_registry.dart 注册模块              │
│  • 验证导航栏显示、主页卡片摘要                         │
│  • 验证主题适配（深色/浅色、强调色切换）                  │
│  • 验证布局适配（横屏/竖屏、不同断点）                   │
│  • 验证输入适配（触控/键鼠）                           │
│  • 验证数据同步（导出/导入往返一致性）                   │
└──────────────────────┬──────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────┐
│  Step 5: 验收发布                                     │
│  • 通过全部约束检查清单（第 8.2 节）                    │
│  • 通过集成测试                                       │
│  • 更新主项目版本号和模块清单                           │
│  • 随 App 版本发布                                    │
└─────────────────────────────────────────────────────┘
```

### 8.4 子项目需求文档模板

每个子项目的 `README.md` 应包含以下结构：

```markdown
# <模块名称> — 子项目需求文档

> **约束基线**: 本模块服从 `modular_tool_app_spec.md`（APP 底座开发规格）
> **模块 ID**: <module_id>
> **版本**: v0.1

## 1. 功能范围
（模块提供的功能列表和边界）

## 2. 数据模型
（模块私有数据结构定义，存储 key 命名空间: `module_<id>_*`）

## 3. ModuleContract 实现
- definition: { id, name, icon, enabledByDefault }
- summary: { 主标题, 副标题, 辅助信息 }
- exportData/importData: 数据格式说明

## 4. 页面设计
（模块主页布局描述，使用 MD3 组件和底座自适应组件）

## 5. 验收标准
（功能验收检查清单）

## 6. 依赖的底座能力
（列出本模块使用的底座服务和组件）
```

### 8.5 版本管理

| 版本号 | 说明 |
|--------|------|
| 主项目版本 (App Version) | `MAJOR.MINOR.PATCH`，随 App 整体发布递增。新增模块或底座能力更新时递增 |
| 模块版本 | 各子项目在 README.md 中独立维护版本号。模块变更需同步更新主项目模块清单 |
| 契约版本 | `ModuleContract` 接口版本。接口变更属于破坏性变更，需主项目 MINOR 版本递增并通知所有子项目适配 |

**发布规则**：
- 模块清单随 App 版本发布，不支持单独模块热更新（见 Q14）
- 新增模块：在主项目 `module_registry.dart` 注册 + App 版本 PATCH 递增
- 移除模块：从注册表移除 + App 版本 MINOR 递增（向下兼容，保留已存储数据）
- 契约变更：App 版本 MINOR 递增，所有已注册子项目须同步适配

### 8.6 开发阶段规划

```
Phase A: APP 底座框架开发（本文档 TASK-00 ~ TASK-08）
  │
  │  交付物: 可运行的空壳 App，含完整底座能力
  │  验收: 导航框架可用、模块注册表可注册空模块、主题/布局/输入适配可用
  │
  ↓
Phase B: 子项目并行开发（各模块独立推进）
  │
  │  ├── 计数器模块（modules/counter）
  │  ├── 计时器模块（modules/timer）
  │  └── 检查表模块（modules/checklist）
  │
  │  前置条件: Phase A 完成，ModuleContract 接口冻结
  │  并行性: 各子项目互相独立，可分配给不同开发者/Agent
  │
  ↓
Phase C: 集成与验收
  │
  │  • 逐一注册模块并执行集成测试（第 8.3 节 Step 4）
  │  • 全平台验证（Windows 优先，其余平台按 Phase 4 计划）
  │  • 发布 v1.0
  │
  ↓
Phase D: 持续迭代
  │
  │  • 新增模块: 按 Step 1-5 流程开发，注册后随版本发布
  │  • 底座升级: 保持 ModuleContract 向下兼容
  │  • 多平台扩展: macOS → Android → iOS → HarmonyOS
```

---

## 9. 配套文件索引

以下文件与本规格文档配套使用，构成完整的项目立项文档体系：

| 文件 | 路径 | 说明 | 面向读者 |
|------|------|------|----------|
| 开发者指南 | `guide.md` | 项目推进说明书，说明各阶段如何推进、Agent该读什么文件、产出什么交付物 | 所有人（入门必读） |
| 任务追踪清单 | `todo.md` | 每日任务状态追踪，按阶段分组的checkbox清单，含里程碑和阻塞项 | OWNER, DEV |
| 设计规范与ADR | `design.md` | 设计决策记录，含架构设计、状态管理、UI/UX、数据设计等7大章节的ADR | ARCH, DEV |
| 约束性规范文件 | `project_constraints.md` | Agent可读的约束性规范，含刚性约束、数据模型、模块契约、角色定义 | DEV, ARCH, QA |
| 开发任务分配文件 | `task_assignments.md` | Agent可执行的任务分配，含任务卡片、角色分工、RACI矩阵、交付物清单 | DEV, QA |
| 项目立项报告 | `ametoolbox-project-init/ametoolbox-project-init.html` | 人可读的HTML立项报告，含项目章程、角色分工、里程碑、风险等 | OWNER |

**阅读顺序建议**：
1. 新成员/Agent入门：先读 `guide.md` 了解项目全貌和推进方式
2. 日常开发：读 `todo.md` 领任务 → 读 `task_assignments.md` 看详情 → 读 `project_constraints.md` 查约束
3. 设计决策：参考 `design.md` 的ADR记录
4. 详细实现：查阅本规格文档（`modular_tool_app_spec.md`）对应章节
5. 项目全景：阅读HTML立项报告

> **项目性质**：个人项目 + AI Agent协作模式。团队由1名人类项目负责人（OWNER）+ 4个AI Agent角色（ARCH/DEV/QA/OPS）组成，详见 `project_constraints.md` 第9节。
