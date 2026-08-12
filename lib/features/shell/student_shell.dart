import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/akadex_theme.dart';
import '../../core/theme/timeline_tokens.dart';
import '../../core/widgets/living_ui.dart';

/// Navigation campus verrouillée pour tous :
/// Accueil · Apprendre · Ma Fac · Communauté · Alumni · Profil
class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: feed.cardBg.withValues(alpha: isDark ? 0.96 : 0.94),
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? AkadexColors.primaryOnDark
                        : AkadexColors.primary)
                    .withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            activeColor: isDark
                ? AkadexColors.primaryOnDark
                : AkadexColors.primary,
            inactiveColor: isDark ? feed.meta : AkadexColors.inkSoft,
            backgroundColor: Colors.transparent,
            border: TimelineTokens.tabBorder,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.play_rectangle),
                activeIcon: Icon(CupertinoIcons.play_rectangle_fill),
                label: 'Apprendre',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_outlined),
                activeIcon: Icon(Icons.account_balance),
                label: 'Ma Fac',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble_2),
                activeIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
                label: 'Communauté',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person_2),
                activeIcon: Icon(CupertinoIcons.person_2_fill),
                label: 'Alumni',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                activeIcon: Icon(CupertinoIcons.person_fill),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
