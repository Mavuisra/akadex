import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty || _password.text.length < 8) {
      setState(() => _error = 'Vérifie nom, email et mot de passe (8+ caractères).');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final username = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    await ref.read(authStateProvider.notifier).register(
          email: email,
          username: username,
          password: _password.text,
          firstName: name.split(' ').first,
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
      context.go('/home');
    } else {
      setState(() {
        _error = 'Inscription impossible.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.go('/onboarding'),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AkadexLogo(size: 96)),
                        const SizedBox(height: 20),
                        const Text(
                          'Créer un compte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AkadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 36),
                        TextField(
                          controller: _name,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Nom',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _email,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          textAlign: TextAlign.center,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFC62828)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
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
                              : const Text("S'inscrire"),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text.rich(
                              TextSpan(
                                style: TextStyle(color: AkadexColors.inkMuted),
                                children: [
                                  TextSpan(text: 'Déjà un compte ? '),
                                  TextSpan(
                                    text: 'Se connecter',
                                    style: TextStyle(
                                      color: AkadexColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
