import 'package:flutter/material.dart';

import '../../../../core/theme/timeline_tokens.dart';

/// Onglet Communauté — temporairement en maintenance.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return Scaffold(
      backgroundColor: feed.feedBg,
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: feed.cardBg,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Text(
                    'Communauté',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: feed.ink,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        size: 40,
                        color: feed.meta,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'En maintenance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: feed.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cette section est en maintenance.\nReviens bientôt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: feed.meta,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
