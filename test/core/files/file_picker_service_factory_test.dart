import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/files/file_picker_service.dart';
import 'package:ametoolbox/core/files/file_picker_service_factory.dart';
import 'package:ametoolbox/core/files/file_picker_service_io.dart';
import 'package:ametoolbox/core/providers/file_provider.dart';

void main() {
  group('createFilePickerService', () {
    test('在 io 环境返回非空 FilePickerService 实现', () {
      final service = createFilePickerService();
      expect(service, isA<FilePickerService>());
      expect(service, isA<FilePickerServiceIO>());
    });
  });

  group('filePickerProvider', () {
    test('直接构造出可用服务，无需 override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(filePickerProvider);
      expect(service, isA<FilePickerService>());
    });
  });
}