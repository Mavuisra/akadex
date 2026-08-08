import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/role_access.dart';
import '../../data/auth/auth_repository.dart';
import '../../domain/models/models.dart';
import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/alumni/presentation/screens/alumni_profile_screen.dart';
import '../../features/alumni/presentation/screens/alumni_publish_screen.dart';
import '../../features/alumni/presentation/screens/alumni_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/community/presentation/screens/community_publish_screen.dart';
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/pdf_reader_screen.dart';
import '../../features/learn/presentation/screens/cart_screen.dart';
import '../../features/learn/presentation/screens/checkout_screen.dart';
import '../../features/learn/presentation/screens/domain_courses_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/learn/presentation/screens/learn_search_screen.dart';
import '../../features/learn/presentation/screens/mobile_money_screen.dart';
import '../../features/library/presentation/screens/contribute_screen.dart';
import '../../core/widgets/post_viewer_screens.dart';
import '../../features/library/presentation/screens/course_detail_screen.dart';
import '../../features/library/presentation/screens/document_detail_screen.dart';
import '../../features/library/presentation/screens/lesson_player_screen.dart';
import '../../features/library/presentation/screens/suggest_course_screen.dart';
import '../../features/ma_fac/presentation/screens/ma_fac_course_detail_screen.dart';
import '../../features/ma_fac/presentation/screens/ma_fac_docs_screen.dart';
import '../../features/ma_fac/presentation/screens/ma_fac_explore_screen.dart';
import '../../features/ma_fac/presentation/screens/ma_fac_screen.dart';
import '../../features/lmd/presentation/screens/lmd_assistant_screen.dart';
import '../../features/lmd/presentation/screens/lmd_guide_screen.dart';
import '../../features/messaging/presentation/screens/chat_screen.dart';
import '../../features/messaging/presentation/screens/conversations_screen.dart';
import '../../features/professor/presentation/screens/professor_create_course_screen.dart';
import '../../features/professor/presentation/screens/professor_course_manage_screen.dart';
import '../../features/professor/presentation/screens/professor_dashboard_screen.dart';
import '../../features/professor/presentation/screens/professor_hub_screen.dart';
import '../../features/professor/presentation/screens/professor_publish_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/my_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/rewards_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/shell/student_shell.dart';
import '../../features/shell/teacher_shell.dart';


/// Clés stables — ne jamais recréer le GoRouter ni ces GlobalKey.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _teacherShellKey =
    GlobalKey<StatefulNavigationShellState>(debugLabel: 'shell-teacher');
final _studentShellKey =
    GlobalKey<StatefulNavigationShellState>(debugLabel: 'shell-student');
