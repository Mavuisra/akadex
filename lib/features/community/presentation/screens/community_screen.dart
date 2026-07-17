import 'package:flutter/material.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/mocks/mock_data.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _tab = 'Pour toi';
  static const _tabs = ['Pour toi', 'Questions', 'Discussions', 'Sujets'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Communauté',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilterChipBar(
              items: _tabs,
              selected: _tab,
              onSelected: (v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 16),
            ...MockData.posts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SoftCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AkadexColors.primarySoft,
                            child: Text(
                              p.author.characters.first,
                              style: const TextStyle(
                                color: AkadexColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.author,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AkadexColors.ink,
                                  ),
                                ),
                                Text(
                                  p.time,
                                  style: const TextStyle(
                                    color: AkadexColors.inkMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p.body,
                        style: const TextStyle(
                          color: AkadexColors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: p.tags.map((t) => DocTypeTag(t)).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: AkadexColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.likes,
                            style: const TextStyle(color: AkadexColors.inkMuted),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: AkadexColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.comments,
                            style: const TextStyle(color: AkadexColors.inkMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
