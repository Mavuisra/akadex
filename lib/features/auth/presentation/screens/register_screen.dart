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
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => context.go('/onboarding'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Créer un compte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rejoins la communauté Akadex',
              style: TextStyle(color: AkadexColors.inkMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email étudiant',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: 'Université de Kinshasa',
              decoration: const InputDecoration(labelText: 'Université'),
              items: const [
                DropdownMenuItem(
                  value: 'Université de Kinshasa',
                  child: Text('Université de Kinshasa'),
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
          ],
        ),
      ),
    );
  }
}
