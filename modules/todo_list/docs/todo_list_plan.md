# 待办清单模块 — 子项目规划（临时应用调试方案）

> **文档类型**: 子项目开发与调试规划
> **模块 ID**: `todo_list`
> **版本**: v1.1
> **状态**: 已确认（OWNER 确认关键决策）
> **约束基线**: `design.md` + `project_constraints.md` + `todo_list_spec.md`

### 1.0 开发隔离硬约束（OWNER 确认）

- **临时底座开发期间，任何代码修改都不得涉及项目主线代码**（主线 `lib/`、主项目 `pubspec.yaml`、底座 `modules/` 下其他子模块）。
- 临时应用全部文件**仅存在于** `modules/todo_list/` 内，完全自包含。
- 唯一可能触碰主线的时点是**合并进主线（M4）**，且必须事先经 OWNER 确认。

---

## 1. 目标与范围

### 1.1 目标

在**不动底座 APP 主线代码**的前提下，为待办清单模块建立**独立临时调试应用**，完成模块界面与设置页的横竖屏布局调试；调试通过后，将模块正式代码**移植合并进项目主线**（通过 `ModuleRegistry` + pubspec path 依赖注册），随后**删除临时应用**，与主线一同进行后续 debug 与首页卡片开发。

### 1.2 范围

| 阶段 | 内容 | 是否触碰底座 |
|------|------|--------------|
| 临时应用搭建 | 模块目录内新增独立运行壳 + 临时入口 | 否 |
| 界面调试 | 待办主页面（类日历 + 列表）、详情页、新增/编辑表单、横竖屏布局 | 否 |
| 设置页调试 | 分类、提醒、导出设置页 | 否 |
| 合并进主线 | 注册 `ModuleRegistry`、主项目 `pubspec.yaml` 加 path 依赖、`main.dart` 注册 | **是（需 OWNER 确认）** |
| 删除临时应用 | 移除独立运行壳与临时入口 | 否 |
| 后续 | 首页卡片（`buildDashboardWidgets` / `buildEntryCard`）、整体 debug | 与主线共同进行 |

---

## 2. 底座 API 清单（临时应用引用）

临时应用需提供/复用的底座 Provider 与组件如下（均位于主线 `lib/`）：

### 2.1 Riverpod Provider（`lib/core/providers/`）

| Provider | 类型 | 提供方式 | 临时应用处理 |
|----------|------|----------|--------------|
| `storageServiceProvider` | `Provider<StorageService>` | 需 override | **内存实现**（见 §3.2） |
| `platformInfoProvider` | `Provider<PlatformInfo>` | 有默认 `PlatformInfoImpl()` | 保留默认 |
| `deviceInfoProvider` | `Provider<DeviceInfoProvider>` | 需 override | **简化实现**（固定值，规避 Windows 内存异常） |
| `themeControllerProvider` | `Provider<ThemeController>` | 需 override | 用 `ThemeController(storage)` 真实实现 |
| `layoutControllerProvider` | `ChangeNotifierProvider<LayoutController>` | 需 override | 用真实 `LayoutController`（横竖屏调试关键） |
| `inputControllerProvider` | `Provider<InputController>` | 需 override | 用真实 `InputController` |
| `notificationServiceProvider` | `Provider<NotificationService>` | 有默认 | **no-op 实现**（临时应用不调试真实通知） |
| `moduleControllerProvider` | `Provider<ModuleController>` | 需 override | 临时应用可不提供（直接挂载模块页面） |
| `syncServiceProvider` | `Provider<SyncService>` | 需 override | 临时应用可不提供（不调试同步） |

### 2.2 布局 / 输入抽象

- `LayoutMode`（`lib/core/models/layout_mode.dart`）：`portrait` / `landscape`。
- `InputMode`（`lib/core/models/input_mode.dart`）：`touch` / `keyboard`。
- `ResponsiveBuilder`（`lib/core/layout/responsive_builder.dart`）：`portraitBuilder` / `landscapeBuilder`，内置 300ms `easeInOut` 过渡。
- `InputModeScope`（`lib/core/input/input_mode_scope.dart`）：widget 树内输入模式上下文。

