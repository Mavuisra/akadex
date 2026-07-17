import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/mocks/mock_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _quick = [
    (Icons.menu_book_outlined, 'Cours'),
    (Icons.assignment_outlined, 'Examens'),
    (Icons.science_outlined, 'TP / TD'),
    (Icons.auto_stories_outlined, 'Livres'),
    (Icons.play_circle_outline, 'Vidéos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Akadex',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AkadexColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SearchField(
              hint: 'Rechercher un cours, document, prof…',
              readOnly: true,
              onTap: () => context.push('/search'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A47B8), Color(0xFF3B6BE0)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bienvenue sur Akadex',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tes ressources académiques\nen un seul endroit.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AkadexColors.primary,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () => context.go('/library'),
                          child: const Text('Explorer'),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle('Accès rapide'),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final q in _quick)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onTap: () => context.go('/explorer'),
                        child: Column(
                          children: [
                            Icon(q.$1, color: AkadexColors.primary, size: 22),
                            const SizedBox(height: 8),
                            Text(
                              q.$2,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AkadexColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SectionTitle(
              'Nouveautés',
              action: 'Voir tout',
              onAction: () => context.go('/library'),
            ),
            const SizedBox(height: 8),
            ...MockData.docs.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SoftCard(
                  delay: Duration(milliseconds: 60 * e.key),
                  onTap: () => context.push('/library/document/${e.value.id}'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AkadexColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AkadexColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AkadexColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.value.meta,
                              style: const TextStyle(
                                color: AkadexColors.inkMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DocTypeTag(e.value.type),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SoftCard(
              delay: const Duration(milliseconds: 200),
              onTap: () => context.push('/ai'),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AkadexColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akadex IA',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AkadexColors.ink,
                          ),
                        ),
                        Text(
                          'Ton assistant d’étude intelligent',
                          style: TextStyle(
                            color: AkadexColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SoftCard(
              delay: const Duration(milliseconds: 260),
              onTap: () => context.push('/calendar'),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: AkadexColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendrier',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AkadexColors.ink,
                          ),
                        ),
                        Text(
                          'Examens, délibérations, événements',
                          style: TextStyle(
                            color: AkadexColors.inkMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
