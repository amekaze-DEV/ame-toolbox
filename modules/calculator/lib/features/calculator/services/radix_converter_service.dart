import 'dart:math' as math;

/// 进制类型。
enum RadixType {
  binary('二进制', 2, '0b', 'binary'),
  octal('八进制', 8, '0o', 'octal'),
  decimal('十进制', 10, '', 'decimal'),
  hex('十六进制', 16, '0x', 'hex');

  final String displayName;
  final int base;
  final String prefix;

  /// 用于序列化与持久化的字符串标识。
  final String value;

  const RadixType(this.displayName, this.base, this.prefix, this.value);

  /// 从序列化字符串还原枚举值；无法识别时返回 [RadixType.decimal]。
  static RadixType fromString(String? value) {
    return RadixType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => RadixType.decimal,
    );
  }

  /// 该进制下允许输入的字符（不含前缀与符号）。
  String get validChars {
    return switch (this) {
      RadixType.binary => '01',
      RadixType.octal => '01234567',
      RadixType.decimal => '0123456789.',
      RadixType.hex => '0123456789abcdefABCDEF',
    };
  }
}

/// 进制转换服务。
///
/// 负责二 / 八 / 十 / 十六进制之间的整数与小数互转。
class RadixConverterService {
  static const String _errorInvalidChar = '输入包含非法字符';
  static const String _errorInvalidDecimal = '十进制输入格式错误';
  static const String _errorDecimalInNonDecimal = '非十进制暂不支持小数互转';
  static const String _errorNegativeNonDecimal = '非十进制仅支持正数';
  static const String _truncateHint = '二进制小数已截断';

  /// 二进制小数最大保留位数。
  static const int maxBinaryFractionBits = 8;

  /// 判断 [input] 对于指定进制是否仅包含合法字符（含可选前缀）。
  bool isValid(String input, RadixType type) {
    if (input.trim().isEmpty) return true;
    final normalized = _stripPrefix(input.trim());
    if (normalized.isEmpty) return true;

    if (type == RadixType.decimal) {
      // 十进制允许一个负号与小数点。
      final body = normalized.startsWith('-') ? normalized.substring(1) : normalized;
      if (body.isEmpty) return true;
      final dotCount = '.'.allMatches(body).length;
      if (dotCount > 1) return false;
      return body.replaceAll('.', '').split('').every((c) => type.validChars.contains(c));
    }

    return normalized.split('').every((c) => type.validChars.contains(c));
  }

  /// 去除前缀并统一大小写（十六进制保留大小写用于显示，内部比较时转换）。
  String _stripPrefix(String input) {
    final lower = input.toLowerCase();
    if (lower.startsWith('0b') || lower.startsWith('0o') || lower.startsWith('0x')) {
      return input.substring(2);
    }
    return input;
  }

  /// 将 [input] 从 [from] 进制转换为 [to] 进制字符串表示。
  ///
  /// - 空输入返回空字符串。
  /// - 十进制小数转到非十进制时最多保留 8 位二进制小数，其余按规则截断。
  /// - 非十进制小数仅支持转到十进制，转到其他非十进制返回错误提示。
  /// - [onHint] 用于返回截断等提示信息。
  String convert(
    String input,
    RadixType from,
    RadixType to, {
    void Function(String hint)? onHint,
  }) {
    if (input.trim().isEmpty) return '';

    final normalized = _stripPrefix(input.trim());
    if (normalized.isEmpty) return '';

    if (from == RadixType.decimal) {
      return _convertFromDecimal(normalized, to, onHint: onHint);
    }

    // 非十进制输入。
    if (normalized.startsWith('-')) {
      if (onHint != null) onHint(_errorNegativeNonDecimal);
      return '';
    }

    if (normalized.contains('.')) {
      if (to == RadixType.decimal) {
        return _convertFractionToDecimal(normalized, from);
      }
      if (onHint != null) onHint(_errorDecimalInNonDecimal);
      return '';
    }

    final value = BigInt.tryParse(normalized, radix: from.base);
    if (value == null) {
      if (onHint != null) onHint(_errorInvalidChar);
      return '';
    }
    return _formatInteger(value, to);
  }

