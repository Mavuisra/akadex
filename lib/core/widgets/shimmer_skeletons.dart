import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/akadex_theme.dart';

/// Os gris pour composer un squelette de chargement.
class SkeletonBone extends StatelessWidget {
  const SkeletonBone({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AkadexShimmer extends StatelessWidget {
  const AkadexShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE4E8F0),
      highlightColor: const Color(0xFFF7F8FB),
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Carte publication (avatar + lignes + actions) — comme le feed communauté.
class PostSkeletonCard extends StatelessWidget {
  const PostSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AkadexColors.surface,
        border: Border(bottom: BorderSide(color: AkadexColors.border)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBone(width: 40, height: 40, radius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBone(width: 120, height: 12),
                    SizedBox(height: 8),
                    SkeletonBone(width: 80, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBone(width: double.infinity, height: 11),
          SizedBox(height: 8),
          SkeletonBone(width: double.infinity, height: 11),
          SizedBox(height: 8),
          SkeletonBone(width: 180, height: 11),
          SizedBox(height: 16),
          Row(
            children: [
              SkeletonBone(width: 22, height: 22, radius: 11),
              SizedBox(width: 14),
              SkeletonBone(width: 22, height: 22, radius: 11),
              SizedBox(width: 14),
              SkeletonBone(width: 22, height: 22, radius: 11),
              Spacer(),
              SkeletonBone(width: 56, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liste de publications en chargement.
class PostFeedSkeleton extends StatelessWidget {
  const PostFeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AkadexShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) const PostSkeletonCard(),
        ],
      ),
    );
  }
}

/// Ligne type document / cours / université.
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AkadexColors.surface,
        border: Border(bottom: BorderSide(color: AkadexColors.border)),
      ),
      child: const Row(
        children: [
          SkeletonBone(width: 48, height: 48, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: double.infinity, height: 12),
                SizedBox(height: 8),
                SkeletonBone(width: 140, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListFeedSkeleton extends StatelessWidget {
  const ListFeedSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AkadexShimmer(
      child: Column(
        children: [
          for (var i = 0; i < count; i++) const ListRowSkeleton(),
        ],
      ),
    );
  }
}

/// Conversation (avatar rond + 2 lignes).
class ConversationRowSkeleton extends StatelessWidget {
  const ConversationRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          SkeletonBone(width: 52, height: 52, radius: 26),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBone(width: 150, height: 12),
                SizedBox(height: 10),
                SkeletonBone(width: double.infinity, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationListSkeleton extends StatelessWidget {
  const ConversationListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AkadexShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        itemBuilder: (_, _) => const ConversationRowSkeleton(),
      ),
    );
  }
}

/// Écran Apprendre en chargement (header recherche + cartes shimmer).
class LearnScreenSkeleton extends StatelessWidget {
  const LearnScreenSkeleton({super.key, this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header type feed : avatar · recherche · chat
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  const SkeletonBone(width: 40, height: 40, radius: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: Color(0xFF8A8D91),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recherche',
                            style: TextStyle(
                              color: Color(0xFF8A8D91),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: null,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Stories domaines (horizontal)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: AkadexShimmer(
                child: SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, _) => const SkeletonBone(
                      width: 96,
                      height: 108,
                      radius: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: const AkadexShimmer(
                      child: SkeletonBone(width: 160, height: 18, radius: 6),
                    ),
                  ),
                  for (var i = 0; i < cardCount; i++)
                    const _LearnCourseCardSkeleton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnCourseCardSkeleton extends StatelessWidget {
  const _LearnCourseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: const AkadexShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBone(width: 40, height: 40, radius: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBone(width: 140, height: 12),
                      SizedBox(height: 8),
                      SkeletonBone(width: 100, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            SkeletonBone(width: double.infinity, height: 12),
            SizedBox(height: 8),
            SkeletonBone(width: double.infinity, height: 12),
            SizedBox(height: 8),
            SkeletonBone(width: 200, height: 12),
            SizedBox(height: 16),
            Row(
              children: [
                SkeletonBone(width: 22, height: 22, radius: 11),
                SizedBox(width: 14),
                SkeletonBone(width: 22, height: 22, radius: 11),
                SizedBox(width: 14),
                SkeletonBone(width: 22, height: 22, radius: 11),
                Spacer(),
                SkeletonBone(width: 56, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

