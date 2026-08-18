import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/core/files/picked_file.dart';

void main() {
  group('PickedFile', () {
    test('完整字段构造后各 getter 正确返回', () {
      final file = PickedFile(
        name: 'photo.png',
        path: r'C:\tmp\photo.png',
        extension: 'png',
        sizeBytes: 1024,
        mimeType: 'image/png',
      );

      expect(file.name, 'photo.png');
      expect(file.path, r'C:\tmp\photo.png');
      expect(file.extension, 'png');
      expect(file.sizeBytes, 1024);
      expect(file.mimeType, 'image/png');
    });

    test('未提供读取回调时 readContent 返回空字节', () async {
      final file = PickedFile(name: 'a.txt', path: 'a.txt');
      final bytes = await file.readContent();
      expect(bytes, isEmpty);
    });

    test('readContent 委托给传入的读取回调', () async {
      const expected = 0xFF;
      final file = PickedFile(
        name: 'a.bin',
        path: 'a.bin',
        readBytes: () async => Uint8List.fromList([expected]),
      );
      final bytes = await file.readContent();
      expect(bytes, [expected]);
    });

    test('sizeBytes 与 mimeType 缺失时为 null', () {
      final file = PickedFile(name: 'a', path: 'a');
      expect(file.sizeBytes, isNull);
      expect(file.mimeType, isNull);
      expect(file.extension, isNull);
    });
  });
}