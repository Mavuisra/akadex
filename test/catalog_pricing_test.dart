import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:akadex/features/learn/data/course_pricing.dart';
import 'package:akadex/features/learn/data/learn_domains.dart';

void main() {
  group('CatalogPricing', () {
    test('formats whole dollars without decimals', () {
      expect(CatalogPricing.format(15), '15\$');
      expect(CatalogPricing.format(29), '29\$');
    });

    test('totalForCount uses sale price', () {
      const pricing = CatalogPricing(salePriceUsd: 15, listPriceUsd: 29);
      expect(pricing.totalForCount(2), 30);
      expect(pricing.totalForCount(0), 0);
    });

    test('fromJson parses API payload', () {
      final pricing = CatalogPricing.fromJson({
        'sale_price_usd': '12.50',
        'list_price_usd': '20',
        'currency': 'USD',
      });
      expect(pricing.salePriceUsd, 12.5);
      expect(pricing.listPriceUsd, 20);
      expect(pricing.currency, 'USD');
    });
  });

  group('LearnDomains.fromApi', () {
    test('maps slug and keywords from API', () {
      final d = LearnDomains.fromApi(
        slug: 'informatique',
        name: 'Informatique',
        keywordsCsv: 'python, ia',
      );
      expect(d.id, 'informatique');
      expect(d.name, 'Informatique');
      expect(d.keywords, contains('python'));
      expect(d.icon, Icons.computer_rounded);
    });

    test('unknown slug gets default icon', () {
      final d = LearnDomains.fromApi(slug: 'nouveau', name: 'Nouveau');
      expect(d.id, 'nouveau');
      expect(d.icon, Icons.category_outlined);
    });
  });
}
