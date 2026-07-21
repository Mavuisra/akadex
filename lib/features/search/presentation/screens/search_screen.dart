import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/shimmer_skeletons.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/document_type.dart';
import '../../../../domain/models/models.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  DocumentType? _typeFilter;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ouvre le profil de l’auteur, puis la publication ciblée.
  void _openAuthorPublication({
    required String authorId,
    String? documentId,
    CommunityPost? post,
  }) {
    final id = authorId.trim();
    if (id.isEmpty) {
      if (documentId != null && documentId.isNotEmpty) {
        context.push('/library/document/$documentId');
      } else if (post != null) {
        context.push('/posts/${post.id}', extra: post);
      }
      return;
    }

    final params = <String, String>{
      if (documentId != null && documentId.isNotEmpty) 'doc': documentId,
      if (post != null) 'post': post.id,
    };
    final qs = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    context.push(
      qs.isEmpty ? '/alumni/profile/$id' : '/alumni/profile/$id?$qs',
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(
      documentsProvider(
        DocumentQuery(search: _query, docType: _typeFilter),
      ),
    );
    final postsAsync = ref.watch(timelinePostsProvider(TimelineQuery.empty));

    return Scaffold(
      backgroundColor: TimelineTokens.feedBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Recherche',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SearchField(
              hint: 'Cours, document, auteur…',
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Container(
            color: Colors.white,
            height: TimelineTokens.filterHeight,
            alignment: Alignment.centerLeft,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tous'),
                    selected: _typeFilter == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _typeFilter = null),
                    selectedColor: AkadexColors.primarySoft,
                    labelStyle: TextStyle(
                      color: _typeFilter == null
                          ? AkadexColors.primary
                          : const Color(0xFF050505),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    backgroundColor: TimelineTokens.feedBg,
                    side: BorderSide(
                      color: _typeFilter == null
                          ? AkadexColors.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
                for (final t in [
                  DocumentType.examen,
                  DocumentType.tp,
                  DocumentType.supportCours,
                  DocumentType.livre,
                  DocumentType.video,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(t.label),
                      selected: _typeFilter == t,
                      showCheckmark: _typeFilter == t,
                      checkmarkColor: AkadexColors.primary,
                      onSelected: (_) => setState(() => _typeFilter = t),
                      selectedColor: AkadexColors.primarySoft,
                      labelStyle: TextStyle(
                        color: _typeFilter == t
                            ? AkadexColors.primary
                            : const Color(0xFF050505),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      backgroundColor: TimelineTokens.feedBg,
                      side: BorderSide(
                        color: _typeFilter == t
                            ? AkadexColors.primary
                            : const Color(0xFFCED0D4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: docsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: ListFeedSkeleton(count: 6),
              ),
              error: (e, _) => Center(child: Text(apiErrorMessage(e))),
              data: (docs) {
                final q = _query.trim().toLowerCase();
                final posts = (postsAsync.valueOrNull ?? const <CommunityPost>[])
                    .where((p) {
                  if (q.isEmpty) return false;
                  final hay = [
                    p.title,
                    p.content,
                    p.author,
                    p.department,
                  ].join(' ').toLowerCase();
                  return hay.contains(q);
                }).toList();

                if (docs.isEmpty && posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun résultat.',
                      style: TextStyle(color: AkadexColors.inkMuted),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    if (docs.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      for (final doc in docs)
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.description_outlined,
                                  color: AkadexColors.primary,
                                ),
                                title: Text(
                                  doc.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${doc.type.label} · ${doc.author} · ${formatCount(doc.downloads)}',
                                  style: const TextStyle(
                                    color: TimelineTokens.meta,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _openAuthorPublication(
                                  authorId: doc.authorId,
                                  documentId: doc.id,
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: TimelineTokens.divider,
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (posts.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Publications',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      for (final post in posts)
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.article_outlined,
                                  color: AkadexColors.primary,
                                ),
                                title: Text(
                                  post.title.isNotEmpty
                                      ? post.title
                                      : post.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  post.author,
                                  style: const TextStyle(
                                    color: TimelineTokens.meta,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _openAuthorPublication(
                                  authorId: post.authorId,
                                  post: post,
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: TimelineTokens.divider,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
