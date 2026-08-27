import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../data/course_pricing.dart';
import '../../data/payments_repository.dart';

/// Prix promo : tarif vente + tarif barré (API).
class CoursePriceRow extends ConsumerWidget {
  const CoursePriceRow({
    super.key,
    this.dense = false,
    this.salePrice,
    this.listPrice,
  });

  final bool dense;
  final double? salePrice;
  final double? listPrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricing =
        ref.watch(catalogPricingProvider).valueOrNull ??
            CatalogPricing.offlineFallback;
    final sale = salePrice ?? pricing.salePriceUsd;
    final list = listPrice ?? pricing.listPriceUsd;
    final feed = TimelineTokens.of(context);
    final saleSize = dense ? 16.0 : 20.0;
    final listSize = dense ? 13.0 : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          CatalogPricing.format(sale),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: saleSize,
            color: feed.ink,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          CatalogPricing.format(list),
          style: TextStyle(
            fontSize: listSize,
            fontWeight: FontWeight.w600,
            color: feed.meta,
            decoration: TextDecoration.lineThrough,
            decorationColor: feed.meta,
            height: 1,
          ),
        ),
      ],
    );
  }
}
