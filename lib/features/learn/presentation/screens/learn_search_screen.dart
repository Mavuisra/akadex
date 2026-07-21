import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';
import '../../data/learn_domains.dart';
import '../widgets/course_udemy_card.dart';

/// Recherche unifiée : domaines, cours et modules.
class LearnSearchScreen extends ConsumerStatefulWidget {
  const LearnSearchScreen({super.key});

  @override
  ConsumerState<LearnSearchScreen> createState() => _LearnSearchScreenState();
}

class _LearnSearchScreenState extends ConsumerState<LearnSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;
  List<CourseModuleItem> _modules = const [];
  bool _modulesLoading = false;
  String? _modulesError;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), _loadModules);
  }

  Future<void> _loadModules() async {
    final q = _query;
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _modules = const [];
          _modulesLoading = false;
          _modulesError = null;
        });
      }
      return;
    }
    setState(() {
      _modulesLoading = true;
      _modulesError = null;
    });
    try {
      final list =
          await ref.read(academicRepositoryProvider).searchModules(q);
      if (!mounted || _query != q) return;
      setState(() {
        _modules = list;
        _modulesLoading = false;
      });
    } catch (_) {
      if (!mounted || _query != q) return;
      setState(() {
        _modules = const [];
        _modulesLoading = false;
        _modulesError = 'Modules indisponibles pour le moment.';
      });
    }
  }

  List<LearnDomain> _filterDomains(String q) {
    if (q.isEmpty) return LearnDomains.all;
    final lower = q.toLowerCase();
    return LearnDomains.all.where((d) {
      final hay = [
        d.name,
        d.shortLabel,
        ...d.keywords,
      ].join(' ').toLowerCase();
      return hay.contains(lower);
    }).toList();
  }

  List<Course> _filterCourses(List<Course> courses, String q) {
    if (q.isEmpty) {
      return courses.where((c) => c.code.startsWith('AKX-')).take(8).toList();
    }
    final lower = q.toLowerCase();
    final matched = courses.where((c) {
      final hay = [
        c.title,
        c.code,
        c.displayTeacher,
        c.faculty,
        c.department,
        c.targetPromotion,
        c.university,
        c.description,
        ...c.academicTags,
      ].join(' ').toLowerCase();
      return hay.contains(lower);
    }).toList();
    matched.sort((a, b) {
      final at = a.title.toLowerCase().startsWith(lower) ? 0 : 1;
      final bt = b.title.toLowerCase().startsWith(lower) ? 0 : 1;
      if (at != bt) return at.compareTo(bt);
      final af = a.code.startsWith('AKX-') ? 0 : 1;
      final bf = b.code.startsWith('AKX-') ? 0 : 1;
      return af.compareTo(bf);
    });
    return matched.take(40).toList();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final q = _query;
    final domains = _filterDomains(q);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Rechercher',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchField(
              hint: 'Cours, module ou domaine…',
              controller: _controller,
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: coursesAsync.when(
              loading: () =>
                  const Center(child: CupertinoActivityIndicator()),
              error: (e, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(coursesProvider),
                  child: const Text('Réessayer'),
                ),
              ),
              data: (courses) {
                final filteredCourses = _filterCourses(courses, q);
                final showEmpty = q.isNotEmpty &&
                    domains.isEmpty &&
                    filteredCourses.isEmpty &&
                    _modules.isEmpty &&
                    !_modulesLoading;

                if (showEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun résultat pour cette recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AkadexColors.inkMuted),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
                  children: [
                    if (domains.isNotEmpty) ...[
                      _SectionTitle(
                        q.isEmpty ? 'Domaines' : 'Domaines',
                      ),
                      SizedBox(
                        height: 108,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: domains.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final d = domains[i];
                            return _DomainChip(
                              domain: d,
                              onTap: () =>
                                  context.push('/learn/domain/${d.id}'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (filteredCourses.isNotEmpty) ...[
                      _SectionTitle(
                        q.isEmpty ? 'Cours suggérés' : 'Cours',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            for (final c in filteredCourses) ...[
                              CourseUdemyCard(course: c),
                              const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (q.length >= 2) ...[
                      const _SectionTitle('Modules'),
                      if (_modulesLoading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CupertinoActivityIndicator()),
                        )
                      else if (_modulesError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _modulesError!,
                            style: const TextStyle(
                              color: AkadexColors.inkMuted,
                            ),
                          ),
                        )
                      else if (_modules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Aucun module trouvé.',
                            style: TextStyle(color: AkadexColors.inkMuted),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              for (final m in _modules)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: SoftCard(
                                    onTap: () {
                                      final id = m.courseId;
                                      if (id.isEmpty) return;
                                      context.push('/library/course/$id');
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: AkadexColors.primarySoft,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.view_module_outlined,
                                            color: AkadexColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                m.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (m.courseTitle.isNotEmpty)
                                                Text(
                                                  m.courseTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        AkadexColors.inkMuted,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AkadexColors.inkSoft,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2F31),
        ),
      ),
    );
  }
}

class _DomainChip extends StatelessWidget {
  const _DomainChip({required this.domain, required this.onTap});

  final LearnDomain domain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 118,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: domain.colors,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(domain.icon, color: Colors.white, size: 22),
                const Spacer(),
                Text(
                  domain.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
