import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

class AlumniScreen extends ConsumerStatefulWidget {
  const AlumniScreen({super.key});

  @override
  ConsumerState<AlumniScreen> createState() => _AlumniScreenState();
}

class _AlumniScreenState extends ConsumerState<AlumniScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider('alumni'));
    final auth = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SectionTitle('Espace Alumni'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Text(
                'Conseils, parcours et mentorat des diplômés.',
                style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final e in [
                    (0, 'Pour toi'),
                    (1, 'Conseils'),
                    (2, 'Carrières'),
                    (3, 'TFC / stages'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(e.$2),
                        selected: _tab == e.$1,
                        onSelected: (_) => setState(() => _tab = e.$1),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: postsAsync.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text(apiErrorMessage(e))),
                data: (posts) {
                  final filtered = posts.where((p) {
                    return switch (_tab) {
                      1 => p.kind == 'alumni_advice' || p.kind == 'alumni_path',
                      2 => p.kind == 'alumni_career',
                      3 => p.kind == 'alumni_tfc',
                      _ => true,
                    };
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Aucun contenu alumni.'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AkadexColors.primarySoft,
                                  child: Text(
                                    p.author.isEmpty
                                        ? '?'
                                        : p.author[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AkadexColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.author,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        [
                                          if (p.kindDisplay.isNotEmpty)
                                            p.kindDisplay,
                                          if (p.department.isNotEmpty)
                                            p.department,
                                        ].join(' · '),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AkadexColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (p.authorId.isNotEmpty)
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(communityRepositoryProvider)
                                            .toggleFollowAlumni(p.authorId);
                                        ref.invalidate(postsProvider('alumni'));
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(apiErrorMessage(e)),
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      p.isFollowingAuthor
                                          ? 'Suivi'
                                          : 'Suivre',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.content,
                              style: const TextStyle(height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await ref
                                        .read(communityRepositoryProvider)
                                        .likePost(p.id);
                                    ref.invalidate(postsProvider('alumni'));
                                  },
                                  icon: Icon(
                                    p.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: AkadexColors.danger,
                                  ),
                                ),
                                Text('${p.likes}'),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _askQuestion(context, p),
                                  icon: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                  ),
                                ),
                                Text('${p.comments}'),
                                const Spacer(),
                                IconButton(
                                  onPressed: () async {
                                    await ref
                                        .read(communityRepositoryProvider)
                                        .savePost(p.id);
                                    ref.invalidate(postsProvider('alumni'));
                                  },
                                  icon: Icon(
                                    p.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: AkadexColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: auth.maybeWhen(
        data: (user) {
          if (user == null) return null;
          return FloatingActionButton.extended(
            onPressed: () => context.push('/alumni/publish'),
            icon: const Icon(Icons.edit_outlined),
            label: Text(user.isAlumni ? 'Publier' : 'Poser une question'),
          );
        },
        orElse: () => null,
      ),
    );
  }

  Future<void> _askQuestion(BuildContext context, CommunityPost post) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commenter / poser une question'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Écris ta question…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await ref
          .read(communityRepositoryProvider)
          .commentPost(post.id, ctrl.text.trim());
      ref.invalidate(postsProvider('alumni'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire publié')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    }
  }
}
