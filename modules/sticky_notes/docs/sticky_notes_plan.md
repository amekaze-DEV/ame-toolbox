# 便签模块 — 子项目规划（临时应用调试方案）

> **文档类型**: 子项目开发与调试规划
> **模块 ID**: `sticky_notes`
> **版本**: v1.0
> **状态**: 草案
> **约束基线**: `design.md` + `project_constraints.md` + `sticky_notes_spec.md`

### 1.0 开发隔离硬约束

- **临时底座开发期间，任何代码修改都不得涉及项目主线代码**（主线 `lib/`、主项目 `pubspec.yaml`、底座 `modules/` 下其他子模块）。
- 临时应用全部文件**仅存在于** `modules/sticky_notes/` 内，完全自包含。
- 唯一可能触碰主线的时点是**合并进主线（M4）**，且必须事先经 OWNER 确认。

---

## 1. 目标与范围

### 1.1 目标

在**不动底座 APP 主线代码**的前提下，为便签模块建立**独立临时调试应用**，完成模块界面与设置页的横竖屏布局调试；调试通过后，将模块正式代码**移植合并进项目主线**（通过 `ModuleRegistry` + pubspec path 依赖注册），随后**删除临时应用**，与主线一同进行后续 debug 与首页卡片开发。

### 1.2 范围

| 阶段 | 内容 | 是否触碰底座 |
|------|------|--------------|
| 临时应用搭建 | 模块目录内新增独立运行壳 + 临时入口 | 否 |
| 界面调试 | 便签主页面（分类筛选 + 列表/网格）、详情/编辑页（富文本 + 图片）、横竖屏布局 | 否 |
| 设置页调试 | 分类管理、默认排序设置页 | 否 |
| 合并进主线 | 注册 `ModuleRegistry`、主项目 `pubspec.yaml` 加 path 依赖、`main.dart` 注册 | **是（需 OWNER 确认）** |
| 删除临时应用 | 移除独立运行壳与临时入口 | 否 |
| 后续 | 首页卡片（`summary` / `buildDashboardWidgets` / `buildEntryCard`）、数据同步联调、整体 debug | 与主线共同进行 |

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
| `notificationServiceProvider` | `Provider<NotificationService>` | 有默认 | **no-op 实现**（如依赖项缺失则简易 stub） |
| `moduleControllerProvider` | `Provider<ModuleController>` | 需 override | 临时应用可不提供（直接挂载模块页面） |
| `syncServiceProvider` | `Provider<SyncService>` | 需 override | 临时应用可不提供（不调试同步） |

> 便签模块不涉及通知调度，`notificationServiceProvider` 若模块初始化不依赖，可省略其 override；以实际 import 依赖为准。

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
- 模块存储：`StorageService.saveData(key, map)` / `loadData(key)` / `deleteData(key)`，key 前缀 `module_sticky_notes_`。

---

## 3. 临时应用方案

### 3.1 结构（均在 `modules/sticky_notes/` 内，合并后部分删除）

```text
modules/sticky_notes/
├── docs/                       # 既有文档（保留）
├── lib/
│   ├── main.dart               # 【临时】独立运行入口（合并后删除）
│   ├── debug/                  # 【临时】调试支撑（合并后删除）
│   │   ├── memory_storage_service.dart   # StorageService 内存实现
│   │   ├── fake_device_info.dart         # 简化 DeviceInfoProvider
│   │   └── noop_notification_service.dart# NotificationService no-op（如需）
│   └── features/sticky_notes/  # 模块正式业务代码（保留，合并进主线）
│       ├── sticky_notes_module.dart
│       ├── models/  data/  providers/  services/  pages/  widgets/
├── test/                       # 单元测试（保留）
├── windows/                    # 【临时】Windows 独立运行壳（合并后删除）
├── pubspec.yaml                # path 依赖 ametoolbox 底座（保留）
└── .gitignore / .metadata / analysis_options.yaml
```

### 3.2 临时入口 `lib/main.dart` 要点

- 创建 `MemoryStorageService()`，override `storageServiceProvider`：读写仅存内存，不碰 Hive，启动轻量、编译快速。
- 创建 `FakeDeviceInfoProvider()`，override `deviceInfoProvider`：返回固定 DPI/内存值，规避项目已知的 `device_info_plus` 在部分 Windows 版本取内存抛异常问题。
- 创建真实 `ThemeController`、`LayoutController`、`InputController` 并 override：保证主题与横竖屏断点逻辑与主线一致。
- 根组件：`MaterialApp` + MD3 主题（复用底座 `Md3ColorScheme.fromAccent`）。
- **调试外壳**：采用**双页调试外壳**，提供两个选项卡（主页面 / 设置页），便于同时调试两处。
- **横竖屏调试**：页面内使用底座 `ResponsiveBuilder` 包裹，通过调整 Windows 窗口宽高触发断点切换；不额外提供手动切换按钮。

### 3.3 独立运行命令

```bash
cd modules/sticky_notes
flutter pub get
flutter run -d windows --debug   # 需 Windows 开发者模式（见 risks）
flutter analyze
flutter test
```

---

