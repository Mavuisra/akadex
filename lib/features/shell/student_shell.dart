import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/akadex_theme.dart';
import '../../core/widgets/living_ui.dart';

/// Navigation campus : Accueil, Explorer, Bibliothèque, Communauté, Alumni, Profil.
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
    return PageAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            border: const Border(
              top: BorderSide(color: AkadexColors.border, width: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: AkadexColors.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            activeColor: AkadexColors.primary,
            inactiveColor: AkadexColors.inkSoft,
            backgroundColor: Colors.transparent,
            border: Border.all(color: Colors.transparent),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.compass),
                activeIcon: Icon(CupertinoIcons.compass_fill),
                label: 'Explorer',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.book),
                activeIcon: Icon(CupertinoIcons.book_fill),
                label: 'Bibliothèque',
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
