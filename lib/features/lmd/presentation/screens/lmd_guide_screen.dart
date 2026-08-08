import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../data/lmd_knowledge.dart';

class LmdGuideScreen extends StatelessWidget {
  const LmdGuideScreen({super.key});

  IconData _icon(String name) => switch (name) {
        'flag' => Icons.flag_outlined,
        'layers' => Icons.layers_outlined,
        'calendar' => Icons.calendar_view_month_outlined,
        'credit' => Icons.toll_outlined,
        'blocks' => Icons.view_module_outlined,
        'compare' => Icons.compare_arrows_rounded,
        'student' => Icons.person_outline_rounded,
        _ => Icons.school_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

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
              backgroundColor: feed.cardBg.withValues(alpha: 0.94),
              foregroundColor: feed.ink,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: feed.ink),
              ),
              title: Text(
                'Système LMD',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: feed.ink,
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () => context.push('/lmd/assistant'),
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: primary,
                  ),
                  label: Text('Assistant', style: TextStyle(color: primary)),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.list(
                children: [
                  FadeSlideIn(
                    child: LivingHeroBanner(
                      title: 'LMD en RDC',
                      subtitle:
                          'Licence · Maîtrise · Doctorat — guide clair pour '
                          'étudiants congolais, basé sur les textes officiels.',
                      ctaLabel: 'Poser une question',
                      onCta: () => context.push('/lmd/assistant'),
                      trailing: const Icon(
                        Icons.account_balance_rounded,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 60),
                    child: SoftCard(
                      accentBorder: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repères rapides',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: feed.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ChipFact(label: 'Licence 3 ans / 6 sem.'),
                              _ChipFact(label: 'Maîtrise 2 ans / 4 sem.'),
                              _ChipFact(label: '30 crédits / semestre'),
                              _ChipFact(label: '1 crédit = 25 h'),
                              _ChipFact(label: 'Décret 22/39 · 2022'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < LmdKnowledge.sections.length; i++) ...[
                    FadeSlideIn(
                      delay: Duration(milliseconds: 80 + i * 40),
                      child: _SectionCard(
                        section: LmdKnowledge.sections[i],
                        icon: _icon(LmdKnowledge.sections[i].iconName),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SectionTitle('Sources officielles'),
                  const SizedBox(height: 8),
                  for (final s in LmdKnowledge.sources) ...[
                    SoftCard(
                      onTap: s.url.isEmpty
                          ? null
                          : () async {
                              final uri = Uri.tryParse(s.url);
                              if (uri != null) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: feed.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.reference,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: feed.meta,
                                  ),
                                ),
                                if (s.url.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ouvrir le document →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  SoftCard(
                    child: Text(
                      'Ce guide synthétise des textes publics. Pour une décision '
                      'personnelle (équivalence, inscription, diplôme), confirme '
                      'toujours auprès de ton établissement et du MESU.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: feed.meta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.push('/lmd/assistant');
        },
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Assistant LMD'),
      ),
    );
  }
}

class _ChipFact extends StatelessWidget {
  const _ChipFact({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: feed.softTint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: feed.divider),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.icon});

  final LmdSection section;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: feed.softTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: feed.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: TextStyle(
              height: 1.45,
              fontSize: 14,
              color: feed.ink,
            ),
          ),
          if (section.bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final b in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•  ',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(height: 1.35, color: feed.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
