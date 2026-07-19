import 'package:akadex/features/lmd/data/lmd_assistant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('répond sur les crédits selon le décret 22/39', () {
    final a = LmdAssistant.answer('Combien de crédits par semestre ?');
    expect(a.text.toLowerCase(), contains('30'));
    expect(a.text, contains('25'));
    expect(a.relatedSectionId, 'credits');
  });

  test('répond sur la durée de la licence', () {
    final a = LmdAssistant.answer('Combien de semestres pour la licence ?');
    expect(a.text, contains('6'));
    expect(a.relatedSectionId, 'cycles');
  });

  test('explique UE et EC', () {
    final a = LmdAssistant.answer('Différence entre UE et EC ?');
    expect(a.text.toLowerCase(), contains('ue'));
    expect(a.text.toLowerCase(), contains('tpe'));
  });
}
