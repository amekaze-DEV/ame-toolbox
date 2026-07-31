import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/services/calculator_service.dart';

void main() {
  group('CalculatorService', () {
    const service = CalculatorService();

    test('加法', () {
      final result = service.evaluate('1+2');
      expect(result.result, '3');
    });

    test('减法', () {
      final result = service.evaluate('10-4');
      expect(result.result, '6');
    });

    test('乘法（支持 × 符号）', () {
      final result = service.evaluate('3×4');
      expect(result.result, '12');
    });

    test('除法（支持 ÷ 符号）', () {
      final result = service.evaluate('8÷2');
      expect(result.result, '4');
    });

    test('百分号', () {
      final result = service.evaluate('50%');
      expect(result.result, '0.5');
    });

    test('括号优先级', () {
      final result = service.evaluate('(1+2)×3');
      expect(result.result, '9');
    });

    test('乘方', () {
      final result = service.evaluate('2^3');
      expect(result.result, '8');
    });

    test('函数 sqrt', () {
      final result = service.evaluate('sqrt(16)');
      expect(result.result, '4');
    });

    test('空格应被忽略', () {
      final result = service.evaluate(' 1 + 2 ');
      expect(result.result, '3');
    });

    test('除零抛出异常', () {
      expect(() => service.evaluate('1/0'), throwsFormatException);
    });

    test('括号不匹配抛出异常', () {
      expect(() => service.evaluate('(1+2'), throwsFormatException);
    });

    test('非法表达式抛出异常', () {
      expect(() => service.evaluate('1++2'), throwsFormatException);
    });
  });
}
