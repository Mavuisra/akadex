import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/theme/timeline_tokens.dart';
import '../../../../core/widgets/file_drop_validator.dart';
import '../../../../core/widgets/file_drop_zone.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/mappers/mappers.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../learn/data/learn_domains.dart';

/// Publication d’un cours — style composer Facebook + modules / leçons / vidéos.
class ProfessorCreateCourseScreen extends ConsumerStatefulWidget {
  const ProfessorCreateCourseScreen({super.key});

  @override
  ConsumerState<ProfessorCreateCourseScreen> createState() =>
      _ProfessorCreateCourseScreenState();
}

class _DraftLesson {
  _DraftLesson()
      : title = TextEditingController(),
        videoUrl = TextEditingController();

  final TextEditingController title;
  final TextEditingController videoUrl;
  String contentType = 'video';
  List<int>? fileBytes;
  String? fileName;
  String? filePath;

  bool get hasFile =>
      (fileBytes != null && fileBytes!.isNotEmpty) ||
      (fileName != null && fileName!.isNotEmpty);

  void clearFile() {
    fileBytes = null;
    fileName = null;
    filePath = null;
  }

  void dispose() {
    title.dispose();
    videoUrl.dispose();
  }
}

class _DraftModule {
  _DraftModule() : title = TextEditingController() {
    lessons.add(_DraftLesson());
  }

  final TextEditingController title;
  final List<_DraftLesson> lessons = [];

  void dispose() {
    title.dispose();
    for (final l in lessons) {
      l.dispose();
    }
  }
}

