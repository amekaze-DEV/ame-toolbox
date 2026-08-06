import 'dart:math' as math;

import 'package:math_expressions/math_expressions.dart';

/// 科学计算器求值结果。
class CalculationResult {
  final double? value;
  final String display;
  final bool isError;
  final String? errorMessage;

  const CalculationResult({
    this.value,
    required this.display,
    this.isError = false,
    this.errorMessage,
  });

  static CalculationResult error(String message) =>
      CalculationResult(display: 'Error', isError: true, errorMessage: message);
}

/// 科学计算器业务服务。
///
/// 封装 `math_expressions`，负责表达式规范化、角度模式切换、
/// 函数注册、求值与结果格式化。
class ScientificCalculatorService {
  static const String _errorDivideByZero = '除数不能为零';
  static const String _errorNegativeSqrt = '负数不能开平方';
  static const String _errorLogNonPositive = '对数真数必须大于零';
  static const String _errorMismatchedBrackets = '括号不匹配';
  static const String _errorSyntax = '表达式格式错误';
  static const String _errorFactorial = '阶乘只能对非负整数求值';
  static const String _errorUnknown = '计算错误';

  final ExpressionParser _parser;

  ScientificCalculatorService() : _parser = ShuntingYardParser() {
    _registerFunctions();
  }

  /// 计算表达式并返回格式化结果。
  CalculationResult evaluate(
    String expression, {
    required bool degrees,
    required int precision,
    required bool scientificNotation,
  }) {
    if (expression.trim().isEmpty) {
      return const CalculationResult(display: '');
    }

    final normalized = normalizeExpression(expression);
    if (!_bracketsBalanced(normalized)) {
      return CalculationResult.error(_errorMismatchedBrackets);
    }

    try {
      final angleApplied = applyAngleMode(normalized, degrees);
      final exp = _parser.parse(angleApplied);
      final context = ContextModel()
        ..bindVariable(Variable('pi'), Number(math.pi))
        ..bindVariable(Variable('e'), Number(math.e));
      final result = exp.evaluate(EvaluationType.REAL, context) as double;

      if (result.isInfinite) {
        return CalculationResult.error(_errorDivideByZero);
      }
      if (result.isNaN) {
        return CalculationResult.error(_errorUnknown);
      }

      final display = formatResult(
        result,
        precision: precision,
        scientificNotation: scientificNotation,
      );
      return CalculationResult(value: result, display: display);
    } on FormatException catch (e) {
      final message = _mapFormatException(e.message);
      return CalculationResult.error(message);
    } catch (e) {
      return CalculationResult.error(_mapRuntimeError(e.toString()));
    }
  }

  /// 规范化表达式，将界面符号转换为 `math_expressions` 可解析形式。
  ///
  /// - `×` → `*`，`÷` → `/`
  /// - 去除空格
  /// - `%` 对紧邻数字生效：`50%` → `(50/100)`
  /// - 科学计数法 `1e-12` → `(1*10^-12)`
  /// - 自然常数 `e` → 数值
  static String normalizeExpression(String expression) {
    var normalized = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '');

    // 处理科学计数法输入（必须在替换独立 e 之前完成）。
    normalized = _normalizeScientificNotation(normalized);

    // 处理自然常数 e：ShuntingYardParser 把 e 当作 e^x 函数。
    normalized = _normalizeEulerConstant(normalized);

    // 处理百分号：仅对紧邻数字生效。
    normalized = _normalizePercent(normalized);

