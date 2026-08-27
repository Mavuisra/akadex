import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/onboarding/student_feature_tour.dart';
import '../../core/theme/akadex_theme.dart';
import '../../core/theme/timeline_tokens.dart';
import '../../core/widgets/feature_tour_overlay.dart';
import '../../core/widgets/living_ui.dart';
import '../../core/widgets/offline_status_banner.dart';
import '../../data/api/api_client.dart';

/// Navigation campus — cœur métier uniquement :
/// Accueil · Apprendre · Ma Fac · Profil
class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  final GlobalKey _navBarKey = GlobalKey();
  OverlayEntry? _tourEntry;
  bool _tourScheduled = false;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartTour());
  }

  @override
  void dispose() {
    _removeTour();
    super.dispose();
  }

  Future<void> _maybeStartTour() async {
    if (_tourScheduled || !mounted) return;
    _tourScheduled = true;

    SharedPreferences prefs;
    try {
      prefs = ref.read(sharedPreferencesProvider);
    } catch (_) {
      return;
    }

    if (StudentFeatureTour.isDone(prefs)) return;

    // Laisse la barre se poser avant le spotlight.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || StudentFeatureTour.isDone(prefs)) return;

    _showTour();
  }

  void _showTour() {
    _removeTour();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _tourEntry = OverlayEntry(
      builder: (context) => FeatureTourOverlay(
        steps: StudentFeatureTour.steps,
        targetRectFor: _tabRect,
        onStepChanged: (tabIndex) {
          if (!mounted) return;
          if (tabIndex != navigationShell.currentIndex) {
            navigationShell.goBranch(tabIndex);
          }
          _tourEntry?.markNeedsBuild();
        },
        onFinished: _finishTour,
      ),
    );
    overlay.insert(_tourEntry!);
  }

  Rect? _tabRect(int tabIndex) {
    final ctx = _navBarKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final origin = box.localToGlobal(Offset.zero);
    final tabW = box.size.width / StudentFeatureTour.steps.length;
    // Zone utile des icônes (hors home indicator).
    final padBottom = MediaQuery.paddingOf(ctx).bottom;
    final contentH = (box.size.height - padBottom).clamp(44.0, 64.0);
    return Rect.fromLTWH(
      origin.dx + tabIndex * tabW,
      origin.dy,
      tabW,
      contentH,
    );
  }

  Future<void> _finishTour() async {
    _removeTour();
    try {
      await StudentFeatureTour.markDone(ref.read(sharedPreferencesProvider));
    } catch (_) {}
  }

  void _removeTour() {
    _tourEntry?.remove();
    _tourEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PageAtmosphere(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const OfflineStatusBanner(),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: Container(
          key: _navBarKey,
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
