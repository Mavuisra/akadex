import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/api_client.dart';

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
  });

  final String depositId;
  final String status;
  final String message;
  final String pawapayStatus;
  final String amount;
  final String currency;

  bool get accepted =>
      status == 'ACCEPTED' || pawapayStatus.toUpperCase() == 'ACCEPTED';

  bool get completed => status == 'COMPLETED';

  factory DepositResult.fromJson(Map<String, dynamic> json) {
    return DepositResult(
      depositId: (json['deposit_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      message: (json['message'] ?? json['detail'] ?? '').toString(),
      pawapayStatus: (json['pawapay_status'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString(),
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
          'Connecte-toi pour payer avec Mobile Money (PawaPay).',
        );
      }
      if (e.response?.statusCode == 503) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) {
          throw Exception(data['detail'].toString());
        }
        throw Exception(
          'PawaPay indisponible (503). Vérifie PAWAPAY_API_TOKEN sur Render.',
        );
      }
      if (e.response?.statusCode == 404) {
        throw Exception(
          'Paiement indisponible sur le serveur. '
          'L’API PawaPay n’est pas encore déployée sur Render '
          '(endpoint /payments/deposits).',
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
      }
      throw Exception(apiErrorMessage(e));
    }
  }

  Future<DepositResult> getDepositStatus(String depositId) async {
    final res = await _dio.get('payments/deposits/$depositId/');
    return DepositResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  return PaymentsRepository(ref.watch(dioProvider));
});
