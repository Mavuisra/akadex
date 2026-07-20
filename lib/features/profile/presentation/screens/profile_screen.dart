import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
                    const Text(
                      'Connecte-toi pour ouvrir ton menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
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
                  onOpenProfile: () => context.push('/profile/me'),
                  onSettings: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vos raccourcis',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF050505),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _ShortcutTile(
                        label: 'Communauté',
                        icon: Icons.forum_outlined,
                        color: const Color(0xFF1877F2),
                        onTap: () => context.go('/community'),
                      ),
                      _ShortcutTile(
                        label: 'Bibliothèque',
                        icon: Icons.menu_book_outlined,
                        color: const Color(0xFF42B72A),
                        onTap: () => context.go('/library'),
                      ),
                      _ShortcutTile(
                        label: 'Alumni',
                        icon: Icons.school_outlined,
                        color: const Color(0xFFF7B928),
                        onTap: () => context.go('/alumni'),
                      ),
                      _ShortcutTile(
                        label: 'Messages',
                        icon: Icons.chat_bubble_outline,
                        color: const Color(0xFF8A3FFC),
                        onTap: () => context.push('/messages'),
                      ),
                      _ShortcutTile(
                        label: 'Calendrier',
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFFFA383E),
                        onTap: () => context.push('/calendar'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.people_outline_rounded,
                  label: 'Ami(e)s',
                  onTap: () => context.go('/community'),
                ),
                _MenuItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Tableau de bord',
                  onTap: () => context.go('/home'),
                ),
                _MenuItem(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Enregistrements',
                  onTap: () => context.push('/my-contributions'),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome,
                  label: 'Akadex IA',
                  onTap: () => context.push('/ai'),
                ),
                if (user.usesStudentShell)
                  _MenuItem(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Récompenses',
                    onTap: () => context.push('/rewards'),
                  ),
                if (_showMore) ...[
                  _MenuItem(
                    icon: Icons.upload_file_rounded,
                    label: 'Proposer une contribution',
                    onTap: () => context.push('/contribute'),
                  ),
                  _MenuItem(
                    icon: Icons.explore_outlined,
                    label: 'Apprendre',
                    onTap: () => context.go('/learn'),
                  ),
                  if (user.usesTeacherShell)
                    _MenuItem(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Publier une leçon',
                      onTap: () => context.go('/teacher-publish'),
                    ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: const Color(0xFFE4E6EB),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => setState(() => _showMore = !_showMore),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _showMore ? 'Voir moins' : 'Voir plus',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFCED0D4)),
                _ExpandRow(
                  icon: Icons.help_outline_rounded,
                  label: 'Aide et assistance',
                  open: _helpOpen,
                  onTap: () => setState(() => _helpOpen = !_helpOpen),
                  children: [
                    _SubItem(
                      label: 'Centre d’aide',
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
                const Divider(height: 1, color: Color(0xFFCED0D4)),
                _ExpandRow(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres et confidentialité',
                  open: _settingsOpen,
                  onTap: () => setState(() => _settingsOpen = !_settingsOpen),
                  children: [
                    _SubItem(
                      label: 'Modifier le profil',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    _SubItem(
                      label: 'Confidentialité',
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
                      onTap: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFCED0D4)),
                const SizedBox(height: 16),
                Text(
                  'Akadex · campus numérique',
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
    required this.onOpenProfile,
    required this.onSettings,
  });

  final UserProfile user;
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
                    backgroundColor: AkadexColors.primarySoft,
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? CachedNetworkImageProvider(avatar)
                        : null,
                    child: avatar != null && avatar.isNotEmpty
                        ? null
                        : Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AkadexColors.primary,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF050505),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: const Color(0xFFE4E6EB),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: const Color(0xFFE4E6EB),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onOpenProfile,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 78,
          child: Column(
            children: [
              Container(
                height: 64,
                width: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E6EB)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
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
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 28, color: const Color(0xFF050505)),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF050505),
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
    required this.open,
    required this.onTap,
    required this.children,
  });

  final IconData icon;
  final String label;
  final bool open;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 26, color: const Color(0xFF050505)),
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: Icon(
            open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
          ),
          onTap: onTap,
        ),
        if (open) ...children,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  const _SubItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 8),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF050505),
        ),
      ),
      onTap: onTap,
    );
  }
}
