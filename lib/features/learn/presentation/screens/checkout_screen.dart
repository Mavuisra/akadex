import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../data/cart_provider.dart';
import '../../data/course_pricing.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (items.isEmpty) {
      return Scaffold(
        backgroundColor: feed.feedBg,
        appBar: AppBar(
          backgroundColor: feed.cardBg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: feed.ink,
          title: const Text('Checkout'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/learn'),
            child: const Text('Retour aux cours'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: feed.ink,
        title: Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Récapitulatif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: feed.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feed.divider),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: feed.divider),
                  ListTile(
                    title: Text(
                      items[i].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: feed.ink,
                      ),
                    ),
                    subtitle: Text(
                      items[i].teacher,
                      style: TextStyle(color: feed.meta, fontSize: 12),
                    ),
                    trailing: Text(
                      CoursePricing.format(items[i].priceUsd),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: feed.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: feed.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: feed.divider),
            ),
            child: Column(
              children: [
                _Line(
                  label: 'Sous-total',
                  value: CoursePricing.format(cart.totalUsd),
                  color: feed.meta,
                ),
                const SizedBox(height: 8),
                _Line(
                  label: 'Frais',
                  value: '0\$',
                  color: feed.meta,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: feed.divider),
                ),
                _Line(
                  label: 'Total',
                  value: CoursePricing.format(cart.totalUsd),
                  color: feed.ink,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mode de paiement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: feed.cardBg,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/checkout/mobile-money'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: feed.softTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.phone_android_rounded, color: primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payer sur le téléphone',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: feed.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vodacom, Airtel ou Orange',
                            style: TextStyle(fontSize: 12, color: feed.meta),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: feed.meta),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: () => context.push('/checkout/mobile-money'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Payer ${CoursePricing.format(cart.totalUsd)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 16 : 14,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            fontSize: bold ? 20 : 14,
            color: color,
          ),
        ),
      ],
    );
  }
}
