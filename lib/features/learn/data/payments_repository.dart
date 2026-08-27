import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/api_client.dart';
import 'course_pricing.dart';

/// Opérateur Mobile Money (codes backend / PawaPay).
enum MomoProvider {
  vodacomMpesa(
    'vodacom_mpesa',
    'M-Pesa',
    'Vodacom',
    'assets/images/momo/vodacom.png',
  ),
  airtel(
    'airtel',
    'Airtel Money',
    'Airtel',
    'assets/images/momo/airtel.png',
  ),
  orange(
    'orange',
    'Orange Money',
    'Orange',
    'assets/images/momo/orange.png',
  );

  const MomoProvider(
    this.apiKey,
    this.label,
    this.brand,
    this.logoAsset,
  );

  final String apiKey;
  final String label;
  final String brand;
  final String logoAsset;
}

class DepositResult {
  const DepositResult({
    required this.depositId,
    required this.status,
    required this.message,
    this.pawapayStatus = '',
    this.amount = '',
    this.currency = 'USD',
    this.courseIds = const [],
    this.grantedCourseIds = const [],
    this.accessGranted = false,
    this.failureMessage = '',
  });

  final String depositId;
  final String status;
  final String message;
  final String pawapayStatus;
  final String amount;
  final String currency;
  final List<String> courseIds;
  final List<String> grantedCourseIds;
  final bool accessGranted;
  final String failureMessage;

  bool get accepted =>
      status == 'ACCEPTED' || pawapayStatus.toUpperCase() == 'ACCEPTED';

  bool get completed =>
      status == 'COMPLETED' || pawapayStatus.toUpperCase() == 'COMPLETED';

  bool get failed =>
      status == 'FAILED' ||
      status == 'REJECTED' ||
      pawapayStatus.toUpperCase() == 'FAILED' ||
      pawapayStatus.toUpperCase() == 'REJECTED';

  bool get isTerminal => completed || failed;

  factory DepositResult.fromJson(Map<String, dynamic> json) {
    List<String> asIds(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    return DepositResult(
      depositId: (json['deposit_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? json['detail'] ?? '').toString(),
      pawapayStatus: (json['pawapay_status'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
      courseIds: asIds(json['course_ids']),
      grantedCourseIds: asIds(json['granted_course_ids']),
      accessGranted: json['access_granted'] == true,
      failureMessage: (json['failure_message'] ?? '').toString(),
    );
  }
}

class PaymentsRepository {
  PaymentsRepository(this._dio);

  final Dio _dio;

  Future<DepositResult> initiateDeposit({
    required String phone,
    required MomoProvider provider,
    required double amountUsd,
    List<String> courseIds = const [],
  }) async {
    try {
      final res = await _dio.post(
        'payments/deposits/',
        data: {
          'phone': phone,
          'provider': provider.apiKey,
          'amount': amountUsd,
          'course_ids': courseIds,
          'statement': 'Akadex cours',
        },
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return DepositResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception(
          'Connecte-toi pour finaliser le paiement.',
        );
      }
      if (e.response?.statusCode == 503) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          throw Exception(data['detail'].toString());
        }
        throw Exception(
          'Paiement temporairement indisponible. Réessaie dans un moment.',
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Paiement indisponible pour le moment. Réessaie plus tard.',
        );
      }
      final data = e.response?.data;
      if (data is Map) {
        final mapped = Map<String, dynamic>.from(data);
        if (mapped['deposit_id'] != null) {
          return DepositResult.fromJson({
            ...mapped,
            'message':
                mapped['detail'] ?? mapped['message'] ?? apiErrorMessage(e),
            'status': mapped['status'] ?? 'FAILED',
          });
        }
        final detail = mapped['detail'];
        if (detail != null) {
          throw Exception(detail.toString());
        }
        final amountErr = mapped['amount'];
        if (amountErr != null) {
          throw Exception(amountErr.toString());
        }
      }
      throw Exception(apiErrorMessage(e));
    }
  }

  Future<CatalogPricing> fetchPricing() async {
    final res = await _dio.get('payments/pricing/');
    final data = res.data;
    if (data is Map) {
      return CatalogPricing.fromJson(Map<String, dynamic>.from(data));
    }
    return CatalogPricing.offlineFallback;
  }

  Future<DepositResult> getDepositStatus(String depositId) async {
    final res = await _dio.get('payments/deposits/$depositId/');
    return DepositResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Set<String>> fetchPurchasedCourseIds() async {
    final res = await _dio.get('payments/my-courses/');
    final data = res.data;
    if (data is! Map) return {};
    final raw = data['course_ids'];
    if (raw is! List) return {};
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(dioProvider));
});

final catalogPricingProvider = FutureProvider<CatalogPricing>((ref) async {
  try {
    return await ref.watch(paymentsRepositoryProvider).fetchPricing();
  } catch (_) {
    return CatalogPricing.offlineFallback;
  }
});

/// Cours débloqués après paiement MoMo confirmé.
final purchasedCourseIdsProvider = FutureProvider<Set<String>>((ref) async {
  try {
    return await ref.watch(paymentsRepositoryProvider).fetchPurchasedCourseIds();
  } catch (_) {
    return {};
  }
});