  /// 从十进制字符串转换到目标进制。
  String _convertFromDecimal(
    String input,
    RadixType to, {
    void Function(String hint)? onHint,
  }) {
    final isNegative = input.startsWith('-');
    final body = isNegative ? input.substring(1) : input;

    if (body.contains('.')) {
      final integerPart = body.substring(0, body.indexOf('.'));
      final fractionPart = body.substring(body.indexOf('.') + 1);
      final integerValue = BigInt.tryParse(integerPart.isEmpty ? '0' : integerPart);
      if (integerValue == null) {
        if (onHint != null) onHint(_errorInvalidDecimal);
        return '';
      }

      final fractionDouble = double.tryParse('0.$fractionPart');
      if (fractionDouble == null) {
        if (onHint != null) onHint(_errorInvalidDecimal);
        return '';
      }

      if (to == RadixType.decimal) return input;

      final integerStr = _formatInteger(integerValue, to);
      final fractionStr = _convertDecimalFraction(
        fractionDouble,
        to,
        onHint: to == RadixType.binary ? onHint : null,
      );
      if (fractionStr.isEmpty) return '$integerStr.0';

      final sign = isNegative ? '-' : '';
      return '$sign$integerStr.$fractionStr';
    }

    final value = BigInt.tryParse(body);
    if (value == null) {
      if (onHint != null) onHint(_errorInvalidDecimal);
      return '';
    }
    final result = _formatInteger(value, to);
    return isNegative ? '-$result' : result;
  }

  /// 将十进制小数部分转换为目标进制字符串。
  ///
  /// 当 [to] 为二进制且小数无法在 [maxBinaryFractionBits] 位内精确表示时，
  /// 通过 [onHint] 返回截断提示。
  String _convertDecimalFraction(
    double fraction,
    RadixType to, {
    void Function(String hint)? onHint,
  }) {
    if (fraction <= 0) return '';

    final base = to.base;
    final buffer = StringBuffer();
    var remaining = fraction;
    var iterations = 0;
    final maxBits = to == RadixType.binary ? maxBinaryFractionBits : 12;

    while (remaining > 1e-12 && iterations < maxBits) {
      remaining *= base;
      final digit = remaining.floor();
      buffer.write(_digitToChar(digit));
      remaining -= digit;
      iterations++;
    }

    if (to == RadixType.binary &&
        iterations == maxBits &&
        remaining > 1e-12 &&
        onHint != null) {
      onHint(_truncateHint);
    }

    return buffer.toString();
  }

  /// 将非十进制小数转换为十进制小数字符串。
  String _convertFractionToDecimal(String input, RadixType from) {
    final parts = input.split('.');
    final integerPart = parts[0];
    final fractionPart = parts[1];

    final integerValue = BigInt.tryParse(integerPart.isEmpty ? '0' : integerPart, radix: from.base);
    if (integerValue == null) return '';

    var fractionValue = 0.0;
    final base = from.base;
    for (var i = 0; i < fractionPart.length; i++) {
      final digit = _charToDigit(fractionPart[i]);
      if (digit == null || digit >= base) return '';
      fractionValue += digit / math.pow(base, i + 1);
    }

    final total = integerValue.toDouble() + fractionValue;
    // 去除末尾 0。
    var result = total.toStringAsFixed(12).replaceAll(RegExp(r'0+$'), '');
    if (result.endsWith('.')) result = result.substring(0, result.length - 1);
    return result;
  }

  /// 将整数格式化为目标进制字符串（带前缀）。
  String _formatInteger(BigInt value, RadixType type) {
    if (type == RadixType.octal) {
      return '${type.prefix}${value.toRadixString(type.base)}';
    }
    if (type == RadixType.decimal) return value.toString();
    return '${type.prefix}${value.toRadixString(type.base).toUpperCase()}';
  }

  /// 将单个数字转换为字符。
  String _digitToChar(int digit) {
    if (digit < 10) return digit.toString();
    return String.fromCharCode('A'.codeUnitAt(0) + digit - 10);
  }

  /// 将字符转换为数字。
  int? _charToDigit(String char) {
    final lower = char.toLowerCase();
    if (lower.codeUnitAt(0) >= '0'.codeUnitAt(0) && lower.codeUnitAt(0) <= '9'.codeUnitAt(0)) {
      return lower.codeUnitAt(0) - '0'.codeUnitAt(0);
    }
    if (lower.codeUnitAt(0) >= 'a'.codeUnitAt(0) && lower.codeUnitAt(0) <= 'f'.codeUnitAt(0)) {
      return lower.codeUnitAt(0) - 'a'.codeUnitAt(0) + 10;
    }
    return null;
  }
}
