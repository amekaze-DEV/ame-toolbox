import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/note_rich_text_parser.dart';

/// 注入富文本解析 / 渲染分发服务。
final noteRichTextParserProvider = Provider<NoteRichTextParser>((ref) {
  return const NoteRichTextParser();
});
