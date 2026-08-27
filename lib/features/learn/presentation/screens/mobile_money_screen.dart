import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/timeline_tokens.dart';
import '../../../../data/api/api_client.dart';
import '../../data/cart_provider.dart';
import '../../data/course_pricing.dart';
import '../../data/payments_repository.dart';

class MobileMoneyScreen extends ConsumerStatefulWidget {
  const MobileMoneyScreen({super.key});

  @override
  ConsumerState<MobileMoneyScreen> createState() => _MobileMoneyScreenState();
}

class _MobileMoneyScreenState extends ConsumerState<MobileMoneyScreen> {
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  MomoProvider _provider = MomoProvider.vodacomMpesa;
  bool _paying = false;
  bool _awaiting = false;
  bool _done = false;
  bool _failed = false;
  String _statusMessage = '';
  String _depositId = '';
  double _paidAmount = 0;
  int _paidCount = 0;
  Timer? _pollTimer;
  int _pollTicks = 0;

  static const _pollInterval = Duration(seconds: 3);
  static const _maxPollTicks = 80; // ~4 min

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pay(double amount, int count, List<String> courseIds) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _paying = true;
      _failed = false;
      _awaiting = false;
      _done = false;
      _statusMessage = '';
    });

    try {
      final result = await ref.read(paymentsRepositoryProvider).initiateDeposit(
            phone: _phoneCtrl.text.trim(),
            provider: _provider,
            amountUsd: amount,
            courseIds: courseIds,
          );

      if (!mounted) return;

      if (result.completed) {
        await _onPaymentConfirmed(result, amount: amount, count: count);
        return;
      }

      if (result.accepted || result.status == 'PENDING') {
        // Ne PAS vider le panier : le paiement n’est pas encore confirmé.
        setState(() {
          _paying = false;
          _awaiting = true;
          _failed = false;
          _paidAmount = amount;
          _paidCount = count;
          _depositId = result.depositId;
          _statusMessage = result.message.isNotEmpty
              ? result.message
              : 'Demande envoyée. Validez sur votre téléphone.';
        });
        _startPolling(result.depositId, amount: amount, count: count);
        return;
      }

      setState(() {
        _paying = false;
        _failed = true;
        _depositId = result.depositId;
        _statusMessage = result.message.isNotEmpty
            ? result.message
            : 'Paiement refusé (${result.status}).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _failed = true;
        _statusMessage = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : apiErrorMessage(e);
      });
    }
  }

  void _startPolling(
    String depositId, {
    required double amount,
    required int count,
  }) {
    _stopPolling();
    _pollTicks = 0;
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      unawaited(_pollOnce(depositId, amount: amount, count: count));
    });
    unawaited(_pollOnce(depositId, amount: amount, count: count));
  }

  Future<void> _pollOnce(
    String depositId, {
    required double amount,
    required int count,
  }) async {
    if (!mounted || !_awaiting) return;
    _pollTicks += 1;
    if (_pollTicks > _maxPollTicks) {
      _stopPolling();
      if (!mounted) return;
      setState(() {
        _awaiting = false;
        _failed = true;
        _statusMessage =
            'Confirmation trop longue. Le panier est conservé. '
            'Réessaie ou attends la confirmation sur ton téléphone — '
            'l’accès sera crédité dès validation.';
      });
      return;
    }

    try {
      final result =
          await ref.read(paymentsRepositoryProvider).getDepositStatus(depositId);
      if (!mounted || !_awaiting) return;

      if (result.completed) {
        await _onPaymentConfirmed(result, amount: amount, count: count);
        return;
      }
      if (result.failed) {
        _stopPolling();
        setState(() {
          _awaiting = false;
          _failed = true;
          _statusMessage = result.failureMessage.isNotEmpty
              ? result.failureMessage
              : (result.message.isNotEmpty
                  ? result.message
                  : 'Paiement échoué (${result.status}).');
        });
        return;
      }
      setState(() {
        _statusMessage = result.message.isNotEmpty
            ? result.message
            : 'En attente de confirmation PIN…';
      });
    } catch (_) {
      // Silent — next tick retries.
    }
  }

  Future<void> _onPaymentConfirmed(
    DepositResult result, {
    required double amount,
    required int count,
  }) async {
    _stopPolling();
    // Panier vidé UNIQUEMENT après COMPLETED + accès crédité côté API.
    ref.read(cartProvider.notifier).clear();
    ref.invalidate(purchasedCourseIdsProvider);
    if (!mounted) return;
    setState(() {
      _paying = false;
      _awaiting = false;
      _done = true;
      _failed = false;
      _paidAmount = amount;
      _paidCount = count;
      _depositId = result.depositId;
      _statusMessage = result.message.isNotEmpty
          ? result.message
          : 'Paiement confirmé. Accès aux cours débloqué.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (!_done && !_awaiting && items.isEmpty) {
      return Scaffold(
        backgroundColor: feed.feedBg,
        appBar: AppBar(
          backgroundColor: feed.cardBg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: feed.ink,
          title: const Text('Paiement'),
        ),
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/learn'),
            child: const Text('Panier vide — retour'),
          ),
        ),
      );
    }

    final amountLabel = CoursePricing.format(
      (_done || _awaiting) ? _paidAmount : cart.totalUsd,
    );

    return Scaffold(
      backgroundColor: feed.feedBg,
      appBar: AppBar(
        backgroundColor: feed.cardBg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: feed.ink,
        title: Text(
          'Paiement',
          style: TextStyle(fontWeight: FontWeight.w800, color: feed.ink),
        ),
      ),
      body: _done
          ? _SuccessBody(
              amountLabel: amountLabel,
              provider: _provider,
              phone: _phoneCtrl.text.trim(),
              courseCount: _paidCount,
              depositId: _depositId,
              message: _statusMessage,
              onHome: () => context.go('/learn'),
            )
          : _awaiting
              ? _AwaitingBody(
                  amountLabel: amountLabel,
                  provider: _provider,
                  phone: _phoneCtrl.text.trim(),
                  courseCount: _paidCount,
                  depositId: _depositId,
                  message: _statusMessage,
                  onCancel: () {
                    _stopPolling();
                    setState(() {
                      _awaiting = false;
                      _statusMessage =
                          'Paiement en cours côté opérateur. '
                          'Le panier est conservé jusqu’à confirmation.';
                    });
                  },
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: feed.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: feed.divider),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${items.length} cours · $amountLabel USD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: feed.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Opérateur',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: feed.ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final op in MomoProvider.values) ...[
                            if (op != MomoProvider.values.first)
                              const SizedBox(width: 10),
                            Expanded(
                              child: _OperatorCard(
                                provider: op,
                                selected: _provider == op,
                                onTap: () => setState(() => _provider = op),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Numéro de téléphone',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: feed.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\s]'),
                          ),
                        ],
                        style: TextStyle(color: feed.ink),
                        decoration: InputDecoration(
                          hintText: 'ex. +243 800 000 000',
                          filled: true,
                          fillColor: feed.cardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: feed.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: feed.divider),
                          ),
                          prefixIcon:
                              Icon(Icons.phone_rounded, color: feed.meta),
                        ),
                        validator: (v) {
                          final digits =
                              (v ?? '').replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 9) {
                            return 'Entrez un numéro RD Congo valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tu recevras une demande de confirmation sur ce numéro. '
                        'Le panier ne sera vidé qu’après validation du paiement.',
                        style: TextStyle(
                          fontSize: 13,
                          color: feed.meta,
                          height: 1.35,
                        ),
                      ),
                      if (_failed && _statusMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x33E53935),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE53935)),
                          ),
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              color: feed.ink,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _paying
                              ? null
                              : () => _pay(
                                    cart.totalUsd,
                                    items.length,
                                    items.map((e) => e.courseId).toList(),
                                  ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _paying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Payer · $amountLabel',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  const _OperatorCard({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final MomoProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: feed.cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primary : feed.divider,
              width: selected ? 2 : 1,
            ),
            color: selected ? feed.softTint : feed.cardBg,
          ),
          child: Column(
            children: [
              _OperatorLogo(provider: provider, size: 44),
              const SizedBox(height: 10),
              Text(
                provider.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.2,
                  color: selected ? primary : feed.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperatorLogo extends StatelessWidget {
  const _OperatorLogo({required this.provider, this.size = 44});

  final MomoProvider provider;
  final double size;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ColoredBox(
        color: Colors.white,
        child: Image.asset(
          provider.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            color: feed.softTint,
            child: Text(
              provider.brand.isNotEmpty ? provider.brand[0] : '?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.42,
                color: feed.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AwaitingBody extends StatelessWidget {
  const _AwaitingBody({
    required this.amountLabel,
    required this.provider,
    required this.phone,
    required this.courseCount,
    required this.depositId,
    required this.message,
    required this.onCancel,
  });

  final String amountLabel;
  final MomoProvider provider;
  final String phone;
  final int courseCount;
  final String depositId;
  final String message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primary,
            ),
          ),
          const SizedBox(height: 20),
          _OperatorLogo(provider: provider, size: 48),
          const SizedBox(height: 16),
          Text(
            'En attente de confirmation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$message\n\n'
            'Valide le PIN sur ton téléphone.\n'
            'Le panier reste intact jusqu’à confirmation.\n\n'
            '${provider.label} · $amountLabel · $courseCount cours\n'
            '$phone'
            '${depositId.isNotEmpty ? '\nRéf. $depositId' : ''}',
            textAlign: TextAlign.center,
            style: TextStyle(color: feed.meta, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextButton(
            onPressed: onCancel,
            child: const Text('Annuler l’attente'),
          ),
        ],
      ),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    required this.amountLabel,
    required this.provider,
    required this.phone,
    required this.courseCount,
    required this.depositId,
    required this.message,
    required this.onHome,
  });

  final String amountLabel;
  final MomoProvider provider;
  final String phone;
  final int courseCount;
  final String depositId;
  final String message;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final feed = TimelineTokens.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: feed.softTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 48, color: primary),
          ),
          const SizedBox(height: 16),
          _OperatorLogo(provider: provider, size: 48),
          const SizedBox(height: 16),
          Text(
            'Paiement confirmé',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: feed.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$message\n\n'
            '${provider.label} · $amountLabel · $courseCount cours\n'
            '$phone'
            '${depositId.isNotEmpty ? '\nRéf. $depositId' : ''}',
            textAlign: TextAlign.center,
            style: TextStyle(color: feed.meta, height: 1.4),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onHome,
              child: const Text(
                'Accéder aux cours',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
