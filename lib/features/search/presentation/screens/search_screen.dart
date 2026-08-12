import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Color primary,
    required Color ink,
    required Color cardBg,
    required Color softTint,
    required Color divider,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: selected,
        checkmarkColor: primary,
        onSelected: (_) => onTap(),
        selectedColor: softTint,
        labelStyle: TextStyle(
          color: selected ? primary : ink,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        backgroundColor: cardBg,
        side: TimelineTokens.tabBorderSide,
      ),
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
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: feed.ink,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Recherche',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: feed.cardBg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: SearchField(
              hint: 'Cours, document, auteur…',
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Container(
            color: feed.cardBg,
            height: TimelineTokens.filterHeight,
            alignment: Alignment.centerLeft,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _typeChip(
                  label: 'Tous',
                  selected: _typeFilter == null,
                  onTap: () => setState(() => _typeFilter = null),
                  primary: primary,
                  ink: feed.ink,
                  cardBg: feed.feedBg,
                  softTint: feed.softTint,
                  divider: feed.divider,
                ),
                for (final t in [
                  DocumentType.examen,
                  DocumentType.tp,
                  DocumentType.supportCours,
                  DocumentType.livre,
                  DocumentType.video,
                ])
                  _typeChip(
                    label: t.label,
                    selected: _typeFilter == t,
                    onTap: () => setState(() => _typeFilter = t),
                    primary: primary,
                    ink: feed.ink,
                    cardBg: feed.feedBg,
                    softTint: feed.softTint,
                    divider: feed.divider,
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: feed.divider),
          Expanded(
            child: docsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: ListFeedSkeleton(count: 6),
              ),
              error: (e, _) => Center(
                child: Text(
                  apiErrorMessage(e),
                  style: TextStyle(color: feed.ink),
                ),
              ),
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
                  return Center(
                    child: Text(
                      'Aucun résultat.',
                      style: TextStyle(color: feed.meta),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    if (docs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          'Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: feed.ink,
                          ),
                        ),
                      ),
                      for (final doc in docs)
                        Container(
                          color: feed.cardBg,
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.description_outlined,
                                  color: primary,
                                ),
                                title: Text(
                                  doc.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: feed.ink,
                                  ),
                                ),
                                subtitle: Text(
                                  '${doc.type.label} · ${doc.author} · ${formatCount(doc.downloads)}',
                                  style: TextStyle(
                                    color: feed.meta,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _openAuthorPublication(
                                  authorId: doc.authorId,
                                  documentId: doc.id,
                                ),
                              ),
                              Divider(height: 1, color: feed.divider),
                            ],
                          ),
                        ),
                    ],
                    if (posts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Publications',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: feed.ink,
                          ),
                        ),
                      ),
                      for (final post in posts)
                        Container(
                          color: feed.cardBg,
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(
                                  Icons.article_outlined,
                                  color: primary,
                                ),
                                title: Text(
                                  post.title.isNotEmpty
                                      ? post.title
                                      : post.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: feed.ink,
                                  ),
                                ),
                                subtitle: Text(
                                  post.author,
                                  style: TextStyle(
                                    color: feed.meta,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () => _openAuthorPublication(
                                  authorId: post.authorId,
                                  post: post,
                                ),
                              ),
                              Divider(height: 1, color: feed.divider),
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
