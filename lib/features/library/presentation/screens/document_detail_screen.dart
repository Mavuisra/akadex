import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/mocks/mock_data.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final doc = MockData.docs.firstWhere(
      (d) => d.id == widget.documentId,
      orElse: () => MockData.docs.first,
    );

    return Scaffold(
      backgroundColor: AkadexColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 48),
            decoration: const BoxDecoration(
              color: AkadexColors.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -28),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [
                  SoftCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AkadexColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'PDF',
                              style: TextStyle(
                                color: AkadexColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          doc.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AkadexColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          doc.meta,
                          style: const TextStyle(color: AkadexColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SoftCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AkadexColors.primarySoft,
                          child: Text(
                            'D',
                            style: TextStyle(
                              color: AkadexColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Par Département Informatique',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AkadexColors.ink,
                                ),
                              ),
                              Text(
                                'UNIKIN · 2023-2024',
                                style: TextStyle(
                                  color: AkadexColors.inkMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatBox(value: doc.downloads, label: 'Downloads'),
                      const SizedBox(width: 8),
                      _StatBox(value: doc.views, label: 'Views'),
                      const SizedBox(width: 8),
                      _StatBox(value: doc.rating, label: 'Rating'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doc.about,
                    style: const TextStyle(
                      color: AkadexColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: doc.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AkadexColors.primary),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: AkadexColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Téléchargement démarré')),
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger'),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _fav = !_fav),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      _fav ? Icons.favorite : Icons.favorite_border,
                      color: _fav ? AkadexColors.danger : AkadexColors.primary,
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

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AkadexColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AkadexColors.inkMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
