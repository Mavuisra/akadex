import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Navigation enseignant — style Facebook (barre blanche, bleu actif).
class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _fbBlue = Color(0xFF0866FF);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _fbBorder, width: 0.6),
          ),
        ),
        child: CupertinoTabBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          activeColor: _fbBlue,
          inactiveColor: _fbMuted,
          backgroundColor: Colors.transparent,
          border: Border.all(color: Colors.transparent),
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