final _tNav0 = GlobalKey<NavigatorState>(debugLabel: 't-nav-0');
final _tNav1 = GlobalKey<NavigatorState>(debugLabel: 't-nav-1');
final _tNav2 = GlobalKey<NavigatorState>(debugLabel: 't-nav-2');
final _tNav3 = GlobalKey<NavigatorState>(debugLabel: 't-nav-3');
final _sNav0 = GlobalKey<NavigatorState>(debugLabel: 's-nav-0');
final _sNav1 = GlobalKey<NavigatorState>(debugLabel: 's-nav-1');
final _sNav2 = GlobalKey<NavigatorState>(debugLabel: 's-nav-2');
final _sNav3 = GlobalKey<NavigatorState>(debugLabel: 's-nav-3');
final _sNav4 = GlobalKey<NavigatorState>(debugLabel: 's-nav-4');
final _sNav5 = GlobalKey<NavigatorState>(debugLabel: 's-nav-5');

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

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
  final refresh = _AuthRefresh(ref);

  // GoRouter créé UNE seule fois. Les deux shells ont des clés distinctes ;
  // RoleAccess redirige vers le bon shell selon le rôle.
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final user = ref.read(authStateProvider).valueOrNull;
      final role = user?.role;

      if (RoleAccess.isPublicLocation(loc)) {
        if (user != null && (loc == '/login' || loc == '/register')) {
          return RoleAccess.homeForRole(role);
        }
        return null;
      }

      if (!RoleAccess.canAccess(role: role, location: loc)) {
        return RoleAccess.redirectForDenied(role: role, location: loc);
      }

      if (loc == '/professor') return '/teacher';
      if (loc.startsWith('/professor/publish')) return '/teacher-publish';
      if (loc == '/explorer' || loc.startsWith('/explorer/')) return '/learn';

      return null;
    },
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
        key: _teacherShellKey,
        builder: (context, state, navigationShell) {
          return TeacherShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _tNav0,
            routes: [
              GoRoute(
                path: '/teacher',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ProfessorHubScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tNav1,
            routes: [
              GoRoute(
                path: '/teacher-publish',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ProfessorPublishScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tNav2,
            routes: [
              GoRoute(
                path: '/teacher-dashboard',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ProfessorDashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _tNav3,
            routes: [
              GoRoute(
                path: '/teacher-profile',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        key: _studentShellKey,
        builder: (context, state, navigationShell) {
          return StudentShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _sNav0,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sNav1,
            routes: [
              GoRoute(
                path: '/learn',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const LearnScreen()),
                routes: [
                  GoRoute(
                    path: 'search',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      const LearnSearchScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'domain/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      DomainCoursesScreen(
                        domainId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sNav2,
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const MaFacScreen()),
                routes: [
                  GoRoute(
                    path: 'docs/:categoryId',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      MaFacDocsScreen(
                        categoryId: state.pathParameters['categoryId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'courses',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      const MaFacCoursesScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'explore',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final q = state.uri.queryParameters;
                      return _cupertino(
                        state,
                        MaFacExploreScreen(
                          departmentId: q['departmentId'] ?? '',
                          departmentName: q['departmentName'] ?? '',
                          promotionId: q['promotionId'] ?? '',
                          promotionName: q['promotionName'] ?? '',
                          facultyName: q['facultyName'] ?? '',
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'ue/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => _cupertino(
                      state,
                      MaFacCourseDetailScreen(
                        courseId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sNav3,
            routes: [
              GoRoute(
                path: '/community',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const CommunityScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sNav4,
            routes: [
              GoRoute(
                path: '/alumni',
                pageBuilder: (context, state) =>
                    _fadeSlide(state, const AlumniScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sNav5,
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
        path: '/library/course/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          CourseDetailScreen(courseId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const CartScreen()),
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/checkout/mobile-money',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const MobileMoneyScreen()),
      ),
      GoRoute(
        path: '/library/document/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          DocumentDetailScreen(documentId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/library/lesson/:id/play',
        parentNavigatorKey: _rootNavigatorKey,
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
              modules:
                  (extra?['modules'] as List<CourseModuleItem>?) ?? const [],
              courseTitle: (extra?['courseTitle'] ?? '').toString(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/lmd',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const LmdGuideScreen()),
      ),
      GoRoute(
        path: '/lmd/assistant',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const LmdAssistantScreen()),
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const SearchScreen()),
      ),
      GoRoute(
        path: '/ai',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const AiAssistantScreen()),
      ),
      GoRoute(
        path: '/calendar',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const CalendarScreen()),
      ),
      GoRoute(
        path: '/rewards',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const RewardsScreen()),
      ),
      GoRoute(
        path: '/contribute',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const ContributeScreen()),
      ),
      GoRoute(
        path: '/contribute/course',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const SuggestCourseScreen()),
      ),
      GoRoute(
        path: '/teacher-course',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const ProfessorCreateCourseScreen()),
      ),
      GoRoute(
        path: '/teacher-course/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          ProfessorCourseManageScreen(
            courseId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/my-contributions',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const MyContributionsScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/profile/me',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const MyProfileScreen()),
      ),
      GoRoute(
        path: '/alumni/profile/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          AlumniProfileScreen(
            userId: state.pathParameters['id']!,
            focusDocumentId: state.uri.queryParameters['doc'],
            focusPostId: state.uri.queryParameters['post'],
          ),
        ),
      ),
      GoRoute(
        path: '/alumni/publish',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const AlumniPublishScreen()),
      ),
      GoRoute(
        path: '/community/publish',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          return CommunityPublishScreen(
            editingPost: extra is CommunityPost ? extra : null,
          );
        },
      ),
      GoRoute(
        path: '/posts/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! CommunityPost) {
            return _cupertino(
              state,
              const Scaffold(
                body: Center(child: Text('Publication introuvable')),
              ),
            );
          }
          return _cupertino(state, TextPostViewerScreen(post: extra));
        },
      ),
      GoRoute(
        path: '/posts/:id/media',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra is! CommunityPost) {
            return _cupertino(
              state,
              const Scaffold(
                body: Center(child: Text('Publication introuvable')),
              ),
            );
          }
          return _cupertino(state, MediaPostViewerScreen(post: extra));
        },
      ),
      GoRoute(
        path: '/pdf-reader',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          var url = '';
          var title = 'Document';
          if (extra is Map) {
            url = (extra['url'] ?? '').toString();
            title = (extra['title'] ?? 'Document').toString();
          }
          return _cupertino(
            state,
            PdfReaderScreen(url: url, title: title),
          );
        },
      ),
      GoRoute(
        path: '/messages',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _cupertino(state, const ConversationsScreen()),
      ),
      GoRoute(
        path: '/messages/chat/:id',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          ChatScreen(conversationId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/messages/with/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _cupertino(
          state,
          StartConversationScreen(userId: state.pathParameters['userId']!),
        ),
      ),
      GoRoute(
        path: '/professor',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/teacher',
      ),
      GoRoute(
        path: '/professor/publish',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => '/teacher-publish',
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