### 2.3 自适应组件（`lib/shared/widgets/`）

- `AdaptiveButton`（text / onPressed / style / icon）。
- `AdaptiveIconButton`（位于 `adaptive_button.dart`）。
- `AdaptiveListTile`（title / subtitle / trailing / onTap）。

### 2.4 模块契约

- `ModuleContract`（`lib/core/modules/module_contract.dart`）：`definition`、`buildPage`、`buildSettingsPage`、`summary`、`initialize(storage)`、`dispose`、`exportData`、`importData`。
- 模块存储：`StorageService.saveData(key, map)` / `loadData(key)` / `deleteData(key)`，key 前缀 `module_todo_list_`。

---

## 3. 临时应用方案

### 3.1 结构（均在 `modules/todo_list/` 内，合并后部分删除）

```text
modules/todo_list/
├── docs/                       # 既有文档（保留）
├── lib/
│   ├── main.dart               # 【临时】独立运行入口（合并后删除）
│   ├── debug/                  # 【临时】调试支撑（合并后删除）
│   │   ├── memory_storage_service.dart   # StorageService 内存实现
│   │   ├── fake_device_info.dart         # 简化 DeviceInfoProvider
│   │   └── noop_notification_service.dart# NotificationService no-op 实现
│   └── features/todo_list/     # 模块正式业务代码（保留，合并进主线）
│       ├── todo_list_module.dart
│       ├── models/  data/  providers/  services/  pages/  widgets/
├── test/                       # 单元测试（保留）
├── windows/                    # 【临时】Windows 独立运行壳（合并后删除）
├── pubspec.yaml                # path 依赖 ametoolbox 底座（保留）
└── .gitignore / .metadata / analysis_options.yaml
```

### 3.2 临时入口 `lib/main.dart` 要点

- 创建 `MemoryStorageService()`，override `storageServiceProvider`：读写仅存内存，不碰 Hive，启动轻量、编译快速。
  - **OWNER 确认**：临时应用存储采用内存实现，且整个临时底座自包含于本模块，不修改主线任何代码。
- 创建 `FakeDeviceInfoProvider()`，override `deviceInfoProvider`：返回固定 DPI/内存值，规避项目已知的 `device_info_plus` 在部分 Windows 版本取内存抛异常问题。
- 创建真实 `ThemeController`、`LayoutController`、`InputController` 并 override：保证主题与横竖屏断点逻辑与主线一致。
- override `notificationServiceProvider` 为 no-op 实现。
- 根组件：`MaterialApp` + MD3 主题（复用底座 `Md3ColorScheme.fromAccent`）。
- **调试外壳（OWNER 确认）**：采用**双页调试外壳**，提供两个选项卡（主页面 / 设置页），便于同时调试两处。
- **横竖屏调试（OWNER 确认）**：页面内使用底座 `ResponsiveBuilder` 包裹，通过调整 Windows 窗口宽高触发断点切换；不额外提供手动切换按钮。

### 3.3 独立运行命令

```bash
cd modules/todo_list
flutter pub get
flutter run -d windows --debug   # 需 Windows 开发者模式（见 risks）
flutter analyze
flutter test
```

---

## 4. 调试范围与验收标准

### 4.1 主页面（类日历 + 当日待办）

- 类日历月视图：翻月、点击日期、有待办日期标记。
- 当日待办列表：按优先级排序、卡片仅显示名称、点击进详情。
- 空状态、完成切换、删除确认。
- 横屏：日历 + 列表并排或增列；竖屏：纵向堆叠。

### 4.2 详情页 / 新增编辑表单

- 名称、详情文本、图片附件（添加/删除/预览）、5 级优先级、期限、循环规则（五级菜单）、起止时间、提醒。
- 空名称校验、保存/取消。

### 4.3 设置页

- 分类管理、提醒设置、导出（.md / 剪贴板）。

### 4.4 验收标准

