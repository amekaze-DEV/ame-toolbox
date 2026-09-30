import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ametoolbox/core/files/file_launcher_service.dart';
import 'package:ametoolbox/core/files/file_launcher_service_factory.dart';
import 'package:ametoolbox/core/files/file_launcher_service_io.dart';
import 'package:ametoolbox/core/providers/file_provider.dart';

/// 记录系统查看器调用路径的测试桩：不真正启动系统查看器。
class _RecordingLauncher extends FileLauncherServiceIO {
  String? launchedPath;

  @override
  Future<void> launchSystemViewer(String path) async {
    launchedPath = path;
  }
}

void main() {
  group('createFileLauncherService', () {
    test('在 io 环境返回非空 FileLauncherService 实现', () {
      final service = createFileLauncherService();
      expect(service, isA<FileLauncherService>());
      expect(service, isA<FileLauncherServiceIO>());
    });
  });

  group('fileLauncherProvider', () {
    test('直接构造出可用服务，无需 override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(fileLauncherProvider);
      expect(service, isA<FileLauncherService>());
    });
  });

  group('FileLauncherServiceIO', () {
    test('openBytesWithDefaultApp 写入临时文件并调用系统查看器', () async {
      final launcher = _RecordingLauncher();
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      await launcher.openBytesWithDefaultApp(bytes, 'report.pdf');

      final path = launcher.launchedPath!;
      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(file.readAsBytesSync(), equals(bytes));
      // 落在系统临时目录下，且文件名源自用户提供。
      expect(Directory(path).parent.path.startsWith(Directory.systemTemp.path),
          isTrue);
      expect(path.endsWith('report.pdf'), isTrue);
      file.deleteSync(recursive: true);
    });

    test('文件名含路径字符会被清洗，避免路径穿越', () async {
      final launcher = _RecordingLauncher();
      await launcher.openBytesWithDefaultApp(
        Uint8List(0),
        r'..\..\evil.txt',
      );
      final path = launcher.launchedPath!;
      // 仅校验文件名的清洗结果：路径本身在 Windows 下必然含分隔符反斜杠。
      final fileName = path.split(Platform.pathSeparator).last;
      expect(fileName.contains('..'), isFalse);
      expect(fileName.contains('/'), isFalse);
      expect(fileName.contains('\\'), isFalse);
      File(path).deleteSync(recursive: true);
    });
  });
}