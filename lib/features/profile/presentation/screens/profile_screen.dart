import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _menu = [
    (Icons.description_outlined, 'Mes documents'),
    (Icons.favorite_border, 'Mes favoris'),
    (Icons.history_rounded, 'Historique'),
    (Icons.emoji_events_outlined, 'Badges'),
    (Icons.settings_outlined, 'Paramètres'),
    (Icons.help_outline_rounded, 'Aide & support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: AkadexColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aïcha Mbemba',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'L3 Informatique · UNIKIN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: const Row(
                  children: [
                    _ProfileStat(value: '126', label: 'Documents'),
                    _ProfileStat(value: '2.4K', label: 'Points'),
                    _ProfileStat(value: '#15', label: 'Classement'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            child: Column(
              children: [
                SoftCard(
                  onTap: () => context.push('/ai'),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AkadexColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Akadex IA',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AkadexColors.ink,
                          ),
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
                      Icon(Icons.calendar_month_outlined, color: AkadexColors.primary),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Calendrier',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AkadexColors.ink,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ..._menu.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SoftCard(
                      onTap: m.$2 == 'Paramètres'
                          ? () => context.go('/login')
                          : () {},
                      child: Row(
                        children: [
                          Icon(m.$1, color: AkadexColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              m.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AkadexColors.ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AkadexColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AkadexColors.inkMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
