import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/akadex_theme.dart';
import '../../core/theme/timeline_tokens.dart';

/// Navigation enseignant — style Facebook (barre blanche, bleu actif).
class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _fbBlue = Color(0xFF0866FF);
  static const _fbMuted = Color(0xFF65676B);

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feed = TimelineTokens.of(context);

    return Scaffold(
      backgroundColor: feed.feedBg,
      body: navigationShell,
      bottomNavigationBar: Container(
        color: feed.cardBg,
        child: CupertinoTabBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          activeColor: isDark ? AkadexColors.primaryOnDark : _fbBlue,
          inactiveColor: isDark ? feed.meta : _fbMuted,
          backgroundColor: Colors.transparent,
          border: TimelineTokens.tabBorder,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.square_list),
              activeIcon: Icon(CupertinoIcons.square_list_fill),
              label: 'Mes cours',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.plus_app),
              activeIcon: Icon(CupertinoIcons.plus_app_fill),
              label: 'Publier',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chart_bar),
              activeIcon: Icon(CupertinoIcons.chart_bar_alt_fill),
              label: 'Tableau',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              activeIcon: Icon(CupertinoIcons.person_fill),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
