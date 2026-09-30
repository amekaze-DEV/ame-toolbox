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
/// - 正文框与标题同款 `OutlineInputBorder` 外观，但默认高度更大（`minHeight`）；
/// - 图片作为独立块内联在文本之间，可删除；
/// - 顶部工具栏作用于**当前选区**：有选区时修改选中文本，折叠光标时仅设定
///   后续输入样式（不修改已输入文本）；另提供插入图片。
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

  /// 正文框默认最小高度。
  static const double minBodyHeight = 200;

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

  /// 正文框是否有内容（决定浮动标签位置）。
  bool get _hasContent =>
      _entries.any((entry) => entry.block.inlines.isNotEmpty);

  /// 定位指定控制器对应的焦点节点。
  FocusNode? _nodeForController(RichTextEditingController controller) {
    for (final entry in _entries) {
      if (entry.controller == controller) return entry.focusNode;
    }
    return null;
  }

  /// 在下一帧把焦点还给指定控制器对应的正文框。
  ///
  /// 点击工具栏按钮（或关闭对话框）会抢占焦点，导致正文失去输入焦点；
  /// 这里将焦点重新交还给当前编辑的文本块，保证调整格式后能继续输入。
  void _requestFocus(RichTextEditingController controller) {
    final node = _nodeForController(controller);
    if (node == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) node.requestFocus();
    });
  }

  /// 包装一个作用于当前聚焦文本块的操作；无可用控制器时返回 null（按钮禁用）。
  ///
  /// 执行操作后把焦点交还正文框，避免点击工具栏导致失去输入焦点。
  VoidCallback? _focusedAction(
    void Function(RichTextEditingController controller) action,
  ) {
    final controller = _focusedController;
    if (controller == null) return null;
    return () {
      action(controller);
      _requestFocus(controller);
    };
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
    if (node == null || !mounted) return;
    if (!node.hasFocus) {
      if (_entries.contains(entry)) setState(() {});
      return;
    }
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
    // 对话框会抢走焦点，先记录原选区，关闭后恢复再应用。
    final selection = controller.selection;
    final theme = Theme.of(context);
    final result = await showNoteFontSizeDialog(
      context,
      baseFontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
      current: controller.currentStyle.fontSize,
    );
    if (result == null || !mounted) return;
    controller.selection = selection;
    if (result.fontSize == null) {
      controller.applyStyle(clearFontSize: true);
    } else {
      controller.applyStyle(fontSize: result.fontSize);
    }
    _requestFocus(controller);
  }

  /// 字体颜色取色盘。
  Future<void> _showColorDialog() async {
    final controller = _focusedController;
    if (controller == null) return;
    final selection = controller.selection;
    final result = await showNoteColorPaletteDialog(
      context,
      current: controller.currentStyle.colorValue,
    );
    if (result == null || !mounted) return;
    controller.selection = selection;
    if (result.colorValue == null) {
      controller.applyStyle(clearColorValue: true);
    } else {
      controller.applyStyle(colorValue: result.colorValue);
    }
    _requestFocus(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(context),
        const SizedBox(height: 8),
        _buildBodyBox(context),
      ],
    );
  }

  /// 正文框：与标题同款 `OutlineInputBorder`，但默认高度更大。
  Widget _buildBodyBox(BuildContext context) {
    final focusedNode = _focusedIndex >= 0 && _focusedIndex < _entries.length
        ? _entries[_focusedIndex].focusNode
        : null;
    return InputDecorator(
      isFocused: focusedNode?.hasFocus ?? false,
      isEmpty: !_hasContent,
      decoration: const InputDecoration(
        labelText: '正文',
        hintText: '输入正文，可插入图片',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
        contentPadding: EdgeInsets.all(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: NoteRichTextEditor.minBodyHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _entries.length; i++) _buildEntry(context, i),
          ],
        ),
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
      // EditableText 在未指定 strutStyle 时，会用基础样式生成
      // `forceStrutHeight: true` 的固定行高，导致大字号文本与相邻行重叠；
      // 关闭 strut 后行高随每行实际字号变化（与只读视图一致）。
      strutStyle: StrutStyle.disabled,
      decoration: const InputDecoration(
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