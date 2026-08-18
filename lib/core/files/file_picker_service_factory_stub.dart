import 'file_picker_service.dart';

/// Web 平台占位工厂。
///
/// 当前项目不配置 Web 支持，此实现仅用于条件导入在 `dart.library.html` 下
/// 编译通过，调用时抛出明确异常。
FilePickerService createFilePickerService() {
  throw UnsupportedError('file_picker_service is not supported on web');
}