    return normalized;
  }

  static String _normalizeScientificNotation(String input) {
    // 匹配数字（含小数）后跟 e/E 与可选正负指数。
    final regex = RegExp(r'(\d+(?:\.\d*)?|\d*\.\d+)[eE]([+-]?\d+)');
    return input.replaceAllMapped(regex, (match) {
      final number = match.group(1);
      final exponent = match.group(2);
      return '($number*10^$exponent)';
    });
  }

  static String _normalizeEulerConstant(String input) {
    // 匹配独立的 e（非科学计数法中的 e）。
    return input.replaceAllMapped(RegExp(r'\be\b'), (_) => '(${math.e})');
  }

  static String _normalizePercent(String input) {
    return _normalizePercentByRegex(input);
  }

  static String _normalizePercentByRegex(String input) {
    // 匹配数字（含小数）后跟 % 的场景。
    final percentRegex = RegExp(r'(\d+(?:\.\d*)?|\d*\.\d+)%');
    return input.replaceAllMapped(percentRegex, (match) {
      final number = match.group(1);
      return '($number/100)';
    });
  }

  /// 格式化计算结果。
  static String formatResult(
    double value, {
    required int precision,
    required bool scientificNotation,
  }) {
    if (value.isNaN) return 'Error';
    if (value.isInfinite) return 'Error';

    if (scientificNotation) {
      return _formatScientific(value, precision);
    }

    // 极大或极小值自动转科学计数法。
    final absValue = value.abs();
    if ((absValue >= 1e10 && absValue != 0) ||
        (absValue < 1e-10 && absValue != 0)) {
      return _formatScientific(value, precision);
    }

    // 按精度四舍五入并去除末尾 0。
    final rounded = _round(value, precision);
    return _trimTrailingZeros(rounded.toStringAsFixed(precision));
  }

  static String _formatScientific(double value, int precision) {
    final absValue = value.abs();
    if (absValue == 0) return '0';

    final exponent = (math.log(absValue) / math.ln10).floor();
    final mantissa = value / math.pow(10, exponent);
    final roundedMantissa = _round(mantissa, precision);
    final mantissaStr = _trimTrailingZeros(roundedMantissa.toStringAsFixed(precision));

    final expSign = exponent >= 0 ? '+' : '-';
    final expValue = exponent.abs().toString().padLeft(2, '0');
    return '${mantissaStr}E$expSign$expValue';
  }

  static double _round(double value, int precision) {
    final factor = math.pow(10, precision).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  static String _trimTrailingZeros(String value) {
    if (value.contains('e')) return value;
    if (!value.contains('.')) return value;

    var result = value;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// 注册自定义函数，覆盖默认三角/对数/根号等函数，统一处理定义域与角度模式。
  void _registerFunctions() {
    // DEG 模式三角函数。
    _parser.addFunction('sin_deg', _wrapSingleArg(math.sin, degInput: true));
    _parser.addFunction('cos_deg', _wrapSingleArg(math.cos, degInput: true));
    _parser.addFunction('tan_deg', _wrapSingleArg(math.tan, degInput: true));
    _parser.addFunction('asin_deg', _wrapSingleArg((x) => math.asin(x) * 180 / math.pi));
    _parser.addFunction('acos_deg', _wrapSingleArg((x) => math.acos(x) * 180 / math.pi));
    _parser.addFunction('atan_deg', _wrapSingleArg((x) => math.atan(x) * 180 / math.pi));

    // RAD 模式三角函数。
    _parser.addFunction('sin_rad', _wrapSingleArg(math.sin));
    _parser.addFunction('cos_rad', _wrapSingleArg(math.cos));
    _parser.addFunction('tan_rad', _wrapSingleArg(math.tan));
    _parser.addFunction('asin_rad', _wrapSingleArg(math.asin));
    _parser.addFunction('acos_rad', _wrapSingleArg(math.acos));
    _parser.addFunction('atan_rad', _wrapSingleArg(math.atan));

    // 平方根：检查负数。
    _parser.addFunction('sqrt', (List<double> args) {
      final x = args[0];
      if (x < 0) throw FormatException(_errorNegativeSqrt);
      return math.sqrt(x);
    }, replace: true);

    // 自然对数：检查非正数。
    _parser.addFunction('ln', (List<double> args) {
      final x = args[0];
      if (x <= 0) throw FormatException(_errorLogNonPositive);
      return math.log(x);
    }, replace: true);

    // 以 10 为底的对数：检查非正数。
    _parser.addFunction('log', (List<double> args) {
      final x = args[0];
      if (x <= 0) throw FormatException(_errorLogNonPositive);
      return math.log(x) / math.ln10;
    }, replace: true);

    // 绝对值。
    _parser.addFunction('abs', (List<double> args) => args[0].abs(), replace: true);

    // 阶乘。
    _parser.addFunction('fac', (List<double> args) {
      final n = args[0];
      if (n < 0 || n != n.truncateToDouble()) {
        throw FormatException(_errorFactorial);
      }
      return _factorial(n.toInt());
    });
  }

  static double Function(List<double>) _wrapSingleArg(
    double Function(double) fn, {
    bool degInput = false,
  }) {
    return (List<double> args) {
      var x = args[0];
      if (degInput) x = x * math.pi / 180;
      return fn(x);
    };
  }

  static double _factorial(int n) {
    if (n > 170) return double.infinity;
    var result = 1.0;
    for (var i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  /// 根据角度模式转换表达式中的三角函数名。
  ///
  /// DEG 模式替换为 `_deg` 后缀函数；RAD 模式替换为 `_rad` 后缀函数。
  static String applyAngleMode(String expression, bool degrees) {
    final suffix = degrees ? '_deg' : '_rad';
    return expression
        .replaceAllMapped(RegExp(r'\bsin\b'), (_) => 'sin$suffix')
        .replaceAllMapped(RegExp(r'\bcos\b'), (_) => 'cos$suffix')
        .replaceAllMapped(RegExp(r'\btan\b'), (_) => 'tan$suffix')
        .replaceAllMapped(RegExp(r'\basin\b'), (_) => 'asin$suffix')
        .replaceAllMapped(RegExp(r'\bacos\b'), (_) => 'acos$suffix')
        .replaceAllMapped(RegExp(r'\batan\b'), (_) => 'atan$suffix');
  }

  /// 检查括号是否平衡。
  static bool _bracketsBalanced(String expression) {
    var depth = 0;
    for (final ch in expression.split('')) {
      if (ch == '(') depth++;
      if (ch == ')') depth--;
      if (depth < 0) return false;
    }
    return depth == 0;
  }

  String _mapFormatException(String message) {
    if (message == _errorDivideByZero) return _errorDivideByZero;
    if (message == _errorNegativeSqrt) return _errorNegativeSqrt;
    if (message == _errorLogNonPositive) return _errorLogNonPositive;
    if (message == _errorFactorial) return _errorFactorial;

    final lower = message.toLowerCase();
    if (lower.contains('bracket') || lower.contains('parenthesis')) {
      return _errorMismatchedBrackets;
    }
    return _errorSyntax;
  }

  String _mapRuntimeError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('divide by zero') || lower.contains('division by zero')) {
      return _errorDivideByZero;
    }
    if (lower.contains('sqrt') && lower.contains('negative')) {
      return _errorNegativeSqrt;
    }
    if (lower.contains('log') && lower.contains('positive')) {
      return _errorLogNonPositive;
    }
    if (lower.contains('factorial')) {
      return _errorFactorial;
    }
    return _errorUnknown;
  }
}
