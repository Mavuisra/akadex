import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return Scaffold(
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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mon profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white,
                        child: Text(
                          user.name.isEmpty
                              ? '?'
                              : user.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AkadexColors.primary,
                          ),
                        ),
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
                      onTap: () => context.push('/professor'),
                      child: const Row(
                        children: [
                          Icon(Icons.school_outlined,
                              color: AkadexColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Espace Professeurs',
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
