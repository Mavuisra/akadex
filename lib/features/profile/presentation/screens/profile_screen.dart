import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../domain/models/models.dart';

/// Menu style Facebook — premier écran de l’onglet Profil.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showMore = false;
  bool _helpOpen = false;
  bool _settingsOpen = false;
  bool _themeOpen = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final feed = TimelineTokens.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: feed.feedBg,
      body: auth.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(apiErrorMessage(e), textAlign: TextAlign.center),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AkadexLogo(size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Connecte-toi pour ouvrir ton menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: feed.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _MenuHeader(
                  user: user,
                  ink: feed.ink,
                  softTint: feed.softTint,
                  chipBg: feed.commentBubble,
                  primary: primary,
                  onOpenProfile: () => context.push('/profile/me'),
                  onSettings: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 12),
                _MenuItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Ami(e)s',
                  ink: feed.ink,
                  onTap: () => context.go('/community'),
                ),
                _MenuItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tableau de bord',
                  ink: feed.ink,
                  onTap: () => context.go('/home'),
                ),
                _MenuItem(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Enregistrements',
                  ink: feed.ink,
                  onTap: () => context.push('/my-contributions'),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome,
                  label: 'Akadex IA',
                  ink: feed.ink,
                  onTap: () => context.push('/ai'),
                ),
                if (user.usesStudentShell)
                  _MenuItem(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Récompenses',
                    ink: feed.ink,
                    onTap: () => context.push('/rewards'),
                  ),
                if (_showMore) ...[
                  _MenuItem(
                    icon: Icons.upload_file_rounded,
                    label: 'Proposer une contribution',
                    ink: feed.ink,
                    onTap: () => context.push('/contribute'),
                  ),
                  _MenuItem(
                    icon: Icons.explore_outlined,
                    label: 'Apprendre',
                    ink: feed.ink,
                    onTap: () => context.go('/learn'),
                  ),
                  if (user.usesTeacherShell)
                    _MenuItem(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Publier une leçon',
                      ink: feed.ink,
                      onTap: () => context.go('/teacher-publish'),
                    ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: feed.commentBubble,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _showMore = !_showMore),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _showMore ? 'Voir moins' : 'Voir plus',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: feed.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: feed.divider),
                _ExpandRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Aide et assistance',
                  ink: feed.ink,
                  open: _helpOpen,
                  onTap: () => setState(() => _helpOpen = !_helpOpen),
                  children: [
                    _SubItem(
                      label: 'Centre d’aide',
                      meta: feed.meta,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Centre d’aide bientôt disponible'),
                          ),
                        );
                      },
                    ),
                    _SubItem(
                      label: 'Signaler un problème',
                      meta: feed.meta,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Merci — bientôt disponible'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Divider(height: 1, color: feed.divider),
                _ExpandRow(
                  icon: Icons.palette_outlined,
                  label: 'Thème',
                  ink: feed.ink,
                  open: _themeOpen,
                  onTap: () => setState(() => _themeOpen = !_themeOpen),
                  children: [
                    _ThemeChoice(
                      label: 'Clair',
                      subtitle: 'Look d’origine',
                      selected: themeMode == ThemeMode.light,
                      meta: feed.meta,
                      ink: feed.ink,
                      primary: primary,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setMode(ThemeMode.light),
                    ),
                    _ThemeChoice(
                      label: 'Sombre',
                      subtitle: 'Noir · cartes charcoal',
                      selected: themeMode == ThemeMode.dark,
                      meta: feed.meta,
                      ink: feed.ink,
                      primary: primary,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setMode(ThemeMode.dark),
                    ),
                  ],
                ),
                Divider(height: 1, color: feed.divider),
                _ExpandRow(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres et confidentialité',
                  ink: feed.ink,
                  open: _settingsOpen,
                  onTap: () => setState(() => _settingsOpen = !_settingsOpen),
                  children: [
                    _SubItem(
                      label: 'Modifier le profil',
                      meta: feed.meta,
                      onTap: () => context.push('/profile/edit'),
                    ),
                    _SubItem(
                      label: 'Confidentialité',
                      meta: feed.meta,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paramètres bientôt disponibles'),
                          ),
                        );
                      },
                    ),
                    _SubItem(
                      label: 'Se déconnecter',
                      meta: feed.meta,
                      onTap: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
                Divider(height: 1, color: feed.divider),
                const SizedBox(height: 16),
                Text(
                  'Akadex · campus numérique',
                  style: TextStyle(
                    color: feed.meta,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.user,
    required this.ink,
    required this.softTint,
    required this.chipBg,
    required this.primary,
    required this.onOpenProfile,
    required this.onSettings,
  });

  final UserProfile user;
  final Color ink;
  final Color softTint;
  final Color chipBg;
  final Color primary;
  final VoidCallback onOpenProfile;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final avatar = user.avatarUrl;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: softTint,
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: avatar != null && avatar.isNotEmpty
                        ? null
                        : Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name.characters.first.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: chipBg,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onSettings,
            icon: Icon(Icons.settings_outlined, color: ink),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: chipBg,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onOpenProfile,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: ink),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 28, color: ink),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ExpandRow extends StatelessWidget {
  const _ExpandRow({
    required this.icon,
    required this.label,
    required this.ink,
    required this.open,
    required this.onTap,
    required this.children,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final bool open;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 26, color: ink),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ink,
            ),
          ),
          trailing: Icon(
            open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: ink,
          ),
          onTap: onTap,
        ),
        if (open) ...children,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.label,
    required this.meta,
    required this.onTap,
  });

  final String label;
  final Color meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 8),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: meta,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.meta,
    required this.ink,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final Color meta;
  final Color ink;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 8),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: meta),
      ),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? primary : meta,
      ),
      onTap: onTap,
    );
  }
}
