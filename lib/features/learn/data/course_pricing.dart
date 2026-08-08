/// Tarifs vitrine Apprendre (USD).
abstract final class CoursePricing {
  /// Prix affiché barré (avant promo).
  static const double listPriceUsd = 29;

  /// Prix actuel pour tous les cours.
  static const double salePriceUsd = 15;

  static String format(double amount) {
    if (amount == amount.roundToDouble()) {
      return '${amount.toInt()}\$';
    }
    return '${amount.toStringAsFixed(2)}\$';
  }

  static String get listLabel => format(listPriceUsd);
  static String get saleLabel => format(salePriceUsd);
}
