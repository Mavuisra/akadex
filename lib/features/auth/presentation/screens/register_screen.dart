import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
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
                        const Text(
                          'Akadex',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AkadexColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: 'Université de Kinshasa',
                          decoration: const InputDecoration(
                            hintText: 'Université',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Université de Kinshasa',
                              child: Text('UNIKIN'),
                            ),
                            DropdownMenuItem(
                              value: 'UPN',
                              child: Text('UPN'),
                            ),
                            DropdownMenuItem(
                              value: 'ISP',
                              child: Text('ISP'),
                            ),
                          ],
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: () => context.go('/home'),
                          child: const Text("S'inscrire"),
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
                                    text: 'Connexion',
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
