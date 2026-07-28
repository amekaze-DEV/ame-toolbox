// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also read child widgets in the widget tree, read text, and
// verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ametoolbox/app.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:ametoolbox/core/models/layout_config.dart';
import 'package:ametoolbox/core/models/module_definition.dart';
import 'package:ametoolbox/core/models/module_state.dart';
import 'package:ametoolbox/core/models/sync_config.dart';
import 'package:ametoolbox/core/models/theme_config.dart';
import 'package:ametoolbox/core/platform/device_info_provider.dart';
import 'package:ametoolbox/core/platform/platform_info.dart';
import 'package:ametoolbox/core/providers/platform_provider.dart';
import 'package:ametoolbox/core/providers/storage_provider.dart';
import 'package:ametoolbox/core/storage/storage_service.dart';

void main() {
  testWidgets('App shows AMEToolbox title', (WidgetTester tester) async {
    // Build our app with mocked infrastructure providers and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformInfoProvider.overrideWithValue(_FakePlatformInfo()),
          storageServiceProvider.overrideWithValue(_FakeStorageService()),
          deviceInfoProvider.overrideWithValue(_FakeDeviceInfo()),
        ],
        child: const App(),
      ),
    );

    // Verify that the app title is shown.
    expect(find.text('AMEToolbox'), findsOneWidget);
  });
}

class _FakePlatformInfo implements PlatformInfo {
  @override
  AppPlatform get platform => AppPlatform.windows;

  @override
  bool get isDesktop => true;

  @override
  bool get isMobile => false;

  @override
  InputMode get defaultInputMode => InputMode.mouse;
}

class _FakeDeviceInfo implements DeviceInfoProvider {
  @override
  String get deviceId => 'test-device';

  @override
  String get osName => 'Windows';

  @override
  String get osVersion => '10';

  @override
  String get deviceModel => 'Test';

  @override
  String get appVersion => '1.0.0';

  @override
  String get appBuildNumber => '1';

  @override
  double get physicalDpi => 96.0;

  @override
  double? get physicalScreenSize => null;

  @override
  DeviceInputCapability get inputCapability => DeviceInputCapability.hybrid;
}

class _FakeStorageService implements StorageService {
  @override
  Future<void> initialize() async {}

  @override
  Future<List<ModuleDefinition>> getModuleDefinitions() async => [];

  @override
  Future<void> setModuleDefinitions(List<ModuleDefinition> definitions) async {}

  @override
  Future<List<ModuleState>> getModuleStates() async => [];

  @override
  Future<void> setModuleStates(List<ModuleState> states) async {}

  @override
  Future<ThemeConfig?> getThemeConfig() async => null;

  @override
  Future<void> setThemeConfig(ThemeConfig config) async {}

  @override
  Future<LayoutConfig?> getLayoutConfig() async => null;

  @override
  Future<void> setLayoutConfig(LayoutConfig config) async {}

  @override
  Future<SyncConfig?> getSyncConfig() async => null;

  @override
  Future<void> setSyncConfig(SyncConfig config) async {}

  @override
  Future<String?> getWebDavPassword() async => null;

  @override
  Future<void> setWebDavPassword(String password) async {}

  @override
  Future<String?> getDeviceId() async => null;

  @override
  Future<void> setDeviceId(String deviceId) async {}

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {}

  @override
  Future<Map<String, dynamic>?> loadData(String key) async => null;

  @override
  Future<void> deleteData(String key) async {}

  @override
  Future<void> clearAll() async {}
}
