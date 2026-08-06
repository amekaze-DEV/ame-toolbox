import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_module/features/calculator/services/radix_converter_service.dart';

void main() {
  group('RadixConverterService', () {
    late RadixConverterService service;

    setUp(() {
      service = RadixConverterService();
    });

    group('进制互转', () {
      test('0b1010 转十进制等于 10', () {
        final result = service.convert('0b1010', RadixType.binary, RadixType.decimal);
        expect(result, '10');
      });

      test('十进制 10 转二进制等于 0b1010', () {
        final result = service.convert('10', RadixType.decimal, RadixType.binary);
        expect(result, '0b1010');
      });

      test('十进制 10 转八进制等于 0o12', () {
        final result = service.convert('10', RadixType.decimal, RadixType.octal);
        expect(result, '0o12');
      });

      test('十进制 10 转八进制再转回十进制仍为 10', () {
        final octal = service.convert('10', RadixType.decimal, RadixType.octal);
        expect(octal, '0o12');
        final decimal = service.convert(octal, RadixType.octal, RadixType.decimal);
        expect(decimal, '10');
      });

      test('十进制 10 转十六进制等于 0xA', () {
        final result = service.convert('10', RadixType.decimal, RadixType.hex);
        expect(result, '0xA');
      });

      test('0xFF 转十进制等于 255', () {
        final result = service.convert('0xFF', RadixType.hex, RadixType.decimal);
        expect(result, '255');
      });

      test('0xA 转二进制等于 0b1010', () {
        final result = service.convert('0xA', RadixType.hex, RadixType.binary);
        expect(result, '0b1010');
      });

      test('0o77 转十六进制等于 0x3F', () {
        final result = service.convert('0o77', RadixType.octal, RadixType.hex);
        expect(result, '0x3F');
      });

      test('空输入返回空字符串', () {
        final result = service.convert('', RadixType.decimal, RadixType.binary);
        expect(result, '');
      });

      test('仅前缀输入返回空字符串', () {
        final result = service.convert('0b', RadixType.binary, RadixType.decimal);
        expect(result, '');
      });
    });

    group('小数转换', () {
      test('十进制 0.5 转二进制等于 0b0.1', () {
        final result = service.convert('0.5', RadixType.decimal, RadixType.binary);
        expect(result, '0b0.1');
      });

      test('十进制 0.1 转二进制截断为 8 位', () {
        String? hint;
        final result = service.convert(
          '0.1',
          RadixType.decimal,
          RadixType.binary,
          onHint: (h) => hint = h,
        );
        expect(result, startsWith('0b0.'));
        expect(hint, '二进制小数已截断');
      });

      test('二进制 0b0.1 转十进制等于 0.5', () {
        final result = service.convert('0b0.1', RadixType.binary, RadixType.decimal);
        expect(result, '0.5');
      });

      test('非十进制小数互转返回错误提示', () {
        String? hint;
        final result = service.convert(
          '0b0.1',
          RadixType.binary,
          RadixType.hex,
          onHint: (h) => hint = h,
        );
        expect(result, '');
        expect(hint, '非十进制暂不支持小数互转');
      });
    });

    group('负数', () {
      test('十进制 -10 转二进制等于 -0b1010', () {
        final result = service.convert('-10', RadixType.decimal, RadixType.binary);
        expect(result, '-0b1010');
      });

      test('非十进制负数返回错误提示', () {
        String? hint;
        final result = service.convert(
          '-0b1010',
          RadixType.binary,
          RadixType.decimal,
          onHint: (h) => hint = h,
        );
        expect(result, '');
        expect(hint, '非十进制仅支持正数');
      });
    });

    group('非法输入', () {
      test('十进制输入多个小数点返回空', () {
        final result = service.convert('1.2.3', RadixType.decimal, RadixType.binary);
        expect(result, '');
      });

      test('二进制输入包含 2 返回空', () {
        String? hint;
        final result = service.convert(
          '0b102',
          RadixType.binary,
          RadixType.decimal,
          onHint: (h) => hint = h,
        );
        expect(result, '');
        expect(hint, '输入包含非法字符');
      });

      test('isValid 对非法字符返回 false', () {
        expect(service.isValid('0b102', RadixType.binary), isFalse);
        expect(service.isValid('0xGG', RadixType.hex), isFalse);
      });

      test('isValid 对合法输入返回 true', () {
        expect(service.isValid('0b1010', RadixType.binary), isTrue);
        expect(service.isValid('-10.5', RadixType.decimal), isTrue);
        expect(service.isValid('0xFF', RadixType.hex), isTrue);
      });
    });


  });
}