## 4. 调试范围与验收标准

### 4.1 主页面（分类筛选 + 便签列表/网格）

- 分类筛选条（全部 / 各分类）切换。
- 便签列表：置顶置前 + 排序方式；竖屏单列、横屏两列网格。
- 空状态、删除确认、置顶/取消置顶。

### 4.2 详情/编辑页

- 标题（必填校验）、富文本编辑（工具栏：粗体/斜体/删除线/标题/列表/引用/待办清单）、图片附件（添加/删除/预览）、分类选择、置顶开关。
- 保存/取消。

### 4.3 设置页

- 分类管理（增删改/排序）、默认排序方式选择。

### 4.4 验收标准

- `flutter analyze` 零报错；`flutter test` 覆盖率 ≥80%。
- 竖屏（窗口窄）与横屏（窗口宽）两种布局均正常切换、无溢出。
- 触控与键鼠两种 `InputMode` 下交互可用。
- 模块内 `lib/features/` 与 `lib/shared/` 无 `Platform.is*` / `dart:io`。

---

## 5. 合并进主线流程（需 OWNER 确认）

1. 保留 `modules/sticky_notes/lib/features/sticky_notes/` 正式业务代码与 `test/`、`docs/`。
2. 主项目 `pubspec.yaml` 增加 path 依赖：

```yaml
dependencies:
  sticky_notes_module:
    path: modules/sticky_notes
```

3. 主项目 `lib/core/modules/module_registry.dart` 的 `registerAll()` 中新增 `'sticky_notes' => StickyNotesModule()` 分支并 import `package:sticky_notes_module/...`。
4. 确认 `module_icon_mapper.dart` 含 `notes` 图标（已确认存在，映射 `Icons.sticky_note_2_outlined`）；并确认 `defaultModules` 中是否已含 `sticky_notes` 条目；若缺失，属于底座配置变更，须 OWNER 确认后补充。
5. 主项目 `main.dart` 的模块 `initialize(storage)` 循环已覆盖 `registry` 内所有模块，新增模块无需改动初始化逻辑。

---

## 6. 清理临时应用

合并成功后删除以下（仅限模块内，不触碰底座）：

- `modules/sticky_notes/lib/main.dart`
- `modules/sticky_notes/lib/debug/` 整个目录
- `modules/sticky_notes/windows/`（及 `.metadata` 中独立运行相关配置）
- `modules/sticky_notes/pubspec.yaml` 中因独立运行引入的额外依赖（如 `cupertino_icons` 等，若存在）

删除后，模块仅保留 `lib/features/sticky_notes/`（正式代码）、`test/`、`docs/`、`pubspec.yaml`（path 依赖底座）。

---

## 7. 里程碑

| 里程碑 | 内容 | 是否触碰底座 |
|--------|------|--------------|
| M1 临时应用骨架 | main.dart + debug 支撑 + 独立运行壳，可 `flutter run` 空壳 | 否 |
| M2 主页面开发 | 分类筛选 + 列表/网格 + 详情/编辑（富文本/图片），横竖屏调试 | 否 |
| M3 设置页开发 | 分类/排序，横竖屏调试 | 否 |
| M4 合并进主线 | ModuleRegistry 注册 + pubspec path 依赖 + 验证 | **是（确认后）** |
| M5 清理临时应用 | 删除临时入口与运行壳，主线回归验证 | 否 |
| M6 首页卡片与后续 | `summary` / `buildDashboardWidgets` / `buildEntryCard`、数据同步联调，与主线共同 debug | 视实现 |

---

## 8. 风险与注意事项

| 风险 | 影响 | 应对 |
|------|------|------|
| `flutter build windows --debug` 需 Windows 开发者模式，沙箱不可自动化 | 高 | 手动在设备上开启开发者模式后运行；文档提示 |
| `device_info_plus` 取内存部分 Windows 版本抛异常 | 中 | 临时应用用 `FakeDeviceInfoProvider` 规避 |
| 自研富文本渲染能力有限（无表格等复杂排版） | 中 | 需求边界为轻量富文本；文档记录取舍 |
| 横屏两列网格 + 可变高度卡片实现复杂度 | 中 | 用 `ResponsiveBuilder` 分层；组件拆分；参照底座 Masonry 思路 |
| 合并时 `defaultModules` 是否含 `sticky_notes` 不确定 | 中 | 合并前 OWNER 确认底座配置（**已闭环**：底座仅有 `id: 'notes'` 槽位，与模块定义 id 不一致；经 OWNER 授权在 P8 中校正为 `'sticky_notes'`，图标仍复用 `notes` 映射） |
| 删除临时壳后如需再独立调试 | 低 | 保留 docs 记录重建步骤 |

---

## 9. 引用文档

- [sticky_notes_spec.md](./sticky_notes_spec.md)
- [sticky_notes_design.md](./sticky_notes_design.md)
- [sticky_notes_coding_standards.md](./sticky_notes_coding_standards.md)
- 底座：`lib/main.dart`、`lib/app.dart`、`lib/core/providers/*`、`lib/core/modules/*`、`lib/shared/widgets/adaptive_*`