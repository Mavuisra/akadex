import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/auth_entry_style.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

/// Écran d’entrée — layout type Facebook : logo, champs, CTA, créer un compte.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await ref.read(authStateProvider.notifier).login(
          _email.text,
          _password.text,
        );
    if (!mounted) return;
    final auth = ref.read(authStateProvider);
    if (auth.hasError) {
      setState(() {
        _error = apiErrorMessage(auth.error!);
        _loading = false;
      });
      return;
    }
    if (auth.valueOrNull != null) {
      context.go(auth.valueOrNull!.homeRoute);
    } else {
      setState(() {
        _error = 'Connexion impossible.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AuthEntryStyle.background(isDark);
    final titleColor = AuthEntryStyle.title(isDark);
    final muted = AuthEntryStyle.muted(isDark);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: canPop
                  ? IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: titleColor,
                      ),
                    )
                  : const SizedBox(height: 48),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: AkadexLogo(size: 72, borderRadius: 36),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'L’outil que tu cherchais',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 36),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: titleColor, fontSize: 16),
                          decoration: AuthEntryStyle.fieldDecoration(
                            hint: 'E-mail ou téléphone',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_loading) _submit();
                          },
                          style: TextStyle(color: titleColor, fontSize: 16),
                          decoration: AuthEntryStyle.fieldDecoration(
                            hint: 'Mot de passe',
                            isDark: isDark,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: muted,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AkadexColors.danger,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: AuthEntryStyle.primaryButton(isDark),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Se connecter'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                context.go('/forgot-password'),
                            style: TextButton.styleFrom(
                              foregroundColor: titleColor,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => context.go('/register'),
                        style: AuthEntryStyle.outlineButton(isDark),
                        child: const Text('Créer un nouveau compte'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Akadex',
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
