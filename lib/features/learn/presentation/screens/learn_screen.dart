import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../lmd/data/lmd_knowledge.dart';

/// Onglet « Apprendre » — guide LMD (fixe pour tous les utilisateurs).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  IconData _icon(String name) => switch (name) {
        'flag' => Icons.flag_outlined,
        'layers' => Icons.layers_outlined,
        'calendar' => Icons.calendar_view_month_outlined,
        'credit' => Icons.toll_outlined,
        'blocks' => Icons.view_module_outlined,
        'compare' => Icons.compare_arrows_rounded,
        'student' => Icons.person_outline_rounded,
        'school' => Icons.school_outlined,
        _ => Icons.school_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final sections = LmdKnowledge.sections;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        intensity: 0.85,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AkadexColors.background.withValues(alpha: 0.92),
              title: const Text(
                'Apprendre',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/lmd/assistant');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Assistant'),
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Système LMD',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Comprendre Licence · Master · Doctorat et naviguer ton parcours.',
                      style: TextStyle(
                        color: AkadexColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: FilledButton.tonalIcon(
                  onPressed: () => context.go('/library'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Voir les cours'),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final s = sections[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/lmd'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AkadexColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _icon(s.iconName),
                                color: AkadexColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    s.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AkadexColors.inkMuted,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
