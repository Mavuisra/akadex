import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Indique une adresse e-mail valide.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final devCode = await repo.requestPasswordReset(email);
      if (!mounted) return;
      final uri = Uri(
        path: '/reset-password',
        queryParameters: {
          'email': email,
          if (devCode != null && devCode.isNotEmpty) 'dev_code': devCode,
        },
      );
      context.go(uri.toString());
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AkadexColors.inkOnDark : AkadexColors.ink;
    final subtitleColor =
        isDark ? AkadexColors.metaOnDark : AkadexColors.inkMuted;
    final linkColor =
        isDark ? AkadexColors.primaryOnDark : AkadexColors.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageAtmosphere(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/login'),
                  icon: Icon(Icons.arrow_back_rounded, color: titleColor),
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
                            const Center(child: AkadexLogo(size: 80)),
                            const SizedBox(height: 20),
                            Text(
                              'Mot de passe oublié',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entre ton e-mail : tu recevras un code pour '
                              'choisir un nouveau mot de passe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 28),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _submit(),
                                style: TextStyle(color: titleColor),
                                decoration: const InputDecoration(
                                  hintText: 'Email',
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
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Envoyer le code'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  foregroundColor: linkColor,
                                ),
                                child: const Text('Retour à la connexion'),
                              ),
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
