import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/akadex_theme.dart';
import '../../core/theme/timeline_tokens.dart';
import '../../data/auth/auth_repository.dart';
import '../../domain/models/models.dart';

/// Shell étudiant type LinkedIn — web grand écran uniquement.
class DesktopStudentShell extends ConsumerWidget {
  const DesktopStudentShell({
    super.key,
    required this.navigationShell,
    required this.onTap,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  static const double _maxContent = 1128;
  static const double _leftW = 225;
  static const double _rightW = 300;
  static const double _gap = 16;
  static const double _topH = 52;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull;
    final index = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: TimelineTokens.feedBg,
      body: Column(
        children: [
          _DesktopTopBar(
            height: _topH,
            currentIndex: index,
            user: me,
            onNav: onTap,
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContent),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: _leftW,
                        child: _LeftSidebar(user: me, onNav: onTap),
                      ),
                      const SizedBox(width: _gap),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: navigationShell,
                        ),
                      ),
                      const SizedBox(width: _gap),
                      SizedBox(
                        width: _rightW,
                        child: const _RightSidebar(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.height,
    required this.currentIndex,
    required this.user,
    required this.onNav,
  });

  final double height;
  final int currentIndex;
  final UserProfile? user;
  final ValueChanged<int> onNav;

  static const _items = <(IconData, IconData, String)>[
    (CupertinoIcons.house, CupertinoIcons.house_fill, 'Accueil'),
    (CupertinoIcons.play_rectangle, CupertinoIcons.play_rectangle_fill, 'Apprendre'),
    (Icons.account_balance_outlined, Icons.account_balance, 'Ma Fac'),
    (CupertinoIcons.chat_bubble_2, CupertinoIcons.chat_bubble_2_fill, 'Communauté'),
    (CupertinoIcons.person_2, CupertinoIcons.person_2_fill, 'Alumni'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: TimelineTokens.divider, width: 0.6),
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1128),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Image.asset(
                    AppConstants.logoAsset,
                    width: 34,
                    height: 34,
                    errorBuilder: (_, _, _) => const CircleAvatar(
                      radius: 17,
                      backgroundColor: AkadexColors.primary,
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 240,
                    height: 34,
                    child: Material(
                      color: TimelineTokens.feedBg,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        onTap: () => context.push('/search'),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: TimelineTokens.meta,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Rechercher',
                                  style: TextStyle(
                                    color: TimelineTokens.meta,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  for (var i = 0; i < _items.length; i++)
                    _TopNavItem(
                      icon: _items[i].$1,
                      activeIcon: _items[i].$2,
                      label: _items[i].$3,
                      selected: currentIndex == i,
                      onTap: () => onNav(i),
                    ),
                  _TopNavItem(
                    icon: CupertinoIcons.person,
                    activeIcon: CupertinoIcons.person_fill,
                    label: 'Moi',
                    selected: currentIndex == 5,
                    onTap: () => onNav(5),
                    avatarUrl: user?.avatarUrl,
                    avatarLetter: user?.name,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => context.push('/calendar'),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: TimelineTokens.meta,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Messages',
                    onPressed: () => context.push('/messages'),
                    icon: const Icon(
                      Icons.messenger_outline_rounded,
                      size: 20,
                      color: TimelineTokens.meta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  const _TopNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.avatarUrl,
    this.avatarLetter,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? avatarLetter;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AkadexColors.primary : TimelineTokens.meta;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AkadexColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (avatarUrl != null || avatarLetter != null)
              CircleAvatar(
                radius: 12,
                backgroundColor: AkadexColors.primarySoft,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl!)
                    : null,
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? null
                    : Text(
                        (avatarLetter == null || avatarLetter!.isEmpty)
                            ? '?'
                            : avatarLetter!.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.primary,
                        ),
                      ),
              )
            else
              Icon(selected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftSidebar extends StatelessWidget {
  const _LeftSidebar({required this.user, required this.onNav});

  final UserProfile? user;
  final ValueChanged<int> onNav;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Étudiant';
    final headline = () {
      final h = user?.headline.trim() ?? '';
      if (h.isNotEmpty) return h;
      final parts = [
        if ((user?.faculty ?? '').trim().isNotEmpty) user!.faculty.trim(),
        if ((user?.level ?? '').trim().isNotEmpty) user!.level.trim(),
      ];
      return parts.isEmpty ? 'Ton campus numérique' : parts.join(' · ');
    }();
    final avatar = user?.avatarUrl;
    final cover = user?.coverUrl;

    return SingleChildScrollView(
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onNav(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: cover != null && cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _coverFallback(),
                          )
                        : _coverFallback(),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: AkadexColors.primarySoft,
                            backgroundImage:
                                avatar != null && avatar.isNotEmpty
                                    ? CachedNetworkImageProvider(avatar)
                                    : null,
                            child: avatar != null && avatar.isNotEmpty
                                ? null
                                : Text(
                                    name.isEmpty
                                        ? '?'
                                        : name.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AkadexColors.primary,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AkadexColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                          child: Text(
                            headline,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TimelineTokens.meta,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                _SideLink(
                  icon: Icons.account_balance_outlined,
                  label: 'Ma Fac',
                  onTap: () => onNav(2),
                ),
                _SideLink(
                  icon: CupertinoIcons.play_rectangle,
                  label: 'Apprendre',
                  onTap: () => onNav(1),
                ),
                _SideLink(
                  icon: CupertinoIcons.chat_bubble_2,
                  label: 'Communauté',
                  onTap: () => onNav(3),
                ),
                _SideLink(
                  icon: CupertinoIcons.person_2,
                  label: 'Alumni',
                  onTap: () => onNav(4),
                ),
                _SideLink(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Ressources sauvées',
                  onTap: () => context.push('/profile/me'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: const BoxDecoration(gradient: AkadexColors.brandGradient),
    );
  }
}

class _SideLink extends StatelessWidget {
  const _SideLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: TimelineTokens.meta),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AkadexColors.ink,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RightSidebar extends StatelessWidget {
  const _RightSidebar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sur Akadex',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TipRow(
                    icon: Icons.description_outlined,
                    title: 'Partage un TP ou un résumé',
                    subtitle: 'Aide ta promo et gagne en visibilité.',
                    onTap: () => context.push('/community/publish'),
                  ),
                  const Divider(height: 20),
                  _TipRow(
                    icon: Icons.school_outlined,
                    title: 'Explore Ma Fac',
                    subtitle: 'Docs, examens et ressources de ta filière.',
                    onTap: () => context.go('/library'),
                  ),
                  const Divider(height: 20),
                  _TipRow(
                    icon: Icons.play_circle_outline,
                    title: 'Cours & leçons',
                    subtitle: 'Continue là où tu t’es arrêté.',
                    onTap: () => context.go('/learn'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'À propos · Confidentialité · Conditions · Aide\n'
              'Akadex © ${DateTime.now().year}',
              style: const TextStyle(
                fontSize: 11,
                color: TimelineTokens.meta,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AkadexColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TimelineTokens.meta,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
