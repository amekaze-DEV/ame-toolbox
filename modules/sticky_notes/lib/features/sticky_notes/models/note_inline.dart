/// 富文本行内元素。
///
/// 一段文本 + 其行内样式（加粗 / 斜体 / 下划线 / 删除线 / 字号 / 颜色 / 链接）。
/// 一个文本块由若干 [NoteInline] 按顺序拼接而成，即「runs」模型。
class NoteInline {
  const NoteInline({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontSize,
    this.colorValue,
    this.link,
  });

  /// 文本内容。
  final String text;

  /// 是否粗体。
  final bool bold;

  /// 是否斜体。
  final bool italic;

  /// 是否下划线。
  final bool underline;

  /// 是否删除线。
  final bool strikethrough;

  /// 绝对字号（pt），null 表示继承块基础字号。
  final double? fontSize;

  /// 自定义字体颜色（ARGB 整数），null 表示继承主题色。
  final int? colorValue;

  /// 链接地址，null 表示非链接。
  final String? link;

  /// 是否存在任一非默认行内样式（用于 runs 合并与工具栏选中态判断）。
  bool get hasInlineStyle =>
      bold ||
      italic ||
      underline ||
      strikethrough ||
      fontSize != null ||
      colorValue != null;

  Map<String, dynamic> toJson() => {
        'text': text,
        'bold': bold,
        'italic': italic,
        if (underline) 'underline': true,
        'strikethrough': strikethrough,
        if (fontSize != null) 'fontSize': fontSize,
        if (colorValue != null) 'colorValue': colorValue,
        if (link != null) 'link': link,
      };

  factory NoteInline.fromJson(Map<String, dynamic> json) => NoteInline(
        text: json['text'] as String,
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        underline: json['underline'] as bool? ?? false,
        strikethrough: json['strikethrough'] as bool? ?? false,
        fontSize: _readFontSize(json['fontSize']),
        colorValue: _readColorValue(json['colorValue']),
        link: json['link'] as String?,
      );

  /// 读取字号：仅接受有限正数，异常值回退继承。
  static double? _readFontSize(Object? raw) {
    if (raw is num) {
      final value = raw.toDouble();
      if (value.isFinite && value > 0) return value;
    }
    return null;
  }

  /// 读取颜色：仅接受 ARGB 整数，异常值回退继承。
  static int? _readColorValue(Object? raw) => raw is int ? raw : null;

  /// 创建副本。
  ///
  /// [fontSize] / [colorValue] 为可空字段，需要真正置空时
  /// 分别使用 [clearFontSize] / [clearColorValue] 标志（clear 优先）。
  NoteInline copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSize,
    bool clearFontSize = false,
    int? colorValue,
    bool clearColorValue = false,
    String? link,
  }) =>
      NoteInline(
        text: text ?? this.text,
        bold: bold ?? this.bold,
        italic: italic ?? this.italic,
        underline: underline ?? this.underline,
        strikethrough: strikethrough ?? this.strikethrough,
        fontSize: clearFontSize ? null : (fontSize ?? this.fontSize),
        colorValue: clearColorValue ? null : (colorValue ?? this.colorValue),
        link: link ?? this.link,
      );

  @override
  bool operator ==(Object other) =>
      other is NoteInline &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic &&
      other.underline == underline &&
      other.strikethrough == strikethrough &&
      other.fontSize == fontSize &&
      other.colorValue == colorValue &&
      other.link == link;

  @override
  int get hashCode => Object.hash(
        text,
        bold,
        italic,
        underline,
        strikethrough,
        fontSize,
        colorValue,
        link,
      );
}