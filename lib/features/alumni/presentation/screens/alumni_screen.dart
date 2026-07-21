import 'package:flutter/material.dart';

import '../../../../core/theme/timeline_tokens.dart';

/// Onglet Alumni — temporairement en maintenance.
class AlumniScreen extends StatelessWidget {
  const AlumniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: TimelineTokens.feedBg,
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Text(
                    'Alumni',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF050505),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        size: 40,
                        color: TimelineTokens.meta,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'En maintenance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF050505),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cette section est en maintenance.\nReviens bientôt.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TimelineTokens.meta,
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