- `flutter analyze` 零报错；`flutter test` 覆盖率 ≥80%。
- 竖屏（窗口窄）与横屏（窗口宽）两种布局均正常切换、无溢出。
- 触控与键鼠两种 `InputMode` 下交互可用。
- 模块内 `lib/features/` 与 `lib/shared/` 无 `Platform.is*` / `dart:io`。

---

## 5. 合并进主线流程（需 OWNER 确认）

1. 保留 `modules/todo_list/lib/features/todo_list/` 正式业务代码与 `test/`、`docs/`。
2. 主项目 `pubspec.yaml` 增加 path 依赖：

```yaml
dependencies:
  todo_list_module:
    path: modules/todo_list
```

3. 主项目 `lib/core/modules/module_registry.dart` 的 `registerAll()` 中追加 `_PlaceholderModule` 无法覆盖，需新增 `'todo_list' => TodoListModule()` 分支并 import `package:todo_list_module/...`。
4. 由于 `registerAll()` 基于 `AppConstants.defaultModules` 生成 definition，需确认 `todo` 图标已映射（已确认 `module_icon_mapper.dart` 含 `todo`），并确认 `defaultModules` 中是否已含 `todo_list` 条目；若缺失，属于底座配置变更，须 OWNER 确认后补充。
5. 主项目 `main.dart` 的模块 `initialize(storage)` 循环已覆盖 `registry` 内所有模块，新增模块无需改动初始化逻辑。

---

## 6. 清理临时应用

合并成功后删除以下（仅限模块内，不触碰底座）：

- `modules/todo_list/lib/main.dart`
- `modules/todo_list/lib/debug/` 整个目录
- `modules/todo_list/windows/`（及 `.metadata` 中独立运行相关配置）
- `modules/todo_list/pubspec.yaml` 中因独立运行引入的额外依赖（如 `cupertino_icons` 等，若存在）

删除后，模块仅保留 `lib/features/todo_list/`（正式代码）、`test/`、`docs/`、`pubspec.yaml`（path 依赖底座）。

---

## 7. 里程碑

| 里程碑 | 内容 | 是否触碰底座 |
|--------|------|--------------|
| M1 临时应用骨架 | main.dart + debug 支撑 + 独立运行壳，可 `flutter run` 空壳 | 否 |
| M2 主页面开发 | 类日历 + 列表 + 详情 + 表单，横竖屏调试 | 否 |
| M3 设置页开发 | 分类/提醒/导出，横竖屏调试 | 否 |
| M4 合并进主线 | ModuleRegistry 注册 + pubspec path 依赖 + 验证 | **是（确认后）** |
| M5 清理临时应用 | 删除临时入口与运行壳，主线回归验证 | 否 |
| M6 首页卡片与后续 | `buildDashboardWidgets` / `buildEntryCard`，与主线共同 debug | 视实现 |

---

## 8. 风险与注意事项

| 风险 | 影响 | 应对 |
|------|------|------|
| `flutter build windows --debug` 需 Windows 开发者模式，沙箱不可自动化 | 高 | 手动在设备上开启开发者模式后运行；文档提示 |
| `device_info_plus` 取内存部分 Windows 版本抛异常 | 中 | 临时应用用 `FakeDeviceInfoProvider` 规避 |
| 临时应用需 `layoutControllerProvider` 依赖 storage/device，链较长 | 中 | 复用真实控制器 + 提供 fake device，避免重写断点逻辑 |
| 合并时 `defaultModules` 是否含 `todo_list` 不确定 | 中 | 合并前 OWNER 确认底座配置 |
| 删除临时壳后如需再独立调试 | 低 | 保留 docs 记录重建步骤 |

---

## 9. 引用文档

- [todo_list_spec.md](./todo_list_spec.md)
- [todo_list_design.md](./todo_list_design.md)
- [todo_list_coding_standards.md](./todo_list_coding_standards.md)
- 底座：`lib/main.dart`、`lib/app.dart`、`lib/core/providers/*`、`lib/core/modules/*`、`lib/shared/widgets/adaptive_*`