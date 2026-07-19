import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/akadex_theme.dart';
import '../../core/widgets/living_ui.dart';

/// Navigation métier enseignant : Cours, Publier, Calendrier, Profil.
class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.navigationShell});

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
            color: Colors.white.withValues(alpha: 0.96),
            border: const Border(
              top: BorderSide(color: AkadexColors.border, width: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: AkadexColors.primaryDark.withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CupertinoTabBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            activeColor: AkadexColors.primaryDark,
            inactiveColor: AkadexColors.inkSoft,
            backgroundColor: Colors.transparent,
            border: Border.all(color: Colors.transparent),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_list),
                activeIcon: Icon(CupertinoIcons.square_list_fill),
                label: 'Mes cours',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.cloud_upload),
                activeIcon: Icon(CupertinoIcons.cloud_upload_fill),
                label: 'Publier',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar),
                activeIcon: Icon(CupertinoIcons.calendar_today),
                label: 'Agenda',
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
