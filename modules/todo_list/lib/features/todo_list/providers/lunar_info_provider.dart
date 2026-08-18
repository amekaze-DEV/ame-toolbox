import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lunar_info_service.dart';

/// 注入 [LunarInfoService] 纯函数服务。
final lunarInfoServiceProvider = Provider<LunarInfoService>((ref) {
  return LunarInfoService();
});