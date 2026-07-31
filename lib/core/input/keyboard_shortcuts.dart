import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/providers/input_provider.dart';
import 'package:ametoolbox/core/providers/sync_provider.dart';
import 'package:ametoolbox/features/settings/settings_page.dart';

class _GoBackIntent extends Intent {
  const _GoBackIntent();
}

class _SyncNowIntent extends Intent {
  const _SyncNowIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _NavigateBackIntent extends Intent {
  const _NavigateBackIntent();
}

/// 全局键盘快捷键（仅在键鼠模式下激活）。
///
/// 使用 Flutter [Shortcuts] + [Actions] + [Focus] 框架，在 [InputMode.mouse] 时注册，
/// 触控模式下直接透传 [child]，避免虚拟键盘触发意外行为。
class KeyboardShortcuts extends ConsumerWidget {
  const KeyboardShortcuts({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputMode = ref.watch(inputControllerProvider).currentMode;

    if (inputMode == InputMode.touch) {
      return child;
    }

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _GoBackIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyS,
        ): const _SyncNowIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.comma,
        ): const _OpenSettingsIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.arrowLeft,
        ): const _NavigateBackIntent(),
      },
      child: Actions(
        actions: {
          _GoBackIntent: CallbackAction<_GoBackIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
          _SyncNowIntent: CallbackAction<_SyncNowIntent>(
            onInvoke: (_) => ref.read(syncServiceProvider).startSync(),
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsPage(),
              ),
            ),
          ),
          _NavigateBackIntent: CallbackAction<_NavigateBackIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
