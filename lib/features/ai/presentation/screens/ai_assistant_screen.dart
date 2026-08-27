import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/living_ui.dart';

/// Assistant IA — non livré : pas de chat fictif.
class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

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
                        'Akadex IA',
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
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 56,
                        color: AkadexColors.inkMuted,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Bientôt disponible',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.ink,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'L’assistant IA n’est pas encore connecté. '
                        'Aucun chat fictif n’est proposé : reviens après '
                        'la mise en production de cette fonctionnalité.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AkadexColors.inkMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
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
