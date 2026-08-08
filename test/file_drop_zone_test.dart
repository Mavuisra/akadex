import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/core/widgets/file_drop_validator.dart';
import 'package:akadex/core/widgets/file_drop_zone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FileDropZone affiche titre et formats', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AkadexTheme.light(),
        home: Scaffold(
          body: FileDropZone(
            allowedExtensions: const ['pdf'],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Glisser-déposer un fichier'), findsOneWidget);
    expect(find.text('ou appuyer pour parcourir'), findsOneWidget);
    expect(find.textContaining('.pdf'), findsOneWidget);
    expect(find.textContaining('20 Mo'), findsOneWidget);
  });

  testWidgets('FileDropZone affiche le fichier sélectionné et permet de retirer',
      (tester) async {
    FileDropSelection? current = fileDropSelectionForTest(
      name: 'module1.pdf',
      bytes: List.filled(2048, 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AkadexTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return FileDropZone(
                allowedExtensions: const ['pdf'],
                fileName: current?.name,
                fileSize: current?.size,
                onChanged: (v) => setState(() => current = v),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('module1.pdf'), findsOneWidget);
    expect(find.text('2 Ko'), findsOneWidget);
    expect(find.text('Changer'), findsOneWidget);

    await tester.tap(find.byTooltip('Retirer'));
    await tester.pump();

    expect(current, isNull);
    expect(find.text('Glisser-déposer un fichier'), findsOneWidget);
  });
}
