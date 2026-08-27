import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

/// Confirmation du nouvel e-mail (API `POST auth/me/confirm-email/`).
class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key, this.initialToken = ''});

  final String initialToken;

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  late final TextEditingController _token;
  bool _loading = false;
  String? _error;

  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Colle le code reçu dans tes notifications.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authStateProvider.notifier).confirmEmail(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail confirmé.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;
    final pending = user?.pendingEmail ?? '';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AkadexColors.inkOnDark : AkadexColors.ink;
    final subtitleColor =
        isDark ? AkadexColors.metaOnDark : AkadexColors.inkMuted;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile');
                        }
                      },
                      icon: Icon(Icons.arrow_back_rounded, color: titleColor),
                    ),
                    Expanded(
                      child: Text(
                        'Confirmer l’e-mail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: FadeSlideIn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              pending.isEmpty
                                  ? 'Aucune demande de changement d’e-mail '
                                      'en cours.'
                                  : 'Un code a été envoyé dans tes '
                                      'notifications pour confirmer '
                                      '$pending.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _token,
                                enabled: pending.isNotEmpty && !_loading,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) =>
                                    pending.isEmpty || _loading
                                        ? null
                                        : _submit(),
                                style: TextStyle(color: titleColor),
                                decoration: const InputDecoration(
                                  hintText: 'Code de confirmation',
                                  border: InputBorder.none,
                                  contentPadding: _fieldPad,
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: AkadexColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: pending.isEmpty || _loading
                                    ? null
                                    : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Confirmer'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  context.push('/notifications'),
                              child: const Text('Ouvrir les notifications'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
