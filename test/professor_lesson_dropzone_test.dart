import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/core/widgets/file_drop_zone.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/features/professor/presentation/screens/professor_create_course_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('type PDF affiche la zone upload, type vidéo le lien',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AkadexTheme.light(),
          home: const ProfessorCreateCourseScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Descend jusqu’aux leçons (sous les champs parcours).
    final lessonLabel = find.text('Leçon 1');
    await tester.scrollUntilVisible(
      lessonLabel,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('Lien vidéo'), findsOneWidget);
    expect(find.byType(FileDropZone), findsNothing);

    await tester.tap(find.text('PDF'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FileDropZone), findsOneWidget);
    expect(
      find.text('Glisser-déposer le fichier de la leçon'),
      findsOneWidget,
    );
    expect(find.textContaining('Lien vidéo'), findsNothing);
  });
}
