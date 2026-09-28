import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/shared/widgets/adaptive_list_tile.dart';

import '../models/note_sort_mode.dart';
import '../providers/sticky_notes_config_provider.dart';
import '../widgets/note_category_manager.dart';

/// 便签设置页（P7）：默认排序方式 + 分类管理（spec §3.4）。
class StickyNotesSettingsPage extends ConsumerWidget {
  const StickyNotesSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final currentMode = ref.watch(stickyNotesConfigProvider).config.defaultSortMode;

    return Scaffold(
      appBar: AppBar(title: const Text('便签设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('默认排序', style: textTheme.titleSmall),
          for (final mode in NoteSortMode.values)
            AdaptiveListTile(
              leading: Icon(
                currentMode == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: currentMode == mode ? colorScheme.primary : null,
              ),
              title: Text(mode.displayName),
              onTap: () =>
                  ref.read(stickyNotesConfigProvider).setDefaultSortMode(mode),
            ),
          const Divider(height: 32),
          Text('分类管理', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          const NoteCategoryManager(),
        ],
      ),
    );
  }
}