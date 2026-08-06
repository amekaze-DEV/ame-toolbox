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
      _throwFromDio(e, operation: 'ping', path: '');
    }
  }

  /// 确保远程目录存在，不存在则递归创建。
  Future<void> ensureDirectory(String path) async {
    final normalized = _normalizePath(path);
    if (normalized.isEmpty) return;
    try {
      // 使用自定义 MKCOL 请求，设置 Content-Type，兼容坚果云等严格服务器。
      await _rawRequest('MKCOL', normalized, optionsHandler: (options) {
        options.headers?['content-type'] = 'text/xml; charset=utf-8';
      });
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 405 Method Not Allowed 或 409 Conflict 通常表示目录已存在，可忽略。
      // 部分 WebDAV 服务器对 MKCOL 返回 400，先忽略并继续，让 read/write 暴露真实错误。
      if (status == 405 || status == 409 || status == 400) return;
      _throwFromDio(e, operation: 'mkdirAll', path: normalized);
    }
  }

  /// 将 JSON 字符串上传到远程路径。
  Future<void> uploadJson(
    String jsonString,
    String remotePath, {
    void Function(int count, int total)? onProgress,
  }) async {
    final data = Uint8List.fromList(utf8.encode(jsonString));
    final normalized = _normalizePath(remotePath);
    try {
      await _ensureParentDirectory(normalized);
      await _rawRequest(
        'PUT',
        normalized,
        data: data,
        optionsHandler: (options) {
          options.headers?['content-type'] = 'application/json; charset=utf-8';
          options.headers?['content-length'] = data.length;
        },
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      _throwFromDio(e, operation: 'write', path: normalized);
    }
  }

  Future<void> _ensureParentDirectory(String path) async {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return;
    final parent = path.substring(0, lastSlash);
    await ensureDirectory(parent);
  }

  /// 通过底层 WdDio 发送原始请求。
  ///
  /// webdav_client 的 `write`/`mkdirAll` 默认请求格式在某些服务器（如坚果云）
  /// 上会被拒绝为 400 Bad Request，因此使用其内部 `req` 方法手动构造请求，
  /// 同时复用其认证与超时配置。
  Future<Response<dynamic>> _rawRequest(
    String method,
    String path, {
    dynamic data,
    void Function(Options options)? optionsHandler,
    void Function(int count, int total)? onSendProgress,
  }) async {
    // 通过 dynamic 访问 webdav_client 内部 WdDio 实例与 req 方法。
    final dio = (_client as dynamic).c as dynamic;
    final resp = await dio.req<dynamic>(
      _client,
      method,
      path,
      data: data,
      optionsHandler: optionsHandler,
      onSendProgress: onSendProgress,
    ) as Response<dynamic>;
    return resp;
  }

  /// 从远程路径下载文本内容。
  ///
  /// 远程文件不存在时返回 `null`。
  Future<String?> readString(String remotePath) async {
    final normalized = _normalizePath(remotePath);
    try {
      final bytes = await _client.read(normalized);
      if (bytes.isEmpty) return null;
      return utf8.decode(bytes);
    } on DioException catch (e) {
      // 404 表示文件不存在；409 在某些服务器（如坚果云）中表示父目录不存在。
      // 这两种情况都视为“无远程数据”，继续到上传流程。
      final status = e.response?.statusCode;
      if (status == 404 || status == 409) return null;
      _throwFromDio(e, operation: 'read', path: normalized);
    }
  }

  /// 将指定模块的旧版本数据归档到 `/archive/` 目录。
  Future<void> archive({
    required String moduleId,
    required Map<String, dynamic> data,
    required String devicePath,
  }) async {
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final archiveDir = '$devicePath/archive';
    final archivePath = '$archiveDir/${moduleId}_$timestamp.json';
    await ensureDirectory(archiveDir);
    await uploadJson(jsonEncode(data), archivePath);
  }

  /// 规范化远程路径。
  ///
  /// webdav_client 的 read/write/mkdirAll 均使用以 `/` 开头的绝对路径，
  /// 因此这里确保路径以单个 `/` 开头，并去除重复斜杠。
  String _normalizePath(String path) {
    if (path.isEmpty) return path;
    var normalized = path.replaceAll(RegExp(r'/+'), '/');
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    return normalized;
  }

  Never _throwFromDio(
    DioException e, {
    required String operation,
    required String path,
  }) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      throw const SyncException('认证失败，请检查用户名和密码');
    }
    if (status == 404) {
      throw SyncException('服务器路径不存在: $path');
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
    final detail = e.message ?? e.error?.toString() ?? '未知错误';
    throw SyncException(
      '[$operation] 网络错误 (HTTP $status, ${e.type.name}): $detail\n路径: $path',
    );
  }
}
