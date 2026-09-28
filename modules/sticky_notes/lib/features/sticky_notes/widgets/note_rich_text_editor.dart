import 'package:flutter/material.dart';

import 'package:ametoolbox/shared/widgets/adaptive_button.dart';

import '../models/note_block.dart';
import '../models/note_image_attachment.dart';
import '../models/note_inline.dart';
import 'note_image_block.dart';
import 'note_text_style_panel.dart';
import 'rich_text_editing_controller.dart';

/// 正文块编辑载体。
///
/// 图片块无文本控制器与焦点节点（后两者为 null）。
class _BlockEntry {
  _BlockEntry({required this.block, this.controller, this.focusNode});

  NoteBlock block;
  RichTextEditingController? controller;
  FocusNode? focusNode;

  void dispose() {
    controller?.dispose();
    focusNode?.dispose();
  }
}

/// 便签富文本编辑器。
///
/// 一个便签对应一段连续图文内容（无块类型、无块级操作入口）：
/// - 文本为无边框多行输入，整体包在一个与页面背景区分的内容容器内；
/// - 图片作为独立块内联在文本之间，可删除；
/// - 顶部工具栏作用于**当前聚焦文本块的选区**：加粗 / 斜体 / 下划线 / 删除线 /
///   字号 / 字体颜色，以及插入图片。
class NoteRichTextEditor extends StatefulWidget {
  const NoteRichTextEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    this.onPickImages,
  });

  /// 初始正文块列表。
  final List<NoteBlock> blocks;

  /// 正文变更回调。
  final ValueChanged<List<NoteBlock>> onChanged;

  /// 插入图片回调（由页面注入文件选择能力）；为 null 时隐藏「插入图片」按钮。
  final Future<List<NoteImageAttachment>> Function()? onPickImages;

  @override
  State<NoteRichTextEditor> createState() => _NoteRichTextEditorState();
}

class _NoteRichTextEditorState extends State<NoteRichTextEditor> {
  late List<_BlockEntry> _entries;
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    final blocks = widget.blocks.isEmpty
        ? <NoteBlock>[const ParagraphBlock(inlines: [])]
        : widget.blocks;
    _entries = [for (final block in blocks) _createEntry(block)];
    final firstText = _entries.indexWhere((e) => e.controller != null);
    _focusedIndex = firstText < 0 ? 0 : firstText;
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  /// 创建块编辑载体；文本块绑定控制器与焦点节点。
  _BlockEntry _createEntry(NoteBlock block) {
    if (block is ImageBlock) return _BlockEntry(block: block);
    final entry = _BlockEntry(
      block: block,
      controller: RichTextEditingController(runs: block.inlines),
      focusNode: FocusNode(),
    );
    entry.controller!.addListener(() => _handleControllerChange(entry));
    entry.focusNode!.addListener(() => _handleFocusChange(entry));
    return entry;
  }

  /// 当前聚焦文本块对应的控制器；聚焦到图片块时为 null。
  RichTextEditingController? get _focusedController {
    if (_focusedIndex < 0 || _focusedIndex >= _entries.length) return null;
    return _entries[_focusedIndex].controller;
  }

  /// 包装一个作用于当前聚焦文本块的操作；无可用控制器时返回 null（按钮禁用）。
  VoidCallback? _focusedAction(
    void Function(RichTextEditingController controller) action,
  ) {
    final controller = _focusedController;
    if (controller == null) return null;
    return () => action(controller);
  }

  List<NoteBlock> _currentBlocks() =>
      [for (final entry in _entries) entry.block];

  void _handleControllerChange(_BlockEntry entry) {
    final controller = entry.controller;
    if (controller == null) return;
    entry.block = ParagraphBlock(inlines: controller.runs);
    if (mounted) setState(() {});
    widget.onChanged(_currentBlocks());
  }

  void _handleFocusChange(_BlockEntry entry) {
    final node = entry.focusNode;
    if (node == null || !node.hasFocus || !mounted) return;
    final index = _entries.indexOf(entry);
    if (index >= 0 && index != _focusedIndex) {
      setState(() => _focusedIndex = index);
    }
  }

  /// 在当前聚焦块之后插入图片块，并补一个空文本块便于继续输入。
  Future<void> _insertImage() async {
    final picker = widget.onPickImages;
    if (picker == null) return;
    final picked = await picker();
    if (picked.isEmpty || !mounted) return;

    final index = _focusedIndex.clamp(0, _entries.length - 1);
    final images = [
      for (final attachment in picked)
        _createEntry(ImageBlock(attachment: attachment)),
    ];
    final paragraph = _createEntry(const ParagraphBlock(inlines: []));
    setState(() {
      _entries = [
        ..._entries.sublist(0, index + 1),
        ...images,
        paragraph,
        ..._entries.sublist(index + 1),
      ];
      _focusedIndex = index + images.length + 1;
    });
    widget.onChanged(_currentBlocks());
    _focusLater(paragraph);
  }