class _ProfessorCreateCourseScreenState
    extends ConsumerState<ProfessorCreateCourseScreen> {
  static const _fbBg = Color(0xFFF0F2F5);
  static const _fbInk = Color(0xFF050505);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBlue = Color(0xFF0866FF);

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _code = TextEditingController();
  final _coverUrl = TextEditingController();
  final _credits = TextEditingController();
  final _hours = TextEditingController();

  static const _lessonTypes = <(String, String, IconData)>[
    ('video', 'Vidéo', Icons.play_circle_outline_rounded),
    ('pdf', 'PDF', Icons.picture_as_pdf_outlined),
    ('slides', 'Diapos', Icons.slideshow_outlined),
    ('tp', 'TP', Icons.science_outlined),
    ('td', 'TD', Icons.edit_note_outlined),
    ('exercise', 'Exercice', Icons.fitness_center_outlined),
  ];

  static const _difficulties = <String>[
    'Débutant',
    'Intermédiaire',
    'Avancé',
  ];

  String? _difficulty;
  final Set<String> _domainSlugs = {};
  final Map<String, String> _domainLabels = {};
  String? _promotionId;
  String? _promotionName;
  final _tagInput = TextEditingController();
  List<PromotionItem> _promotions = const [];
  final List<_DraftModule> _modules = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _modules.add(_DraftModule());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPromotions());
  }

  Future<void> _loadPromotions() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final deptId = user?.departmentId ?? '';
    if (deptId.isEmpty) return;
    try {
      final list = await ref
          .read(academicRepositoryProvider)
          .fetchPromotions(departmentId: deptId);
      if (!mounted) return;
      setState(() => _promotions = list);
    } catch (_) {}
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _code.dispose();
    _coverUrl.dispose();
    _credits.dispose();
    _hours.dispose();
    _tagInput.dispose();
    for (final m in _modules) {
      m.dispose();
    }
    super.dispose();
  }

  String _slugify(String raw) {
    final lower = raw.trim().toLowerCase();
    final buf = StringBuffer();
    var dash = false;
    for (final cu in lower.runes) {
      final ch = String.fromCharCode(cu);
      final ok = RegExp(r'[a-z0-9]').hasMatch(ch);
      if (ok) {
        buf.write(ch);
        dash = false;
      } else if (!dash && buf.isNotEmpty) {
        buf.write('-');
        dash = true;
      }
    }
    return buf.toString().replaceAll(RegExp(r'-+$'), '');
  }

  void _commitTagInput() {
    final raw = _tagInput.text.trim();
    if (raw.isEmpty) return;
    final isPromo = RegExp(
      r'^(l[123]|m[12]|master|licence|promo)',
      caseSensitive: false,
    ).hasMatch(raw);
    setState(() {
      if (isPromo) {
        _promotionId = null;
        _promotionName = raw;
      } else {
        final slug = _slugify(raw);
        if (slug.isNotEmpty) {
          _domainSlugs.add(slug);
          _domainLabels[slug] = raw;
        }
      }
      _tagInput.clear();
    });
  }

  void _addModule() {
    setState(() => _modules.add(_DraftModule()));
  }

  void _removeModule(int index) {
    if (_modules.length <= 1) return;
    setState(() {
      _modules.removeAt(index).dispose();
    });
  }

  void _addLesson(int moduleIndex) {
    setState(() => _modules[moduleIndex].lessons.add(_DraftLesson()));
  }

  void _removeLesson(int moduleIndex, int lessonIndex) {
    final lessons = _modules[moduleIndex].lessons;
    if (lessons.length <= 1) return;
    setState(() {
      lessons.removeAt(lessonIndex).dispose();
    });
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null || !user.usesTeacherShell) {
      setState(() => _error = 'Réservé aux enseignants.');
      return;
    }
    if (user.departmentId.isEmpty) {
      setState(
        () => _error =
            'Complète ton département dans le profil avant de publier.',
      );
      return;
    }
    if (_title.text.trim().length < 3) {
      setState(() => _error = 'Ajoute un titre au cours.');
      return;
    }

    for (var i = 0; i < _modules.length; i++) {
      final m = _modules[i];
      if (m.title.text.trim().isEmpty) {
        setState(() => _error = 'Module ${i + 1} : ajoute un titre.');
        return;
      }
      for (var j = 0; j < m.lessons.length; j++) {
        final l = m.lessons[j];
        if (l.title.text.trim().isEmpty) {
          setState(
            () => _error =
                'Module ${i + 1}, leçon ${j + 1} : ajoute un titre.',
          );
          return;
        }
        if (l.contentType == 'video' && l.videoUrl.text.trim().isEmpty) {
          setState(
            () => _error =
                'Module ${i + 1}, leçon ${j + 1} : colle le lien vidéo.',
          );
          return;
        }
        if (l.contentType != 'video' && !l.hasFile) {
          setState(
            () => _error =
                'Module ${i + 1}, leçon ${j + 1} : ajoute un fichier '
                '(glisser-déposer ou parcourir).',
          );
          return;
        }
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(academicRepositoryProvider);
      final hours = int.tryParse(_hours.text.trim()) ?? 0;
      final credits = int.tryParse(_credits.text.trim()) ?? 0;
      final course = await repo.createCourse({
        'title': _title.text.trim(),
        if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        if (_coverUrl.text.trim().isNotEmpty)
          'cover_url': _coverUrl.text.trim(),
        if (hours > 0) 'estimated_hours': hours,
        if (credits > 0) 'credits': credits,
        if (_difficulty != null && _difficulty!.isNotEmpty)
          'level_label': _difficulty,
        'teacher_name': user.name,
        if (_domainSlugs.isNotEmpty) 'domain_slugs': _domainSlugs.toList(),
        if (_promotionId != null && _promotionId!.isNotEmpty)
          'promotion_id': int.tryParse(_promotionId!) ?? _promotionId,
        if ((_promotionId == null || _promotionId!.isEmpty) &&
            (_promotionName?.isNotEmpty ?? false))
          'promotion_name': _promotionName,
      });

      for (var i = 0; i < _modules.length; i++) {
        final draft = _modules[i];
        final module = await repo.createModule({
          'course': int.tryParse(course.id) ?? course.id,
          'title': draft.title.text.trim(),
          'description': '',
          'order': i + 1,
        });
        for (var j = 0; j < draft.lessons.length; j++) {
          final lesson = draft.lessons[j];
          await repo.createLessonMultipart(
            moduleId: int.tryParse(module.id) ?? module.id,
            title: lesson.title.text.trim(),
            description: '',
            contentType: lesson.contentType,
            order: j + 1,
            videoUrl: lesson.videoUrl.text.trim(),
            isPublished: true,
            fileBytes: lesson.fileBytes,
            fileName: lesson.fileName,
            filePath: lesson.filePath,
          );
        }
      }

      ref.invalidate(coursesProvider);
      ref.invalidate(courseOutlineProvider(course.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '« ${course.title} » publié — visible dans Apprendre.',
          ),
        ),
      );
      context.go('/teacher');
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDec(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _fbMuted, fontSize: 15),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: _fbMuted, size: 22),
      filled: true,
      fillColor: _fbBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _fbBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final canPublish = !_loading && _title.text.trim().length >= 3;

    return Scaffold(
      backgroundColor: _fbBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: _fbInk),
        ),
        title: const Text(
          'Publier un cours',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: _fbInk,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: canPublish ? _submit : null,
              style: TextButton.styleFrom(
                backgroundColor: canPublish ? _fbBlue : const Color(0xFFE4E6EB),
                foregroundColor:
                    canPublish ? Colors.white : const Color(0xFFBCC0C4),
                disabledBackgroundColor: const Color(0xFFE4E6EB),
                disabledForegroundColor: const Color(0xFFBCC0C4),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Publier',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _fbBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // —— Composer infos cours
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AkadexColors.primarySoft,
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AkadexColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Enseignant',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: _fbInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if ((user?.faculty ?? '').isNotEmpty)
                                user!.faculty,
                              if ((user?.department ?? '').isNotEmpty)
                                user!.department,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _fbMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _fbInk,
                    height: 1.25,
                  ),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Titre du cours…',
                    hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A8D91),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                TextField(
                  controller: _description,
                  maxLines: null,
                  minLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    color: _fbInk,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Décris le cours en quelques lignes…',
                    hintStyle: TextStyle(fontSize: 16, color: _fbMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // —— Infos rapides
          _FbCard(
            title: 'Infos du cours',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: _fieldDec('Niveau de difficulté'),
                  items: [
                    for (final d in _difficulties)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _fieldDec(
                    'Code (optionnel)',
                    icon: Icons.qr_code_2_rounded,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _coverUrl,
                  keyboardType: TextInputType.url,
                  decoration: _fieldDec(
                    'URL image de couverture',
                    icon: Icons.image_outlined,
                  ),
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
                        decoration: _fieldDec(
                          'Crédits',
                          icon: Icons.toll_outlined,
                        ),
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
                        decoration: _fieldDec(
                          'Volume (h)',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Domaines & promotion (optionnel)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _fbMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sélectionnez ou tapez puis Entrée pour ajouter.',
                  style: TextStyle(fontSize: 12, color: _fbMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slug in _domainSlugs)
                      InputChip(
                        label: Text(_domainLabels[slug] ?? slug),
                        onDeleted: () => setState(() {
                          _domainSlugs.remove(slug);
                          _domainLabels.remove(slug);
                        }),
                      ),
                    if (_promotionName != null && _promotionName!.isNotEmpty)
                      InputChip(
                        label: Text('Promo · $_promotionName'),
                        onDeleted: () => setState(() {
                          _promotionId = null;
                          _promotionName = null;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagInput,
                  textInputAction: TextInputAction.done,
                  decoration: _fieldDec(
                    'Ex. Informatique, L3, Cybersécurité…',
                    icon: Icons.sell_outlined,
                  ),
                  onSubmitted: (_) => _commitTagInput(),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in LearnDomains.all)
                      FilterChip(
                        label: Text(d.shortLabel),
                        selected: _domainSlugs.contains(d.id),
                        showCheckmark: true,
                        selectedColor: _fbBlue,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _domainSlugs.contains(d.id)
                              ? Colors.white
                              : _fbInk,
                        ),
                        side: TimelineTokens.tabBorderSide,
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _domainSlugs.add(d.id);
                              _domainLabels[d.id] = d.name;
                            } else {
                              _domainSlugs.remove(d.id);
                              _domainLabels.remove(d.id);
                            }
                          });
                        },
                      ),
                    for (final p in _promotions.take(8))
                      FilterChip(
                        label: Text(p.name),
                        selected: _promotionId == p.id,
                        showCheckmark: true,
                        selectedColor: const Color(0xFF42B72A),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              _promotionId == p.id ? Colors.white : _fbInk,
                        ),
                        side: TimelineTokens.tabBorderSide,
                        backgroundColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _promotionId = p.id;
                              _promotionName = p.name;
                            } else if (_promotionId == p.id) {
                              _promotionId = null;
                              _promotionName = null;
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // —— Modules & leçons
          _FbCard(
            title: 'Contenu du cours',
            trailing: TextButton.icon(
              onPressed: _addModule,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Module'),
              style: TextButton.styleFrom(
                foregroundColor: _fbBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            child: Column(
              children: [
                for (var mi = 0; mi < _modules.length; mi++) ...[
                  if (mi > 0) const SizedBox(height: 14),
                  _ModuleBlock(
                    index: mi,
                    module: _modules[mi],
                    canRemove: _modules.length > 1,
                    fieldDec: _fieldDec,
                    lessonTypes: _lessonTypes,
                    onRemove: () => _removeModule(mi),
                    onAddLesson: () => _addLesson(mi),
                    onRemoveLesson: (li) => _removeLesson(mi, li),
                    onLessonType: (li, type) {
                      setState(() {
                        final lesson = _modules[mi].lessons[li];
                        lesson.contentType = type;
                        if (type == 'video') {
                          lesson.clearFile();
                        } else {
                          lesson.videoUrl.clear();
                        }
                      });
                    },
                    onLessonFile: (li, selection) {
                      setState(() {
                        final lesson = _modules[mi].lessons[li];
                        if (selection == null) {
                          lesson.clearFile();
                        } else {
                          lesson.fileBytes = selection.bytes;
                          lesson.fileName = selection.name;
                          lesson.filePath = selection.path;
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE41E3F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFE41E3F),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: canPublish ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _fbBlue,
                  disabledBackgroundColor: const Color(0xFFE4E6EB),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFFBCC0C4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publier le cours'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FbCard extends StatelessWidget {
  const _FbCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF050505),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ModuleBlock extends StatelessWidget {
  const _ModuleBlock({
    required this.index,
    required this.module,
    required this.canRemove,
    required this.fieldDec,
    required this.lessonTypes,
    required this.onRemove,
    required this.onAddLesson,
    required this.onRemoveLesson,
    required this.onLessonType,
    required this.onLessonFile,
  });

  final int index;
  final _DraftModule module;
  final bool canRemove;
  final InputDecoration Function(String hint, {IconData? icon}) fieldDec;
  final List<(String, String, IconData)> lessonTypes;
  final VoidCallback onRemove;
  final VoidCallback onAddLesson;
  final ValueChanged<int> onRemoveLesson;
  final void Function(int lessonIndex, String type) onLessonType;
  final void Function(int lessonIndex, FileDropSelection? selection)
      onLessonFile;

  static const _fbMuted = Color(0xFF65676B);
  static const _fbBlue = Color(0xFF0866FF);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBg = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _fbBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fbBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Module ${index + 1}',
                  style: const TextStyle(
                    color: _fbBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: _fbMuted,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: module.title,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDec(
              'Titre du module (ex. Introduction)',
              icon: Icons.folder_outlined,
            ),
          ),
          const SizedBox(height: 12),
          for (var li = 0; li < module.lessons.length; li++) ...[
            if (li > 0) const SizedBox(height: 10),
            _LessonBlock(
              index: li,
              lesson: module.lessons[li],
              canRemove: module.lessons.length > 1,
              fieldDec: fieldDec,
              lessonTypes: lessonTypes,
              onRemove: () => onRemoveLesson(li),
              onType: (t) => onLessonType(li, t),
              onFile: (selection) => onLessonFile(li, selection),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddLesson,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Ajouter une leçon'),
              style: TextButton.styleFrom(
                foregroundColor: _fbBlue,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({
    required this.index,
    required this.lesson,
    required this.canRemove,
    required this.fieldDec,
    required this.lessonTypes,
    required this.onRemove,
    required this.onType,
    required this.onFile,
  });

  final int index;
  final _DraftLesson lesson;
  final bool canRemove;
  final InputDecoration Function(String hint, {IconData? icon}) fieldDec;
  final List<(String, String, IconData)> lessonTypes;
  final VoidCallback onRemove;
  final ValueChanged<String> onType;
  final ValueChanged<FileDropSelection?> onFile;

  static const _fbMuted = Color(0xFF65676B);
  static const _fbInk = Color(0xFF050505);
  static const _fbBorder = Color(0xFFCED0D4);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _fbBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Leçon ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _fbInk,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: _fbMuted,
                ),
            ],
          ),
          TextField(
            controller: lesson.title,
            textCapitalization: TextCapitalization.sentences,
            decoration: fieldDec(
              'Titre de la leçon',
              icon: Icons.play_lesson_outlined,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in lessonTypes) ...[
                  ChoiceChip(
                    avatar: Icon(t.$3, size: 16),
                    label: Text(t.$2),
                    selected: lesson.contentType == t.$1,
                    onSelected: (_) => onType(t.$1),
                    selectedColor: const Color(0xFFE7F3FF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: lesson.contentType == t.$1
                          ? const Color(0xFF0866FF)
                          : _fbMuted,
                    ),
                    side: BorderSide(
                      color: lesson.contentType == t.$1
                          ? const Color(0xFF0866FF)
                          : _fbBorder,
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          if (lesson.contentType == 'video') ...[
            const SizedBox(height: 10),
            TextField(
              controller: lesson.videoUrl,
              keyboardType: TextInputType.url,
              decoration: fieldDec(
                'Lien vidéo (YouTube, Vimeo…)',
                icon: Icons.videocam_outlined,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            FileDropZone(
              allowedExtensions:
                  FileDropValidator.extensionsForLessonType(lesson.contentType),
              fileName: lesson.fileName,
              fileSize: lesson.fileBytes?.length,
              onChanged: onFile,
              title: 'Glisser-déposer le fichier de la leçon',
            ),
          ],
        ],
      ),
    );
  }
}
