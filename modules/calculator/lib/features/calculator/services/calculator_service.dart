import 'dart:math' as math;

import '../models/calculation.dart';

/// 多功能计算器核心计算服务。
///
/// 当前实现支持四则运算、括号、百分号与常见数学函数。
/// 后续可在隔离环境中扩展单位换算、进制转换等能力。
class CalculatorService {
  const CalculatorService();

  /// 计算表达式并返回结果。
  ///
  /// 返回 [Calculation] 包含原始表达式与结果字符串；
  /// 若表达式非法，则抛出 [FormatException]。
  Calculation evaluate(String expression) {
    final sanitized = _sanitize(expression);
    final result = _compute(_tokenize(sanitized));
    return Calculation(
      expression: expression,
      result: _formatResult(result),
      timestamp: DateTime.now(),
    );
  }

  String _sanitize(String input) {
    return input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '')
        .replaceAll('%', '/100');
  }

  List<String> _tokenize(String expression) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];
      if (_isDigitOrDot(char)) {
        buffer.write(char);
      } else if (_isFunctionStart(expression, i)) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        final func = _readFunction(expression, i);
        tokens.add(func);
        i += func.length - 1;
      } else {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
      }
    }
    if (buffer.isNotEmpty) tokens.add(buffer.toString());
    return tokens;
  }

  bool _isDigitOrDot(String char) =>
      (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) || char == '.';

  bool _isFunctionStart(String expression, int index) {
    const functions = ['sqrt', 'sin', 'cos', 'tan', 'log', 'ln'];
    return functions.any((f) => expression.startsWith(f, index));
  }

  String _readFunction(String expression, int index) {
    const functions = ['sqrt', 'sin', 'cos', 'tan', 'log', 'ln'];
    return functions.firstWhere((f) => expression.startsWith(f, index));
  }

  double _compute(List<String> tokens) {
    // 中缀转后缀（调度场算法）
    final output = <String>[];
    final operators = <String>[];

    for (final token in tokens) {
      if (_isNumber(token)) {
        output.add(token);
      } else if (_isFunction(token)) {
        operators.add(token);
      } else if (token == ',') {
        while (operators.isNotEmpty && operators.last != '(') {
          output.add(operators.removeLast());
        }
      } else if (_isOperator(token)) {
        while (operators.isNotEmpty &&
            operators.last != '(' &&
            _precedence(operators.last) >= _precedence(token)) {
          output.add(operators.removeLast());
        }
        operators.add(token);
      } else if (token == '(') {
        operators.add(token);
      } else if (token == ')') {
        while (operators.isNotEmpty && operators.last != '(') {
          output.add(operators.removeLast());
        }
        if (operators.isEmpty) throw const FormatException('括号不匹配');
        operators.removeLast(); // 弹出 '('
        if (operators.isNotEmpty && _isFunction(operators.last)) {
          output.add(operators.removeLast());
        }
      } else {
        throw FormatException('未知符号: $token');
      }
    }

    while (operators.isNotEmpty) {
      final op = operators.removeLast();
      if (op == '(' || op == ')') throw const FormatException('括号不匹配');
      output.add(op);
    }

    return _evaluateRpn(output);
  }

  bool _isNumber(String token) => double.tryParse(token) != null;

  bool _isFunction(String token) =>
      ['sqrt', 'sin', 'cos', 'tan', 'log', 'ln'].contains(token);

  bool _isOperator(String token) =>
      token == '+' || token == '-' || token == '*' || token == '/' || token == '^';

  int _precedence(String op) {
    switch (op) {
      case '+':
      case '-':
        return 1;
      case '*':
      case '/':
        return 2;
      case '^':
        return 3;
      default:
        return 0;
    }
  }

  double _evaluateRpn(List<String> rpn) {
    final stack = <double>[];
    for (final token in rpn) {
      if (_isNumber(token)) {
        stack.add(double.parse(token));
      } else if (_isFunction(token)) {
        if (stack.isEmpty) throw const FormatException('函数参数不足');
        final value = stack.removeLast();
        stack.add(_applyFunction(token, value));
      } else if (_isOperator(token)) {
        if (stack.length < 2) throw const FormatException('运算符操作数不足');
        final b = stack.removeLast();
        final a = stack.removeLast();
        stack.add(_applyOperator(token, a, b));
      }
    }
    if (stack.length != 1) throw const FormatException('表达式格式错误');
    return stack.single;
  }

  double _applyOperator(String op, double a, double b) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '*':
        return a * b;
      case '/':
        if (b == 0) throw const FormatException('除数不能为零');
        return a / b;
      case '^':
        return math.pow(a, b).toDouble();
      default:
        throw FormatException('未知运算符: $op');
    }
  }

  double _applyFunction(String func, double value) {
    switch (func) {
      case 'sqrt':
        if (value < 0) throw const FormatException('负数不能开平方');
        return math.sqrt(value);
      case 'sin':
        return math.sin(value);
      case 'cos':
        return math.cos(value);
      case 'tan':
        return math.tan(value);
      case 'log':
        if (value <= 0) throw const FormatException('对数真数必须大于零');
        return math.log(value) / math.ln10;
      case 'ln':
        if (value <= 0) throw const FormatException('对数真数必须大于零');
        return math.log(value);
      default:
        throw FormatException('未知函数: $func');
    }
  }

  String _formatResult(double value) {
    if (value.isInfinite || value.isNaN) return 'Error';
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsPrecision(12).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}
