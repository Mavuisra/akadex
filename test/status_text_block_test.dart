import 'package:akadex/core/theme/status_backgrounds.dart';
import 'package:akadex/core/widgets/status_text_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('texte court éligible, trop long non', () {
    expect(StatusBackgrounds.isShortEnough('A chacun sa petite vie'), isTrue);
    expect(
      StatusBackgrounds.isShortEnough('x' * (StatusBackgrounds.maxChars + 1)),
      isFalse,
    );
  });

  test('texte court sans couleur → fond bleu par défaut', () {
    final color = StatusBackgrounds.resolveDisplayColor(
      content: 'Bonjour cette application est interessante',
      hasMedia: false,
    );
    expect(color, StatusBackgrounds.parse(StatusBackgrounds.defaultHex));
  });

  test('tag bg: récupéré si pas de champ API', () {
    expect(
      StatusBackgrounds.hexFromTags(['discussion', 'bg:#F02849']),
      '#F02849',
    );
    final color = StatusBackgrounds.resolveDisplayColor(
      content: 'Hello',
      hasMedia: false,
      tags: ['bg:#31A24C'],
    );
    expect(color, StatusBackgrounds.parse('#31A24C'));
  });

  test('média ou texte long → pas de fond', () {
    expect(
      StatusBackgrounds.resolveDisplayColor(
        content: 'Court',
        hasMedia: true,
        backgroundColor: '#1877F2',
      ),
      isNull,
    );
    expect(
      StatusBackgrounds.resolveDisplayColor(
        content: 'x' * 200,
        hasMedia: false,
        backgroundColor: '#1877F2',
      ),
      isNull,
    );
  });

  testWidgets('PostBodyText affiche le fond même sans backgroundColor',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PostBodyText(content: 'Hello Akadex'),
        ),
      ),
    );
    expect(find.byType(StatusTextBlock), findsOneWidget);
    expect(find.text('Hello Akadex'), findsOneWidget);
  });

  testWidgets('PostBodyText masque le style si texte trop long', (tester) async {
    final long = 'a' * (StatusBackgrounds.maxChars + 20);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostBodyText(content: long, backgroundColor: '#1877F2'),
        ),
      ),
    );
    expect(find.byType(StatusTextBlock), findsNothing);
    expect(find.text(long), findsOneWidget);
  });
}
