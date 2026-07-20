import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  String _tab = 'Tout';
  bool _bioExpanded = false;

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
                const SizedBox(height: 12),
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
                    const AkadexLogo(size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'Connecte-toi pour voir ton profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _FacebookProfileHeader(user: user)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF050505),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatCount(user.followersCount)} followers · '
                        '${formatCount(user.followingCount)} suivi(e)s · '
                        '${formatCount(user.postsCount > 0 ? user.postsCount : user.contributions)} publications',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF65676B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (user.bio.isNotEmpty || user.headline.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          user.bio.isNotEmpty ? user.bio : user.headline,
                          maxLines: _bioExpanded ? null : 3,
                          overflow: _bioExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.35,
                            color: Color(0xFF050505),
                          ),
                        ),
                        if ((user.bio.isNotEmpty ? user.bio : user.headline)
                                .length >
                            90)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _bioExpanded = !_bioExpanded),
                            child: Text(
                              _bioExpanded ? 'Voir moins' : 'Voir plus',
                              style: const TextStyle(
                                color: TimelineTokens.likeActive,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 10),
                      if (user.professionalDomain.isNotEmpty)
                        _InfoLine(
                          icon: Icons.work_outline_rounded,
                          text: user.professionalDomain,
                        ),
                      if (user.university.isNotEmpty)
                        _InfoLine(
                          icon: Icons.school_outlined,
                          text: user.university,
                        ),
                      if (user.department.isNotEmpty || user.level.isNotEmpty)
                        _InfoLine(
                          icon: Icons.account_tree_outlined,
                          text: [
                            if (user.faculty.isNotEmpty) user.faculty,
                            if (user.department.isNotEmpty) user.department,
                            if (user.level.isNotEmpty) user.level,
                            if (user.promotion.isNotEmpty) user.promotion,
                          ].join(' · '),
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _GreyButton(
                              icon: Icons.edit_outlined,
                              label: 'Modifier le profil',
                              onTap: () => context.push('/profile/edit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _BlueButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Message',
                              onTap: () => context.push('/messages'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SquareGreyButton(
                            icon: Icons.more_horiz,
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCED0D4)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.groups_outlined, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Campus',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.usesTeacherShell
                                  ? 'Compte enseignant sur Akadex'
                                  : user.isAlumni
                                      ? 'Alumni · mentorat et partage d’expérience'
                                      : 'Étudiant · partage TP, résumés et examens',
                              style: const TextStyle(
                                color: Color(0xFF65676B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final t in const [
                              'Tout',
                              'Publications',
                              'À propos',
                              'Médias',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t),
                                  selected: _tab == t,
                                  onSelected: (_) => setState(() => _tab = t),
                                  selectedColor: const Color(0xFFE7F3FF),
                                  labelStyle: TextStyle(
                                    color: _tab == t
                                        ? TimelineTokens.likeActive
                                        : const Color(0xFF050505),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  side: BorderSide.none,
                                  showCheckmark: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Color(0xFFCED0D4)),
                      const SizedBox(height: 12),
                      if (_tab == 'À propos' || _tab == 'Tout') ...[
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (user.university.isNotEmpty)
                          _AboutRow(
                            icon: Icons.location_on_outlined,
                            title: 'Étudie à',
                            value: user.university,
                          ),
                        if (user.department.isNotEmpty)
                          _AboutRow(
                            icon: Icons.home_outlined,
                            title: 'Département',
                            value: user.department,
                          ),
                        if (user.email.isNotEmpty)
                          _AboutRow(
                            icon: Icons.alternate_email,
                            title: 'Coordonnées',
                            value: user.email,
                          ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.list(
                  children: [
                    _MenuTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      trailing: const _NotificationsBadge(),
                      onTap: () {},
                    ),
                    if (user.usesStudentShell) ...[
                      _MenuTile(
                        icon: Icons.upload_file_rounded,
                        label: 'Proposer une contribution',
                        onTap: () => context.push('/contribute'),
                      ),
                      _MenuTile(
                        icon: Icons.folder_shared_outlined,
                        label: 'Mes contributions',
                        onTap: () => context.push('/my-contributions'),
                      ),
                      _MenuTile(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Récompenses & roue',
                        onTap: () => context.push('/rewards'),
                      ),
                      _MenuTile(
                        icon: Icons.auto_awesome,
                        label: 'Akadex IA',
                        onTap: () => context.push('/ai'),
                      ),
                      _MenuTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Calendrier',
                        onTap: () => context.push('/calendar'),
                      ),
                    ],
                    if (user.usesTeacherShell) ...[
                      _MenuTile(
                        icon: Icons.cloud_upload_outlined,
                        label: 'Publier une leçon',
                        onTap: () => context.go('/teacher-publish'),
                      ),
                      _MenuTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Agenda universitaire',
                        onTap: () => context.go('/teacher-calendar'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Se déconnecter'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FacebookProfileHeader extends StatelessWidget {
  const _FacebookProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final cover = user.coverUrl;
    final avatar = user.avatarUrl;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AkadexColors.primary,
                image: cover != null && cover.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(cover),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: cover == null || cover.isEmpty
                    ? AkadexColors.brandGradient
                    : null,
              ),
            ),
            Positioned(
              left: 16,
              bottom: -44,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TimelineTokens.likeActive,
                    width: 3.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AkadexColors.primarySoft,
                  backgroundImage: avatar != null && avatar.isNotEmpty
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar == null || avatar.isEmpty
                      ? Text(
                          user.name.isEmpty
                              ? '?'
                              : user.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: AkadexColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              right: 8,
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => context.push('/profile/edit'),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 52),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF65676B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF050505),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF65676B)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Color(0xFF050505)),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(color: Color(0xFF65676B)),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreyButton extends StatelessWidget {
  const _GreyButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E6EB),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlueButton extends StatelessWidget {
  const _BlueButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TimelineTokens.likeActive,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareGreyButton extends StatelessWidget {
  const _SquareGreyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE4E6EB),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AkadexColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _NotificationsBadge extends ConsumerWidget {
  const _NotificationsBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider).valueOrNull ?? const [];
    if (notifs.isEmpty) return const Icon(Icons.chevron_right_rounded);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: TimelineTokens.likeActive,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${notifs.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded),
      ],
    );
  }
}
