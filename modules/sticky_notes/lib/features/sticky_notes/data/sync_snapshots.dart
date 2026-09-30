import '../models/sticky_note.dart';
import '../models/sticky_notes_config.dart';

/// 同步导出用的**模块级内存镜像**（写穿）。
///
/// `ModuleContract.exportData` / `importData` 为同步签名，而配置与便签的
/// 读写发生在页面级 Provider 中（与模块实例不是同一对象），因此以模块级
/// 镜像承载「当前最新状态」，使同步导出无需异步 IO：
///
/// - [latestConfigSnapshot]：由 `StickyNotesConfigController` 在加载 / 变更后写入；
/// - [latestNotesSnapshot]：由 `StickyNotesController` 在加载 / 变更后写入，
///   模块 `initialize` 亦会写入启动时的落库结果；
/// - 附件字节见 `attachmentBytesCache`（`NoteAttachmentStore` 写穿维护）。
StickyNotesConfig? latestConfigSnapshot;

/// 当前便签列表镜像（同步导出 / 导入合并的本地基准）。
List<StickyNote> latestNotesSnapshot = const [];