import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator_module/features/calculator/services/radix_converter_service.dart';
import 'package:calculator_module/features/calculator/widgets/radix_input_formatter.dart';

void main() {
  group('RadixInputFormatter', () {
    test('二进制只允许 0 和 1', () {
      final formatter = RadixInputFormatter(RadixType.binary);
      expect(_format(formatter, '', '1010').text, '1010');
      expect(_format(formatter, '10', '2').text, '10');
      expect(_format(formatter, '1', 'a').text, '1');
    });

    test('八进制只允许 0-7', () {
      final formatter = RadixInputFormatter(RadixType.octal);
      expect(_format(formatter, '', '77').text, '77');
      expect(_format(formatter, '7', '8').text, '7');
      expect(_format(formatter, '', '8').text, '');
    });

    test('十进制允许数字、一个小数点与开头负号', () {
      final formatter = RadixInputFormatter(RadixType.decimal);
      expect(_format(formatter, '', '123').text, '123');
      expect(_format(formatter, '', '-123').text, '-123');
      expect(_format(formatter, '1', '1.5').text, '1.5');
      expect(_format(formatter, '-1', '-1.5').text, '-1.5');
      expect(_format(formatter, '1.2', '1.2.3').text, '1.2');
      expect(_format(formatter, '1', '1-2').text, '1');
      expect(_format(formatter, '-', '--1').text, '-');
      expect(_format(formatter, '', 'a').text, '');
    });

    test('十六进制允许 0-9、A-F 并自动大写', () {
      final formatter = RadixInputFormatter(RadixType.hex);
      expect(_format(formatter, '', 'af').text, 'AF');
      expect(_format(formatter, 'AF', 'AF10').text, 'AF10');
      expect(_format(formatter, '', 'g').text, '');
      expect(_format(formatter, '1', '.2').text, '1');
    });

    test('空字符串保持不变', () {
      final formatter = RadixInputFormatter(RadixType.binary);
      expect(_format(formatter, '', '').text, '');
    });
  });
}

TextEditingValue _format(
  RadixInputFormatter formatter,
  String oldText,
  String newText,
) {
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    ),
  );
}
