import 'package:ametoolbox/core/input/input_mode_scope.dart';
import 'package:ametoolbox/core/models/input_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_notes_module/features/sticky_notes/models/note_image_attachment.dart';
import 'package:sticky_notes_module/features/sticky_notes/widgets/note_image_block.dart';

/// 1x1 透明 PNG（base64），用于构造可解析的图片载荷。
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFAAH/q842iQAAAABJRU5ErkJggg==';

Widget wrap(Widget child) => InputModeScope(
      mode: InputMode.touch,
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  final createdAt = DateTime(2026, 9, 1, 10);

  NoteImageAttachment attachment(String data) => NoteImageAttachment(
        id: 'img',
        dataBase64: data,
        createdAt: createdAt,
      );

  testWidgets('渲染图片并支持删除回调', (tester) async {
    var deleted = 0;
    await tester.pumpWidget(
      wrap(
        NoteImageBlock(
          attachment: attachment(_pngBase64),
          onDelete: () => deleted++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.byTooltip('删除图片'));
    await tester.pumpAndSettle();
    expect(deleted, 1);
  });

  testWidgets('点击图片打开大图预览并可关闭', (tester) async {
    await tester.pumpWidget(
      wrap(NoteImageBlock(attachment: attachment(_pngBase64))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(IconButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭'), findsNothing);
  });

  testWidgets('损坏的 base64 渲染兜底占位', (tester) async {
    await tester.pumpWidget(
      wrap(NoteImageBlock(attachment: attachment('!!!not-base64!!!'))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('readOnly 隐藏删除入口', (tester) async {
    await tester.pumpWidget(
      wrap(
        NoteImageBlock(
          attachment: attachment(_pngBase64),
          onDelete: () {},
          readOnly: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('删除图片'), findsNothing);
  });
}