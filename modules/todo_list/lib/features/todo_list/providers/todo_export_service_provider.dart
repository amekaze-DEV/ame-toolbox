import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/todo_export_service.dart';

/// 注入导出服务。
final todoExportServiceProvider =
    Provider<TodoExportService>((ref) => const TodoExportService());