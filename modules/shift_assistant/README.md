# 倒班助手模块（shift_assistant）

本目录是 **倒班助手模块** 的独立开发与测试环境，与 AMEToolbox 主线底座 APP 严格隔离。

## 目录结构

```text
modules/shift_assistant/
├── android/              # Android 独立运行壳（如需）
├── ios/                  # iOS 独立运行壳（如需）
├── linux/                # Linux 独立运行壳（如需）
├── macos/                # macOS 独立运行壳（如需）
├── windows/              # Windows 独立运行壳（项目主要目标平台）
├── docs/                 # 模块专属文档（前缀 shift_assistant_）
│   ├── shift_assistant_design.md
│   ├── shift_assistant_plan.md
│   ├── shift_assistant_spec.md
│   └── shift_assistant_todo.md
├── lib/                  # 模块业务代码
│   ├── main.dart         # 独立运行入口
│   ├── core/storage/     # 隔离测试用的内存存储服务
│   └── features/shift_assistant/
│       ├── shift_assistant_module.dart   # ModuleContract 实现
│       ├── models/                       # 数据模型
│       ├── data/                         # Repository
│       ├── providers/                    # Riverpod Provider / Controller
│       ├── pages/                        # 页面
│       └── widgets/                      # 模块私有组件
├── test/                 # 单元测试 / Widget 测试
├── pubspec.yaml          # 子项目依赖（path 依赖 ametoolbox 底座）
└── analysis_options.yaml # 静态分析配置
```

## 独立运行

```bash
cd modules/shift_assistant
flutter run -d windows --debug
```

独立运行时使用 `lib/core/storage/memory_storage_service.dart` 覆盖底座的 `storageServiceProvider`，不访问 Hive 与文件系统，启动轻量、编译快速。

## 测试

```bash
cd modules/shift_assistant
flutter test
flutter analyze
```

## 合并到主项目

开发完成后，按以下步骤合并：

1. 将 `modules/shift_assistant/lib/features/shift_assistant/` 整体保留。
2. 在主项目 `lib/main.dart` 的 `StorageService.initialize()` 之后注册模块：

```dart
final shiftAssistant = ShiftAssistantModule();
await shiftAssistant.initialize(storage);
moduleRegistry.register(shiftAssistant);
```

3. 在主项目 `pubspec.yaml` 中添加 path 依赖：

```yaml
dependencies:
  shift_assistant_module:
    path: modules/shift_assistant
```

4. 不修改 APP 底座代码的前提下，模块内部所有 `package:shift_assistant_module/...` import 保持不动；底座侧仅新增注册入口。

## 约束

- 模块存储 key 前缀：`module_shift_assistant_`
- 不存储敏感数据（密码、设备 ID 等），全部交给底座
- `lib/features/` 与 `lib/shared/` 不出现 `Platform.is*` 或 `dart:io`
- UI 组件优先使用底座 `AdaptiveButton`、`AdaptiveIconButton`、`AdaptiveListTile`
