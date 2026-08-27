/// Tarifs catalogue Apprendre — valeurs affichées = API `/payments/pricing/`.
/// Le montant payé est toujours recalculé côté serveur.
class CatalogPricing {
  const CatalogPricing({
    required this.salePriceUsd,
    required this.listPriceUsd,
    this.currency = 'USD',
  });

  final double salePriceUsd;
  final double listPriceUsd;
  final String currency;

  /// Affichage hors-ligne uniquement — jamais source de vérité pour le paiement.
  static const offlineFallback = CatalogPricing(
    salePriceUsd: 15,
    listPriceUsd: 29,
  );

  double totalForCount(int courseCount) =>
      salePriceUsd * (courseCount < 0 ? 0 : courseCount);

  static String format(double amount) {
    if (amount == amount.roundToDouble()) {
      return '${amount.toInt()}\$';
    }
    return '${amount.toStringAsFixed(2)}\$';
  }

  String get listLabel => format(listPriceUsd);
  String get saleLabel => format(salePriceUsd);

  factory CatalogPricing.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return CatalogPricing(
      salePriceUsd: asDouble(json['sale_price_usd'], offlineFallback.salePriceUsd),
      listPriceUsd: asDouble(json['list_price_usd'], offlineFallback.listPriceUsd),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }
}

/// @Deprecated Use [CatalogPricing] + [catalogPricingProvider].
typedef CoursePricing = CatalogPricing;
