import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../data/cart_provider.dart';
import '../../data/course_pricing.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: feed.ink,
        title: Text(
          'Panier',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 56, color: feed.meta),
                    const SizedBox(height: 16),
                    Text(
                      'Votre panier est vide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: feed.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez un cours depuis Apprendre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: feed.meta),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.go('/learn'),
                      child: const Text('Voir les cours'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final cover = item.coverUrl;
                      return Material(
                        color: feed.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              context.push('/library/course/${item.courseId}'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: feed.divider),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: cover,
                                    width: 96,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => Container(
                                      width: 96,
                                      height: 64,
                                      color: feed.softTint,
                                      child: Icon(Icons.school_outlined,
                                          color: feed.meta),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: feed.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.teacher,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: feed.meta,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        CoursePricing.format(item.priceUsd),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: feed.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Retirer',
                                  onPressed: () => cart.remove(item.courseId),
                                  icon: Icon(Icons.delete_outline_rounded,
                                      color: feed.meta),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    14 + MediaQuery.paddingOf(context).bottom,
                  ),
                  decoration: BoxDecoration(
                    color: feed.cardBg,
                    border: Border(
                      top: BorderSide(color: feed.divider),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Total (${items.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: feed.meta,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            CoursePricing.format(cart.totalUsd),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: feed.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: () => context.push('/checkout'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Passer au paiement',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
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
