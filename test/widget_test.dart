import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:akadex/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Akadex démarre sur le splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AkadexApp()));
    await tester.pumpAndSettle();

    expect(find.text('Akadex'), findsWidgets);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text("S'inscrire"), findsOneWidget);
  });
}
