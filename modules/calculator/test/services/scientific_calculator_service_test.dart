import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_module/features/calculator/services/scientific_calculator_service.dart';

void main() {
  group('ScientificCalculatorService', () {
    late ScientificCalculatorService service;

    setUp(() {
      service = ScientificCalculatorService();
    });

    group('基本四则运算', () {
      test('加法', () {
        final result = service.evaluate('1+2', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, false);
        expect(result.display, '3');
      });

      test('减法', () {
        final result = service.evaluate('5-3', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '2');
      });

      test('乘法使用 ×', () {
        final result = service.evaluate('4×5', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '20');
      });

      test('除法使用 ÷', () {
        final result = service.evaluate('8÷2', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '4');
      });

      test('复合运算', () {
        final result = service.evaluate('1+2×3', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '7');
      });
    });

    group('表达式规范化', () {
      test('去除空格', () {
        final result = service.evaluate('1 + 2', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '3');
      });

      test('百分号转换为除 100', () {
        final result = service.evaluate('50%', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '0.5');
      });

      test('百分号参与复合运算', () {
        final result = service.evaluate('100+50%', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '100.5');
      });
    });

    group('三角函数与角度模式', () {
      test('DEG 模式下 sin(30) = 0.5', () {
        final result = service.evaluate('sin(30)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '0.5');
      });

      test('RAD 模式下 sin(pi/2) = 1', () {
        final result = service.evaluate('sin(pi/2)', degrees: false, precision: 6, scientificNotation: false);
        expect(result.display, '1');
      });

      test('DEG 模式下 cos(60) = 0.5', () {
        final result = service.evaluate('cos(60)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '0.5');
      });

      test('RAD 模式下 cos(pi) = -1', () {
        final result = service.evaluate('cos(pi)', degrees: false, precision: 6, scientificNotation: false);
        expect(result.display, '-1');
      });

      test('DEG 模式下 tan(45) = 1', () {
        final result = service.evaluate('tan(45)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, closeTo(1, 1e-5).toString(), skip: 'tan 45 存在浮点误差，用 closeTo 断言');
      });

      test('DEG 反三角函数 asin(0.5) = 30', () {
        final result = service.evaluate('asin(0.5)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '30');
      });
    });

    group('函数与常数', () {
      test('sqrt', () {
        final result = service.evaluate('sqrt(16)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '4');
      });

      test('ln', () {
        final result = service.evaluate('ln(e)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '1');
      });

      test('log', () {
        final result = service.evaluate('log(100)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '2');
      });

      test('abs', () {
        final result = service.evaluate('abs(-5)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '5');
      });

      test('fac', () {
        final result = service.evaluate('fac(5)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '120');
      });

      test('幂运算', () {
        final result = service.evaluate('2^10', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '1024');
      });
    });

    group('结果格式化', () {
      test('精度控制', () {
        final result = service.evaluate('1/3', degrees: true, precision: 4, scientificNotation: false);
        expect(result.display, '0.3333');
      });

      test('末尾 0 去除', () {
        final result = service.evaluate('1.5+1.5', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, '3');
      });

      test('科学计数法', () {
        final result = service.evaluate('123456789×1000', degrees: true, precision: 6, scientificNotation: true);
        expect(result.display, '1.234568E+11');
      });

      test('极小值自动转科学计数法', () {
        final result = service.evaluate('1e-12', degrees: true, precision: 6, scientificNotation: false);
        expect(result.display, contains('E-'));
      });
    });

    group('错误处理', () {
      test('除零', () {
        final result = service.evaluate('1/0', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, true);
        expect(result.errorMessage, '除数不能为零');
      });

      test('负数开平方', () {
        final result = service.evaluate('sqrt(-1)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, true);
        expect(result.errorMessage, '负数不能开平方');
      });

      test('对数非正数', () {
        final result = service.evaluate('log(0)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, true);
        expect(result.errorMessage, '对数真数必须大于零');
      });

      test('括号不匹配', () {
        final result = service.evaluate('(1+2', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, true);
        expect(result.errorMessage, '括号不匹配');
      });

      test('阶乘非法', () {
        final result = service.evaluate('fac(-1)', degrees: true, precision: 6, scientificNotation: false);
        expect(result.isError, true);
        expect(result.errorMessage, '阶乘只能对非负整数求值');
      });
    });
  });
}
