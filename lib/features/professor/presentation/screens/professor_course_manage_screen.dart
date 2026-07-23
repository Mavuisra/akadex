import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/api/api_client.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

final courseStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  return ref.watch(academicRepositoryProvider).fetchCourseStats(id);
});

/// Détail + stats + édition d’un cours enseignant (style Facebook).
class ProfessorCourseManageScreen extends ConsumerStatefulWidget {
  const ProfessorCourseManageScreen({super.key, required this.courseId});

  final String courseId;

  @override
  ConsumerState<ProfessorCourseManageScreen> createState() =>
      _ProfessorCourseManageScreenState();
}

class _ProfessorCourseManageScreenState
    extends ConsumerState<ProfessorCourseManageScreen> {
  static const _fbBg = Color(0xFFF0F2F5);
  static const _fbInk = Color(0xFF050505);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBlue = Color(0xFF0866FF);

  bool _editing = false;
  bool _saving = false;
  String? _error;

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _coverUrl;
  late final TextEditingController _code;
  late final TextEditingController _credits;
  late final TextEditingController _hours;
  String? _cycle;
  String? _semester;
  bool _controllersReady = false;

  static const _cycles = <String>['L1', 'L2', 'L3', 'Master 1', 'Master 2'];
  static const _semesters = <String>['S1', 'S2'];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _coverUrl = TextEditingController();
    _code = TextEditingController();
    _credits = TextEditingController();
    _hours = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _coverUrl.dispose();
    _code.dispose();
    _credits.dispose();
    _hours.dispose();
    super.dispose();
  }

  void _seedFrom(Course course) {
    if (_controllersReady) return;
    _controllersReady = true;
    _title.text = course.title;
    _description.text = course.description;
    _coverUrl.text = course.coverUrl;
    _code.text = course.code;
    _credits.text = course.credits > 0 ? '${course.credits}' : '';
    _hours.text =
        course.estimatedHours > 0 ? '${course.estimatedHours}' : '';
    _cycle = _cycles.contains(course.semester) ? course.semester : course.semester;
    if (!_cycles.contains(_cycle)) {
      for (final c in _cycles) {
        if (course.semester.contains(c) || course.promotion.contains(c)) {
          _cycle = c;
          break;
        }
      }
    }
    _semester = _semesters.contains(course.levelLabel)
        ? course.levelLabel
        : (_semesters.contains(course.semester) ? course.semester : null);
  }

  Future<void> _save() async {
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'Titre trop court.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final credits = int.tryParse(_credits.text.trim()) ?? 0;
      final hours = int.tryParse(_hours.text.trim()) ?? 0;
      await ref.read(academicRepositoryProvider).updateCourse(
        widget.courseId,
        {
          'title': _title.text.trim(),
          'description': _description.text.trim(),
          if (_coverUrl.text.trim().isNotEmpty)
            'cover_url': _coverUrl.text.trim(),
          if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
          if (_cycle != null) 'semester': _cycle,
          if (_semester != null) 'level_label': _semester,
          if (credits > 0) 'credits': credits,
          if (hours > 0) 'estimated_hours': hours,
        },
      );
      ref.invalidate(courseProvider(widget.courseId));
      ref.invalidate(courseOutlineProvider(widget.courseId));
      ref.invalidate(coursesProvider);
      ref.invalidate(courseStatsProvider(widget.courseId));
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cours mis à jour')),
      );
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _fbMuted),
      filled: true,
      fillColor: _fbBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseProvider(widget.courseId));
    final statsAsync = ref.watch(courseStatsProvider(widget.courseId));
    final outlineAsync = ref.watch(courseOutlineProvider(widget.courseId));

    return Scaffold(
      backgroundColor: _fbBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _fbInk),
        ),
        title: const Text(
          'Mon cours',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _fbInk,
          ),
        ),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              style: TextButton.styleFrom(
                foregroundColor: _fbBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Modifier'),
            )
          else
            TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: _fbBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE4E6EB),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _fbBorder),
        ),
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (course) {
          _seedFrom(course);
          return ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              const SizedBox(height: 8),
              // Stats
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: statsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CupertinoActivityIndicator(),
                    ),
                  ),
                  error: (_, _) => _StatsFallback(course: course),
                  data: (stats) {
                    final activity =
                        (stats['activity_7d'] as List?) ?? const [];
                    final values = activity
                        .map(
                          (e) =>
                              ((e as Map)['value'] as num?)?.toDouble() ?? 0,
                        )
                        .toList();
                    final labels = activity
                        .map((e) => ((e as Map)['label'] ?? '').toString())
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _fbInk,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStat(
                                label: 'Visites',
                                value: '${stats['views'] ?? course.views}',
                                icon: Icons.visibility_outlined,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStat(
                                label: 'Étudiants',
                                value: '${stats['students'] ?? 0}',
                                icon: Icons.people_outline,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStat(
                                label: 'Leçons',
                                value: '${stats['lessons'] ?? 0}',
                                icon: Icons.play_lesson_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Activité (7 j)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _fbMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: _SimpleBars(
                            values: values,
                            labels: labels,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Infos / édition
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: _editing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Modifier le cours',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _title,
                            decoration: _dec('Titre'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _description,
                            maxLines: 3,
                            decoration: _dec('Description'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _coverUrl,
                            decoration: _dec('URL couverture'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _code,
                            decoration: _dec('Code UE'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _cycles.contains(_cycle)
                                      ? _cycle
                                      : null,
                                  decoration: _dec('Niveau'),
                                  items: [
                                    for (final c in _cycles)
                                      DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _cycle = v),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _semesters.contains(_semester)
                                      ? _semester
                                      : null,
                                  decoration: _dec('Semestre'),
                                  items: [
                                    for (final s in _semesters)
                                      DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _semester = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _credits,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _dec('Crédits'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _hours,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: _dec('Volume (h)'),
                                ),
                              ),
                            ],
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFE41E3F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(() {
                              _editing = false;
                              _controllersReady = false;
                              _error = null;
                            }),
                            child: const Text('Annuler'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: _fbInk,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${course.code} · ${course.semester}',
                            style: const TextStyle(
                              color: _fbMuted,
                              fontSize: 13,
                            ),
                          ),
                          if (course.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              course.description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: _fbInk,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/library/course/${course.id}',
                                  ),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Voir page publique'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _fbBlue,
                                    side: const BorderSide(color: _fbBorder),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      context.push('/teacher-publish'),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Leçon'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _fbBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              // Modules
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: const Text(
                  'Modules & leçons',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _fbInk,
                  ),
                ),
              ),
              outlineAsync.when(
                loading: () => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
                error: (e, _) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Text(apiErrorMessage(e)),
                ),
                data: (outline) {
                  if (outline.modules.isEmpty) {
                    return Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: const Text(
                        'Aucun module. Ajoute une leçon pour démarrer.',
                        style: TextStyle(color: _fbMuted),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final m in outline.modules)
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: _fbBorder,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final l in m.lessons)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    bottom: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        l.contentType == 'video'
                                            ? Icons.play_circle_outline
                                            : Icons.description_outlined,
                                        size: 16,
                                        color: _fbMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          l.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: _fbInk,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsFallback extends StatelessWidget {
  const _StatsFallback({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Visites',
            value: '${course.views}',
            icon: Icons.visibility_outlined,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _MiniStat(
            label: 'Étudiants',
            value: '—',
            icon: Icons.people_outline,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0866FF)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF050505),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF65676B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBars extends StatelessWidget {
  const _SimpleBars({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(
        child: Text(
          'Pas encore d’activité',
          style: TextStyle(color: Color(0xFF65676B)),
        ),
      );
    }
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    final peak = maxV <= 0 ? 1.0 : maxV;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (values[i] / peak).clamp(0.05, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0866FF),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i < labels.length ? labels[i] : '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF65676B),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
