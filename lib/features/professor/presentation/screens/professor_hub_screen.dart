import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/akadex_theme.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/auth/auth_repository.dart';
import '../../../../data/repositories/repositories.dart';
import '../../../../domain/models/models.dart';

/// Hub enseignant — style feed Facebook.
class ProfessorHubScreen extends ConsumerWidget {
  const ProfessorHubScreen({super.key});

  static const _fbBg = Color(0xFFF0F2F5);
  static const _fbInk = Color(0xFF050505);
  static const _fbMuted = Color(0xFF65676B);
  static const _fbBorder = Color(0xFFCED0D4);
  static const _fbBlue = Color(0xFF0866FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      backgroundColor: _fbBg,
      body: auth.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text(apiErrorMessage(e))),
        data: (user) {
          if (user == null) {
            return Center(
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Se connecter'),
              ),
            );
          }
          if (!user.usesTeacherShell) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Espace réservé aux enseignants.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SafeArea(
            child: RefreshIndicator(
              color: _fbBlue,
              onRefresh: () async {
                await ref.read(coursesProvider.notifier).refresh();
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE7F3FF),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _fbBlue,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour ${user.name.split(' ').first}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: _fbInk,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (user.department.isNotEmpty)
                                    user.department,
                                  if (user.university.isNotEmpty)
                                    user.university,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _fbMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: _fbBorder),
                  const SizedBox(height: 8),
                  _FbAction(
                    icon: Icons.add_box_outlined,
                    iconColor: _fbBlue,
                    title: 'Publier un cours',
                    subtitle: 'Modules, leçons et vidéos',
                    onTap: () => context.push('/teacher-course'),
                  ),
                  _FbAction(
                    icon: Icons.insights_rounded,
                    iconColor: const Color(0xFFF7B928),
                    title: 'Tableau de bord',
                    subtitle: 'Visites, étudiants et graphiques',
                    onTap: () => context.go('/teacher-dashboard'),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: const Text(
                      'Tes cours',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _fbInk,
                      ),
                    ),
                  ),
                  coursesAsync.when(
                    loading: () => Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                    error: (e, _) => Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Text(apiErrorMessage(e)),
                    ),
                    data: (courses) {
                      final mine = _teacherCourses(courses, user);
                      if (mine.isEmpty) {
                        return Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'Aucun cours pour l’instant.',
                                style: TextStyle(color: _fbMuted),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () =>
                                    context.push('/teacher-course'),
                                style: TextButton.styleFrom(
                                  backgroundColor: _fbBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Créer mon premier cours',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final c in mine)
                            _CourseTile(
                              course: c,
                              onTap: () => context.push(
                                '/teacher-course/${c.id}',
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Course> _teacherCourses(List<Course> courses, UserProfile user) {
    final uid = user.id;
    final name = user.name.toLowerCase();
    final tokens = name.split(' ').where((p) => p.length > 1).toList();
    final mine = courses.where((c) {
      if (uid.isNotEmpty && c.submittedById == uid) return true;
      final hay = [
        c.teacher,
        c.displayTeacher,
        c.teacherFullName,
        c.submittedByName,
      ].join(' ').toLowerCase();
      if (tokens.any((t) => hay.contains(t))) return true;
      // Publication web/mobile enseignant : même fac + code ENS.
      if (c.code.startsWith('ENS-') &&
          user.faculty.isNotEmpty &&
          c.faculty.toLowerCase().contains(
                user.faculty.toLowerCase().split(' ').firstWhere(
                      (w) => w.length > 2,
                      orElse: () => user.faculty.toLowerCase(),
                    ),
              )) {
        return true;
      }
      return false;
    }).toList();
    if (mine.isNotEmpty) return mine.take(40).toList();
    return courses.where((c) => !c.code.startsWith('AKX-')).take(40).toList();
  }
}

class _FbAction extends StatelessWidget {
  const _FbAction({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFCED0D4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF050505),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF65676B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFCED0D4), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AkadexColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF0866FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF050505),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${course.code} · ${course.semester}'
                      '${course.views > 0 ? ' · ${course.views} vues' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF65676B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF65676B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
