import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';

class AlumniPublishScreen extends ConsumerStatefulWidget {
  const AlumniPublishScreen({super.key});

  @override
  ConsumerState<AlumniPublishScreen> createState() =>
      _AlumniPublishScreenState();
}

class _AlumniPublishScreenState extends ConsumerState<AlumniPublishScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _video = TextEditingController();
  String _kind = 'alumni_advice';
  bool _loading = false;

  static const _kindsAlumni = [
    ('alumni_advice', 'Conseil académique'),
    ('alumni_path', 'Parcours universitaire'),
    ('alumni_career', 'Parcours professionnel'),
    ('alumni_tfc', 'Stages / mémoire / TFC'),
    ('alumni_video', 'Vidéo de conseil'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _video.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      final kind = user?.isAlumni == true ? _kind : 'question';
      await ref.read(communityRepositoryProvider).createPost(
            title: _title.text.trim(),
            content: _content.text.trim(),
            kind: kind,
            videoUrl: _video.text.trim(),
          );
      ref.invalidate(postsProvider('alumni'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication envoyée')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final isAlumni = user?.isAlumni == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAlumni ? 'Publier un conseil' : 'Poser une question'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isAlumni) ...[
            const Text('Type de contenu', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final k in _kindsAlumni)
                  ChoiceChip(
                    label: Text(k.$2),
                    selected: _kind == k.$1,
                    onSelected: (_) => setState(() => _kind = k.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Contenu',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          if (isAlumni && _kind == 'alumni_video') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _video,
              decoration: const InputDecoration(
                labelText: 'URL vidéo',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isAlumni ? 'Publier' : 'Envoyer la question'),
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Text(
              isAlumni
                  ? 'Partage ton expérience pour aider les promotions actuelles.'
                  : 'Les alumni de ta filière pourront te répondre.',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
            ),
          ),
        ],
      ),
    );
  }
}
