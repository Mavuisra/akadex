import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

          return ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
                decoration: const BoxDecoration(
                  color: AkadexColors.primary,
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mon profil',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.push('/profile/edit'),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        backgroundImage: user.avatarUrl != null &&
                                user.avatarUrl!.isNotEmpty
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null ||
                                user.avatarUrl!.isEmpty
                            ? Text(
                                user.name.isEmpty
                                    ? '?'
                                    : user.name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AkadexColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          if (user.department.isNotEmpty) user.department,
                          if (user.level.isNotEmpty) user.level,
                          if (user.university.isNotEmpty) user.university,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      if (user.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.bio,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(
                            value: formatCount(user.contributions),
                            label: 'Contributions',
                          ),
                          _Stat(
                            value: formatCount(user.reputation),
                            label: 'Points',
                          ),
                          _Stat(
                            value: '${user.badges.length}',
                            label: 'Badges',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  children: [
                    SoftCard(
                      child: Row(
                        children: [
                          Icon(
                            user.usesTeacherShell
                                ? Icons.school_rounded
                                : user.isAlumni
                                    ? Icons.workspace_premium_outlined
                                    : Icons.person_outline_rounded,
                            color: AkadexColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.usesTeacherShell
                                  ? 'Compte enseignant'
                                  : user.isAlumni
                                      ? 'Compte alumni'
                                      : 'Compte étudiant',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SoftCard(
                      onTap: () => context.push('/messages'),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: AkadexColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Messages',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _NotificationsCard(),                    if (user.usesStudentShell) ...[
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.push('/contribute'),
                        child: const Row(
                          children: [
                            Icon(Icons.upload_file_rounded,
                                color: AkadexColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Proposer une contribution',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.push('/my-contributions'),
                        child: const Row(
                          children: [
                            Icon(Icons.folder_shared_outlined,
                                color: AkadexColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mes contributions',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.push('/rewards'),
                        child: const Row(
                          children: [
                            Icon(Icons.card_giftcard_rounded,
                                color: AkadexColors.warning),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Récompenses & roue',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.push('/ai'),
                        child: const Row(
                          children: [
                            AkadexLogo(size: 32),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Akadex IA',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.push('/calendar'),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                color: AkadexColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Calendrier',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ],
                    if (user.usesTeacherShell) ...[
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.go('/teacher-publish'),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                color: AkadexColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Publier une leçon',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        onTap: () => context.go('/teacher-calendar'),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                color: AkadexColors.primary),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Agenda universitaire',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ],
                    if (user.badges.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: SectionTitle('Badges'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final b in user.badges) DocTypeTag(b),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NotificationsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return SoftCard(
      child: notifsAsync.when(
        loading: () => const Row(
          children: [
            Icon(Icons.notifications_outlined, color: AkadexColors.primary),
            SizedBox(width: 12),
            Text(
              'Notifications…',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        error: (_, _) => const Row(
          children: [
            Icon(Icons.notifications_outlined, color: AkadexColors.inkMuted),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notifications indisponibles',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        data: (notifs) {
          final unread = notifs.where((n) => !n.isRead).length;
          final latest = notifs.isEmpty ? null : notifs.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AkadexColors.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AkadexColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              if (latest != null) ...[
                const SizedBox(height: 10),
                Text(
                  latest.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  latest.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AkadexColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Aucune notification pour le moment.',
                  style: TextStyle(
                    color: AkadexColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
