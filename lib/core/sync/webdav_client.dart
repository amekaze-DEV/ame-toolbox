import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'package:ametoolbox/core/sync/sync_exception.dart';

/// 基于 [webdav_client] 的 WebDAV 协议封装。
///
/// 负责连接测试、目录创建、JSON 数据上传/下载以及旧版本归档。
/// 所有网络错误均转换为面向用户的 [SyncException]。
class WebDavClient {
  WebDavClient({
    required String baseUrl,
    required this.username,
    required this.password,
  }) {
    final normalized = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    _client = webdav.newClient(
      normalized,
      user: username,
      password: password,
      debug: false,
    );
    _client
      ..setConnectTimeout(8000)
      ..setSendTimeout(8000)
      ..setReceiveTimeout(8000);
  }

  late final webdav.Client _client;
  final String username;
  final String password;

  /// 发送 PROPFIND 请求验证连通性与凭据。
  Future<bool> testConnection() async {
    try {
      await _client.ping();
      return true;
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  /// 确保远程目录存在，不存在则递归创建。
  Future<void> ensureDirectory(String path) async {
    try {
      await _client.mkdirAll(path);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  /// 将 JSON 字符串上传到远程路径。
  Future<void> uploadJson(
    String jsonString,
    String remotePath, {
    void Function(int count, int total)? onProgress,
  }) async {
    final data = Uint8List.fromList(utf8.encode(jsonString));
    try {
      await _client.write(remotePath, data, onProgress: onProgress);
    } on DioException catch (e) {
      _throwFromDio(e);
    }
  }

  /// 从远程路径下载文本内容。
  ///
  /// 远程文件不存在时返回 `null`。
  Future<String?> readString(String remotePath) async {
    try {
      final bytes = await _client.read(remotePath);
      if (bytes.isEmpty) return null;
      return utf8.decode(bytes);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      _throwFromDio(e);
    }
  }

  /// 将指定模块的旧版本数据归档到 `/archive/` 目录。
  Future<void> archive({
    required String moduleId,
    required Map<String, dynamic> data,
    required String devicePath,
  }) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final archivePath = '$devicePath/archive/${moduleId}_$timestamp.json';
    await uploadJson(jsonEncode(data), archivePath);
  }

  Never _throwFromDio(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw const SyncException('认证失败，请检查用户名和密码');
    }
    if (status == 404) {
      throw SyncException('服务器路径不存在: ${e.requestOptions.path}');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw const SyncException('无法连接到服务器，请检查地址或网络');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      throw const SyncException('网络不可用，请检查连接');
    }
    throw SyncException('网络错误: ${e.message}');
  }
}
