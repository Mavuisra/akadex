import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/living_ui.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.devCode,
  });

  final String initialEmail;
  final String? devCode;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  late final TextEditingController _email;
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _success;

  static const _fieldPad = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _token = TextEditingController(text: widget.devCode ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final token = _token.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Indique une adresse e-mail valide.');
      return;
    }
    if (token.isEmpty) {
      setState(() => _error = 'Indique le code reçu par e-mail.');
      return;
    }
    if (password.length < 8) {
      setState(
        () => _error = 'Le mot de passe doit contenir au moins 8 caractères.',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            email: email,
            token: token,
            password: password,
            passwordConfirm: confirm,
          );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = 'Mot de passe mis à jour. Tu peux te connecter.';
      });
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      context.go('/login');
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
                  onPressed: () => context.go('/forgot-password'),
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
                            Text(
                              'Nouveau mot de passe',
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
                              'Saisis le code reçu, puis ton nouveau mot de passe.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                            if (widget.devCode != null &&
                                widget.devCode!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              SoftCard(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  'Mode dev : code prérempli (${widget.devCode}). '
                                  'En prod, il arrive par e-mail.',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: titleColor),
                                decoration: const InputDecoration(
                                  hintText: 'Email',
                                  border: InputBorder.none,
                                  contentPadding: _fieldPad,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _token,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: titleColor),
                                decoration: const InputDecoration(
                                  hintText: 'Code à 6 chiffres',
                                  border: InputBorder.none,
                                  contentPadding: _fieldPad,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _password,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(color: titleColor),
                                decoration: InputDecoration(
                                  hintText: 'Nouveau mot de passe',
                                  border: InputBorder.none,
                                  contentPadding: _fieldPad,
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SoftCard(
                              padding: EdgeInsets.zero,
                              child: TextField(
                                controller: _confirm,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _loading ? null : _submit(),
                                style: TextStyle(color: titleColor),
                                decoration: const InputDecoration(
                                  hintText: 'Confirmer le mot de passe',
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
                            if (_success != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _success!,
                                style: TextStyle(
                                  color: linkColor,
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
                                    : const Text('Réinitialiser'),
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
