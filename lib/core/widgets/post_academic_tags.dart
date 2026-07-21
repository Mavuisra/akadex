import 'package:flutter/material.dart';

import '../theme/akadex_theme.dart';
import '../../domain/models/models.dart';

/// Préfixes stockés dans `Post.tags` pour le contexte académique de la pub.
abstract final class PostAcademicTags {
  static const univPrefix = 'univ:';
  static const facPrefix = 'fac:';
  static const promoPrefix = 'promo:';

  static String encodeUniversity(String name) => '$univPrefix${name.trim()}';
  static String encodeFaculty(String name) => '$facPrefix${name.trim()}';
  static String encodePromotion(String name) => '$promoPrefix${name.trim()}';

  static String? _value(List<String> tags, String prefix) {
    for (final t in tags) {
      if (t.startsWith(prefix)) {
        final v = t.substring(prefix.length).trim();
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }

  static String? universityOf(CommunityPost post) =>
      _value(post.tags, univPrefix) ??
      (post.authorUniversity.isNotEmpty ? post.authorUniversity : null);

  static String? facultyOf(CommunityPost post) => _value(post.tags, facPrefix);

  static String? promotionOf(CommunityPost post) =>
      _value(post.tags, promoPrefix) ??
      (post.authorPromotion.isNotEmpty ? post.authorPromotion : null);

  static List<({String label, String value})> chipsFor(CommunityPost post) {
    final out = <({String label, String value})>[];
    final u = universityOf(post);
    final f = facultyOf(post);
    final p = promotionOf(post);
    if (u != null) out.add((label: 'Université', value: u));
    if (f != null) out.add((label: 'Faculté', value: f));
    if (p != null) out.add((label: 'Promotion', value: p));
    return out;
  }
}

/// Rangée horizontale scrollable de tags académiques (sous le média).
class PostAcademicTagsRow extends StatelessWidget {
  const PostAcademicTagsRow({super.key, required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final chips = PostAcademicTags.chipsFor(post);
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = chips[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AkadexColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${c.label} · ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AkadexColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: c.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF050505),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}
