import 'package:flutter/material.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../data/course_pricing.dart';

/// Prix promo aligné : 15$ + 29$ barré.
class CoursePriceRow extends StatelessWidget {
  const CoursePriceRow({
    super.key,
    this.dense = false,
    this.salePrice = CoursePricing.salePriceUsd,
    this.listPrice = CoursePricing.listPriceUsd,
  });

  final bool dense;
  final double salePrice;
  final double listPrice;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final saleSize = dense ? 16.0 : 20.0;
    final listSize = dense ? 13.0 : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          CoursePricing.format(salePrice),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: saleSize,
            color: feed.ink,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          CoursePricing.format(listPrice),
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
