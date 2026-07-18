import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/models.dart';
import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/alumni/presentation/screens/alumni_publish_screen.dart';
import '../../features/alumni/presentation/screens/alumni_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/library/presentation/screens/course_detail_screen.dart';
import '../../features/library/presentation/screens/document_detail_screen.dart';
import '../../features/library/presentation/screens/lesson_player_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/professor/presentation/screens/professor_hub_screen.dart';
import '../../features/professor/presentation/screens/professor_publish_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/rewards_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/shell/main_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

CupertinoPage<void> _cupertino(GoRouterState state, Widget child) {
  return CupertinoPage<void>(
    key: state.pageKey,
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeSlide(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _cupertino(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _cupertino(state, const RegisterScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explorer',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ExplorerScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const LibraryScreen()),
                routes: [
                  GoRoute(
                    path: 'course/:id',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      CourseDetailScreen(
                        courseId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'document/:id',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      DocumentDetailScreen(
                        documentId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'lesson/:id/play',
                    parentNavigatorKey: _rootKey,
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      final lesson = extra?['lesson'] as CourseLessonItem?;
                      if (lesson == null) {
                        return _cupertino(
                          state,
                          const Scaffold(
                            body: Center(child: Text('Leçon introuvable')),
                          ),
                        );
                      }
                      return _cupertino(
                        state,
                        LessonPlayerScreen(
                          lessonId: state.pathParameters['id']!,
                          lesson: lesson,
                          courseId: (extra?['courseId'] ?? '').toString(),
                          modules: (extra?['modules'] as List<CourseModuleItem>?) ??
                              const [],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const CommunityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alumni',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const AlumniScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const SearchScreen()),
      ),
      GoRoute(
        path: '/ai',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const AiAssistantScreen()),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const CalendarScreen()),
      ),
      GoRoute(
        path: '/rewards',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const RewardsScreen()),
      ),
      GoRoute(
        path: '/alumni/publish',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const AlumniPublishScreen()),
      ),
      GoRoute(
        path: '/professor',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const ProfessorHubScreen()),
      ),
      GoRoute(
        path: '/professor/publish',
        parentNavigatorKey: _rootKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const ProfessorPublishScreen()),
      ),
    ],
  );
});
