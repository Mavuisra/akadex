import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/living_ui.dart';

/// Centre d’aide — FAQ basée sur les fonctions réellement livrées.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'Comment me connecter ?',
      'Utilise ton e-mail et ton mot de passe. '
          'Si tu as oublié le mot de passe, le lien « Mot de passe oublié » '
          'sur l’écran de connexion envoie un code de réinitialisation.',
    ),
    (
      'Comment acheter un cours ?',
      'Ajoute le cours au panier, puis paie depuis ton téléphone. '
          'L’accès est débloqué dès que le paiement est confirmé.',
    ),
    (
      'Messages en temps réel',
      'Les conversations se rafraîchissent automatiquement. '
          'Tu peux aussi recevoir une notification push quand quelqu’un t’écrit.',
    ),
    (
      'Mode hors ligne',
      'Si le réseau tombe, Akadex affiche un bandeau « Hors ligne » '
          'et continue d’afficher le catalogue cours/docs déjà synchronisé. '
          'Touche le bandeau pour retenter la sync.',
    ),
    (
      'Enseignant : messages et notifications',
      'Depuis ton hub enseignant, les icônes Messages et Notifications '
          'sont en haut à droite, comme sur l’accueil étudiant.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Centre d’aide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    for (final (q, a) in _faqs) ...[
                      Text(
                        q,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AkadexColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a,
                        style: const TextStyle(
                          color: AkadexColors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    FilledButton.icon(
                      onPressed: () => context.push('/profile/report'),
                      icon: const Icon(Icons.report_gmailerrorred_outlined),
                      label: const Text('Signaler un problème'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signaler un problème via e-mail (pas de backend inventé).
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      setState(() => _error = 'Indique un objet et une description.');
      return;
    }
    setState(() => _error = null);
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@akadex.app',
      queryParameters: {
        'subject': '[Akadex] $subject',
        'body': body,
      },
    );
    final ok = await launchUrl(uri);
    if (!mounted) return;
    if (!ok) {
      setState(
        () => _error =
            'Impossible d’ouvrir l’app mail. Écris à support@akadex.app.',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client mail ouvert.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Signaler un problème',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                    TextButton(onPressed: _send, child: const Text('Envoyer')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Ton message s’ouvre dans ton application mail '
                      'vers support@akadex.app. Aucune donnée n’est stockée '
                      'ici côté serveur pour ce formulaire.',
                      style: TextStyle(
                        color: AkadexColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subject,
                      decoration: const InputDecoration(
                        labelText: 'Objet',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _body,
                      minLines: 6,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confidentialité — textes alignés sur le comportement réel de l’app.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Confidentialité',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: const [
                    _PrivacyBlock(
                      title: 'Compte',
                      body:
                          'Ton e-mail sert à la connexion et aux codes de '
                          'confirmation / reset. Un changement d’e-mail exige '
                          'un code reçu dans tes notifications in-app.',
                    ),
                    _PrivacyBlock(
                      title: 'Messages',
                      body:
                          'Les conversations sont privées entre participants. '
                          'Seul toi et ton interlocuteur y ont accès côté API.',
                    ),
                    _PrivacyBlock(
                      title: 'Notifications push',
                      body:
                          'Un jeton appareil est enregistré uniquement si tu '
                          'es connecté et as autorisé les notifications. '
                          'Tu peux révoquer l’autorisation dans les réglages '
                          'du téléphone.',
                    ),
                    _PrivacyBlock(
                      title: 'Hors ligne',
                      body:
                          'Un cache local (cours / documents) peut rester sur '
                          'l’appareil pour la lecture hors ligne. Il n’est pas '
                          'partagé avec d’autres utilisateurs.',
                    ),
                    _PrivacyBlock(
                      title: 'Paiements',
                      body:
                          'Les paiements de cours sont traités via un prestataire '
                          'sécurisé. Akadex conserve le statut du paiement et les '
                          'cours achetés, jamais ton code secret (PIN).',
                    ),
                    _PrivacyBlock(
                      title: 'Suppression de compte',
                      body:
                          'Tu peux supprimer ton compte dans Profil → '
                          'Paramètres → Supprimer mon compte. Les données '
                          'personnelles sont alors anonymisées. '
                          'Politique complète : https://akadex.onrender.com/legal/privacy/',
                    ),
                    _PrivacyBlock(
                      title: 'Désinstaller l’application',
                      body:
                          'Sur iPhone : appui long sur l’icône → Supprimer l’app. '
                          'Sur Android : Réglages → Applications → Akadex → '
                          'Désinstaller. La désinstallation n’efface pas le '
                          'compte serveur : utilise « Supprimer mon compte ».',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conditions générales d’utilisation.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'Conditions d’utilisation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: const [
                    _PrivacyBlock(
                      title: '1. Objet',
                      body:
                          'Akadex est une plateforme académique (cours, documents, '
                          'communauté, messagerie). En créant un compte, tu acceptes '
                          'ces conditions.',
                    ),
                    _PrivacyBlock(
                      title: '2. Compte',
                      body:
                          'Tu es responsable de la confidentialité de ton mot de passe '
                          'et des informations fournies (identité, matricule, parcours). '
                          'Les comptes enseignants et étudiants sont soumis à la '
                          'modération de la plateforme.',
                    ),
                    _PrivacyBlock(
                      title: '3. Contenu',
                      body:
                          'Tu restes propriétaire du contenu que tu publies. En le '
                          'mettant en ligne, tu autorises Akadex à l’héberger et à '
                          'l’afficher aux utilisateurs autorisés. Le contenu illégal, '
                          'diffamatoire ou portant atteinte aux droits d’autrui peut '
                          'être retiré.',
                    ),
                    _PrivacyBlock(
                      title: '4. Achats de cours',
                      body:
                          'Les prix affichés sont en USD. Le montant facturé est '
                          'calculé par le serveur. L’accès au cours est débloqué '
                          'après confirmation du paiement. Les remboursements '
                          'suivent la politique du prestataire / de la plateforme.',
                    ),
                    _PrivacyBlock(
                      title: '5. Disponibilité',
                      body:
                          'Nous visons une disponibilité continue, sans garantie '
                          'absolue (maintenance, incidents réseau). Certaines '
                          'fonctions (ex. assistant IA) peuvent être annoncées '
                          'comme « bientôt disponibles ».',
                    ),
                    _PrivacyBlock(
                      title: '6. Contact',
                      body:
                          'Pour une question ou un signalement, utilise « Signaler '
                          'un problème » dans le profil, ou contacte le support '
                          'Akadex via l’adresse indiquée sur le site / store.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyBlock extends StatelessWidget {
  const _PrivacyBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AkadexColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AkadexColors.inkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