  void _focusLater(_BlockEntry entry) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) entry.focusNode?.requestFocus();
    });
  }

  /// 删除指定图片块；正文至少保留一个文本块。
  void _removeImageEntry(int index) {
    if (index < 0 || index >= _entries.length) return;
    final removed = _entries[index];
    setState(() {
      _entries = [..._entries]..removeAt(index);
      if (_entries.isEmpty) {
        _entries = [_createEntry(const ParagraphBlock(inlines: []))];
      }
      if (_focusedIndex >= _entries.length) {
        _focusedIndex = _entries.length - 1;
      }
    });
    widget.onChanged(_currentBlocks());
    // 待旧输入框卸载后再释放，避免「已释放控制器仍被使用」。
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  /// 字号选择器（滑块 + 数值输入框）。
  Future<void> _showFontSizeDialog() async {
    final controller = _focusedController;
    if (controller == null) return;
    final theme = Theme.of(context);
    final result = await showNoteFontSizeDialog(
      context,
      baseFontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
      current: controller.currentStyle.fontSize,
    );
    if (result == null || !mounted) return;
    if (result.fontSize == null) {
      controller.applyStyle(clearFontSize: true);
    } else {
      controller.applyStyle(fontSize: result.fontSize);
    }
  }

  /// 字体颜色取色盘。
  Future<void> _showColorDialog() async {
    final controller = _focusedController;
    if (controller == null) return;
    final result = await showNoteColorPaletteDialog(
      context,
      current: controller.currentStyle.colorValue,
    );
    if (result == null || !mounted) return;
    if (result.colorValue == null) {
      controller.applyStyle(clearColorValue: true);
    } else {
      controller.applyStyle(colorValue: result.colorValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(context),
        const SizedBox(height: 8),
        _buildContentContainer(context),
      ],
    );
  }

  /// 内容容器：以填充色 + 描边与页面背景区分。
  Widget _buildContentContainer(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _entries.length; i++) _buildEntry(context, i),
        ],
      ),
    );
  }

  Widget _buildEntry(BuildContext context, int index) {
    final entry = _entries[index];
    final block = entry.block;
    if (block is ImageBlock) {
      return NoteImageBlock(
        attachment: block.attachment,
        onDelete: () => _removeImageEntry(index),
      );
    }
    return TextField(
      controller: entry.controller,
      focusNode: entry.focusNode,
      maxLines: null,
      decoration: const InputDecoration(
        hintText: '输入正文',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final controller = _focusedController;
    final style = controller?.currentStyle ?? const NoteInline(text: '');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 4,
        children: [
          _toolbarToggle(
            icon: Icons.format_bold,
            tooltip: '加粗',
            selected: style.bold,
            onPressed: _focusedAction((c) => c.applyStyle(bold: !style.bold)),
          ),
          _toolbarToggle(
            icon: Icons.format_italic,
            tooltip: '斜体',
            selected: style.italic,
            onPressed:
                _focusedAction((c) => c.applyStyle(italic: !style.italic)),
          ),
          _toolbarToggle(
            icon: Icons.format_underlined,
            tooltip: '下划线',
            selected: style.underline,
            onPressed:
                _focusedAction((c) => c.applyStyle(underline: !style.underline)),
          ),
          _toolbarToggle(
            icon: Icons.format_strikethrough,
            tooltip: '删除线',
            selected: style.strikethrough,
            onPressed: _focusedAction(
              (c) => c.applyStyle(strikethrough: !style.strikethrough),
            ),
          ),
          _toolbarToggle(
            icon: Icons.format_size,
            tooltip: '字号',
            selected: style.fontSize != null,
            onPressed: controller == null ? null : _showFontSizeDialog,
          ),
          _toolbarToggle(
            icon: Icons.format_color_text,
            tooltip: '字体颜色',
            selected: style.colorValue != null,
            onPressed: controller == null ? null : _showColorDialog,
          ),
          if (widget.onPickImages != null)
            _toolbarToggle(
              icon: Icons.image_outlined,
              tooltip: '插入图片',
              selected: false,
              onPressed: _insertImage,
            ),
        ],
      ),
    );
  }

  Widget _toolbarToggle({
    required IconData icon,
    required String tooltip,
    required bool selected,
    required VoidCallback? onPressed,
  }) =>
      AdaptiveIconButton(
        icon: Icon(icon),
        selectedIcon: Icon(icon),
        isSelected: selected,
        tooltip: tooltip,
        onPressed: onPressed,
      );
}