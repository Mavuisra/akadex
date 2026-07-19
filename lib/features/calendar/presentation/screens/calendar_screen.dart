import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  IconData _iconFor(String type) => switch (type) {
        'examen' => Icons.assignment_outlined,
        'deadline' => Icons.flag_outlined,
        'deliberation' => Icons.how_to_vote_outlined,
        'evenement' => Icons.celebration_outlined,
        'cours' => Icons.school_outlined,
        _ => Icons.event_outlined,
      };

  Color _colorFor(String type) => switch (type) {
        'examen' => const Color(0xFFE53935),
        'deadline' => const Color(0xFFFB8C00),
        'deliberation' => const Color(0xFF8E24AA),
        'evenement' => const Color(0xFF1A47B8),
        _ => AkadexColors.primary,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final dateFmt = DateFormat('EEE d MMM', 'fr_FR');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        title: const Text('Calendrier'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(eventsProvider),
        child: eventsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: SoftCard(
                  child: Column(
                    children: [
                      Text(apiErrorMessage(e), textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () => ref.invalidate(eventsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucun événement à venir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AkadexColors.inkMuted),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final e = events[i];
                final color = _colorFor(e.eventType);
                return SoftCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_iconFor(e.eventType), color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AkadexColors.ink,
                              ),
                            ),
                            Text(
                              '${dateFmt.format(e.startsAt.toLocal())} · ${timeFmt.format(e.startsAt.toLocal())}'
                              '${e.location.isNotEmpty ? ' · ${e.location}' : ''}',
                              style: const TextStyle(
                                color: AkadexColors.inkMuted,
                                fontSize: 13,
                              ),
                            ),
                            if (e.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  e.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AkadexColors.inkMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
