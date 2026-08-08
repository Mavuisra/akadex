import 'package:akadex/core/theme/akadex_theme.dart';
import 'package:akadex/core/widgets/file_drop_zone.dart';
import 'package:akadex/data/api/api_client.dart';
import 'package:akadex/features/library/presentation/screens/contribute_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ContributeScreen affiche dropzone fichier et masque pour Lien',
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
          home: const ContributeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    final dropTitle = find.text('Glisser-déposer ton document');
    await tester.scrollUntilVisible(
      dropTitle,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.byType(FileDropZone), findsOneWidget);
    expect(dropTitle, findsOneWidget);

    // Type « Ressource libre » (lien) → pas de dropzone.
    final linkChip = find.text('Ressource libre');
    await tester.scrollUntilVisible(
      linkChip,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(linkChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(FileDropZone), findsNothing);
    expect(find.textContaining('Lien de la ressource'), findsOneWidget);
  });
}
