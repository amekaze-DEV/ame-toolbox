import 'package:flutter/services.dart';

import '../services/radix_converter_service.dart';

/// 进制转换器输入格式化器。
///
/// 根据当前进制类型限制输入框只能输入合法字符：
/// - 二进制：仅 0、1
/// - 八进制：0-7
/// - 十进制：0-9、小数点与开头负号
/// - 十六进制：0-9、A-F（自动转为大写）
class RadixInputFormatter extends TextInputFormatter {
  final RadixType type;

  const RadixInputFormatter(this.type);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // 十六进制输入自动转为大写。
    if (type == RadixType.hex) {
      final upper = text.toUpperCase();
      if (_isValid(upper)) {
        return _replaceText(newValue, upper);
      }
      return oldValue;
    }

    if (_isValid(text)) return newValue;
    return oldValue;
  }

  bool _isValid(String text) {
    if (type == RadixType.decimal) {
      return _isValidDecimal(text);
    }
    return text.split('').every((c) => type.validChars.contains(c));
  }

  bool _isValidDecimal(String text) {
    if (text.isEmpty) return true;

    // 负号只能出现在开头且最多一个。
    final minusCount = '-'.allMatches(text).length;
    if (minusCount > 1) return false;
    if (minusCount == 1 && !text.startsWith('-')) return false;

    final body = text.startsWith('-') ? text.substring(1) : text;
    if (body.isEmpty) return true;

    // 小数点最多一个。
    final dotCount = '.'.allMatches(body).length;
    if (dotCount > 1) return false;

    return body.split('').every(
          (c) => type.validChars.contains(c) || c == '-',
        );
  }

  TextEditingValue _replaceText(TextEditingValue value, String newText) {
    if (value.text == newText) return value;

    final oldText = value.text;
    final selection = value.selection;

    // 仅当光标在末尾时保持位置，否则将光标移至末尾，避免大小写转换后位置错乱。
    final newSelection = selection.isValid && selection.baseOffset == oldText.length
        ? TextSelection.collapsed(offset: newText.length)
        : TextSelection.collapsed(offset: newText.length);

    return TextEditingValue(
      text: newText,
      selection: newSelection,
    );
  }
}
