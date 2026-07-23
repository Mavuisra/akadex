import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';

class ProfessorPublishScreen extends ConsumerStatefulWidget {
  const ProfessorPublishScreen({super.key});

  @override
  ConsumerState<ProfessorPublishScreen> createState() =>
      _ProfessorPublishScreenState();
}

class _ProfessorPublishScreenState
    extends ConsumerState<ProfessorPublishScreen> {
  final _moduleTitle = TextEditingController();
  final _lessonTitle = TextEditingController();
  final _description = TextEditingController();
  final _videoUrl = TextEditingController();
  String? _courseId;
  String _contentType = 'video';
  bool _loading = false;

  static const _types = [
    ('video', 'Vidéo de cours'),
    ('pdf', 'PDF / syllabus'),
    ('slides', 'Diapositives'),
    ('tp', 'TP'),
    ('td', 'TD'),
    ('exercise', 'Exercice'),
    ('exam', 'Examen'),
    ('solution', 'Corrigé'),
    ('book', 'Livre recommandé'),
    ('link', 'Document complémentaire'),
  ];

  @override
  void dispose() {
    _moduleTitle.dispose();
    _lessonTitle.dispose();
    _description.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_courseId == null ||
        _moduleTitle.text.trim().isEmpty ||
        _lessonTitle.text.trim().isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(academicRepositoryProvider);
      final module = await repo.createModule({
        'course': int.tryParse(_courseId!) ?? _courseId,
        'title': _moduleTitle.text.trim(),
        'description': '',
        'order': DateTime.now().millisecondsSinceEpoch % 1000,
      });
      await repo.createLesson({
        'module': int.tryParse(module.id) ?? module.id,
        'title': _lessonTitle.text.trim(),
        'description': _description.text.trim(),
        'content_type': _contentType,
        'order': 1,
        'video_url': _videoUrl.text.trim(),
        'is_published': true,
      });
      ref.invalidate(courseOutlineProvider(_courseId!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leçon publiée')),
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
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Publier une leçon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            onTap: () => context.push('/teacher-course'),
            child: const Row(
              children: [
                Icon(Icons.menu_book_outlined, color: AkadexColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau cours',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Créer le cours avec tous les champs, puis revenir ici',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AkadexColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 16),
          coursesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(apiErrorMessage(e)),
            data: (courses) => DropdownButtonFormField<String>(
              initialValue: _courseId,
              decoration: const InputDecoration(
                labelText: 'Matière / cours',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in courses.take(80))
                  DropdownMenuItem(
                    value: c.id,
                    child: Text('${c.code} — ${c.title}', overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _courseId = v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _moduleTitle,
            decoration: const InputDecoration(
              labelText: 'Chapitre / module',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lessonTitle,
            decoration: const InputDecoration(
              labelText: 'Titre de la leçon',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Type de contenu', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _contentType == t.$1,
                  onSelected: (_) => setState(() => _contentType = t.$1),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          if (_contentType == 'video') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _videoUrl,
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
                  : const Text('Publier'),
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Text(
              'Le niveau (L1–Master 2), la faculté et le département sont '
              'ceux déjà associés au cours sélectionné.',
              style: TextStyle(color: Colors.black.withValues(alpha: 0.65)),
            ),
          ),
        ],
      ),
    );
  }
}
