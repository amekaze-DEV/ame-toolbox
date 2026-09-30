import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_summary.dart';
import 'package:ametoolbox/core/modules/module_contract.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

import 'data/note_attachment_store.dart';
import 'data/sticky_notes_config_repository.dart';
import 'data/sticky_notes_repository.dart';
import 'data/sync_snapshots.dart';
import 'models/sticky_note.dart';
import 'models/sticky_notes_config.dart';
import 'pages/sticky_notes_page.dart';
import 'pages/sticky_notes_settings_page.dart';
import 'providers/sticky_notes_config_controller.dart';

/// 便签模块入口。
///
/// 实现 [ModuleContract]，接入底座生命周期；
/// 合并主线时由主项目 [ModuleRegistry] 注册。
class StickyNotesModule implements ModuleContract {
  StickyNotesConfigController? _configController;
  StickyNotesRepository? _notesRepository;
  NoteAttachmentStore? _attachmentStore;

  /// 首页卡片摘要使用的便签数（启动时统计的快照）。
  int _total = 0;

  @override
  ModuleDefinition get definition => const ModuleDefinition(
        id: 'sticky_notes',
        name: '便签',
        description: '便签记录、分类与置顶管理',
        iconName: 'notes',
        defaultEnabled: true,
      );

  @override
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return const StickyNotesPage();
  }

  @override
  Widget? buildSettingsPage(BuildContext context, WidgetRef ref) {
    return const StickyNotesSettingsPage();
  }

  @override
  ModuleSummary get summary => ModuleSummary(
        label: '便签',
        value: '$_total',
      );

  @override
  Future<void> initialize(StorageService storage) async {
    // 加载配置（首次运行写入默认分类与默认排序）。
    final configRepository = StickyNotesConfigRepository(
      storageService: storage,
    );
    final configController = StickyNotesConfigController(configRepository);
    await configController.load();
    _configController = configController;

    final notesRepository = StickyNotesRepository(storageService: storage);
    _notesRepository = notesRepository;
    final attachmentStore = NoteAttachmentStore(storageService: storage);
    _attachmentStore = attachmentStore;

    // 统计便签总数（首页卡片摘要）并同步写入导出镜像。
    final notes = await notesRepository.loadAll();
    _total = notes.length;
    latestNotesSnapshot = notes;

    // 预载全部附件字节：`exportData` 为同步签名，需在导出前常驻内存。
    await attachmentStore.preload(_attachmentIdsOf(notes));
  }

  @override
  Future<void> dispose() async {
    _configController?.dispose();
    _configController = null;
    _notesRepository = null;
    _attachmentStore = null;
  }

  @override
  List<Widget> buildDashboardWidgets(BuildContext context, WidgetRef ref) =>
      const [];

  @override
  bool get hasCustomEntryCard => false;

  @override
  Widget? buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onOpenModule,
  ) =>
      null;

  @override
  Map<String, dynamic> exportData() {
    final config = latestConfigSnapshot ??
        _configController?.config ??
        const StickyNotesConfig();
    final notes = latestNotesSnapshot;
    return <String, dynamic>{
      'module_sticky_notes_config': config.toJson(),
      'module_sticky_notes_notes': [
        for (final note in notes) note.toJson(),
      ],
      'module_sticky_notes_attachments': _exportAttachmentBytes(notes),
    };
  }

  @override
  void importData(Map<String, dynamic> data) {
    final configJson =
        data['module_sticky_notes_config'] as Map<String, dynamic>?;
    if (configJson != null) {
      final config = StickyNotesConfig.fromJson(configJson);
      // 镜像先行写入，保证同一轮同步内的再次导出立即反映导入结果。
      latestConfigSnapshot = config;
      unawaited(_configController?.replaceConfig(config));
    }

    // 按 id 合并便签（远端不存在则保留本地，双方存在取 updatedAt 较新者）。
    final merged = <String, StickyNote>{
      for (final note in latestNotesSnapshot) note.id: note,
    };
    for (final json in data['module_sticky_notes_notes'] as List<dynamic>? ??
        const <dynamic>[]) {
      final remote = StickyNote.fromJson(json as Map<String, dynamic>);
      final local = merged[remote.id];
      if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
        merged[remote.id] = remote;
      }
    }
    latestNotesSnapshot = merged.values.toList();
    unawaited(_notesRepository?.saveAll(latestNotesSnapshot));

    // 附件字节：仅落库合并结果中被引用的附件，避免产生孤儿数据。
    final attachmentsJson =
        data['module_sticky_notes_attachments'] as Map<String, dynamic>?;
    if (attachmentsJson == null) return;
    for (final id in _attachmentIdsOf(latestNotesSnapshot)) {
      final b64 = attachmentsJson[id] as String?;
      if (b64 == null) continue;
      final bytes = base64Decode(b64);
      attachmentBytesCache[id] = bytes;
      unawaited(_attachmentStore?.saveBytes(id, bytes));
    }
  }

  /// 导出被 [notes] 引用的附件字节（base64），键为附件 id。
  Map<String, String> _exportAttachmentBytes(List<StickyNote> notes) {
    final result = <String, String>{};
    for (final note in notes) {
      for (final attachment in note.attachments) {
        final bytes = attachmentBytesCache[attachment.id];
        if (bytes != null) result[attachment.id] = base64Encode(bytes);
      }
    }
    return result;
  }

  /// 遍历 [notes] 引用的全部附件 id。
  Iterable<String> _attachmentIdsOf(List<StickyNote> notes) sync* {
    for (final note in notes) {
      for (final attachment in note.attachments) {
        yield attachment.id;
      }
    }
  }
}