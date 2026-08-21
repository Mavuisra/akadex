from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from academic.models import Course

from .events import record_learning_event
from .models import (
    CourseComment,
    CourseLesson,
    CourseModule,
    LessonProgress,
    StudentLearningEvent,
)
from .serializers import (
    CourseCommentSerializer,
    CourseLessonSerializer,
    CourseModuleSerializer,
    CourseOutlineSerializer,
    LessonProgressSerializer,
)


class IsTeacherOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        user = request.user
        return bool(
            user
            and user.is_authenticated
            and (user.is_staff or getattr(user, 'role', '') in ('teacher', 'admin'))
        )


class CourseOutlineViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CourseOutlineSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Course.objects.select_related(
            'department',
            'department__faculty',
            'department__faculty__university',
            'promotion',
        ).prefetch_related(
            'teachers',
            'domains',
            'modules__lessons',
        )

    def retrieve(self, request, *args, **kwargs):
        from .visits import record_course_visit

        instance = self.get_object()
        # Visite réelle uniquement (étudiant) — ignore aperçu enseignant / anonyme.
        record_course_visit(instance, request)
        if request.user.is_authenticated:
            record_learning_event(
                student=request.user,
                course=instance,
                event_type=StudentLearningEvent.EventType.COURSE_OPENED,
                throttle_seconds=3600,
            )
        serializer = self.get_serializer(instance)
        return Response(serializer.data)


class CourseModuleViewSet(viewsets.ModelViewSet):
    serializer_class = CourseModuleSerializer
    permission_classes = [IsTeacherOrReadOnly]
    filterset_fields = ['course']
    search_fields = ['title', 'description', 'course__title', 'course__code']

    def get_queryset(self):
        return CourseModule.objects.select_related('course')


class CourseLessonViewSet(viewsets.ModelViewSet):
    serializer_class = CourseLessonSerializer
    permission_classes = [IsTeacherOrReadOnly]
    filterset_fields = ['module', 'content_type', 'is_published']
    search_fields = ['title', 'description']

    def get_queryset(self):
        qs = CourseLesson.objects.select_related('module', 'module__course')
        user = self.request.user
        if user.is_authenticated and (
            user.is_staff or getattr(user, 'role', '') in ('teacher', 'admin')
        ):
            return qs
        return qs.filter(is_published=True)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def progress(self, request, pk=None):
        from .visits import is_real_learner

        lesson = self.get_object()
        course = lesson.module.course
        position = int(request.data.get('position_seconds', 0) or 0)
        completed = bool(request.data.get('completed', False))
        position = max(0, position)

        # Enseignant / propriétaire : pas de progression pédagogique stockée.
        if not is_real_learner(request.user, course):
            return Response({
                'id': None,
                'lesson': lesson.id,
                'position_seconds': position,
                'completed': completed,
                'updated_at': None,
                'tracked': False,
            })

        created = False
        try:
            prog = LessonProgress.objects.get(user=request.user, lesson=lesson)
            was_completed = prog.completed
            prev_pos = prog.position_seconds
        except LessonProgress.DoesNotExist:
            prog = None
            was_completed = False
            prev_pos = 0
            created = True

        prog, _ = LessonProgress.objects.update_or_create(
            user=request.user,
            lesson=lesson,
            defaults={
                'position_seconds': position,
                'completed': completed or was_completed,
            },
        )
        completed = prog.completed

        # Première interaction = ouverture de contenu (+ démarrage vidéo).
        if created or prev_pos == 0:
            record_learning_event(
                student=request.user,
                course=course,
                lesson=lesson,
                event_type=StudentLearningEvent.EventType.CONTENT_OPENED,
                event_data={'content_type': lesson.content_type},
                throttle_seconds=600,
            )
            if lesson.content_type == 'video':
                record_learning_event(
                    student=request.user,
                    course=course,
                    lesson=lesson,
                    event_type=StudentLearningEvent.EventType.VIDEO_STARTED,
                    event_data={'position_seconds': position},
                    throttle_seconds=600,
                )
            elif lesson.content_type in (
                'pdf',
                'slides',
                'book',
                'document',
            ):
                record_learning_event(
                    student=request.user,
                    course=course,
                    lesson=lesson,
                    event_type=StudentLearningEvent.EventType.DOCUMENT_OPENED,
                    event_data={'content_type': lesson.content_type},
                    throttle_seconds=600,
                )

        # Progression vidéo (throttle 30 s côté serveur).
        if lesson.content_type == 'video' and position > 0 and not completed:
            if abs(position - prev_pos) >= 15 or created:
                record_learning_event(
                    student=request.user,
                    course=course,
                    lesson=lesson,
                    event_type=StudentLearningEvent.EventType.VIDEO_PROGRESS,
                    event_data={'position_seconds': position},
                    throttle_seconds=30,
                )

        if completed and not was_completed:
            if lesson.content_type == 'video':
                record_learning_event(
                    student=request.user,
                    course=course,
                    lesson=lesson,
                    event_type=StudentLearningEvent.EventType.VIDEO_COMPLETED,
                    event_data={'position_seconds': position},
                )
            record_learning_event(
                student=request.user,
                course=course,
                lesson=lesson,
                event_type=StudentLearningEvent.EventType.LESSON_COMPLETED,
                event_data={
                    'content_type': lesson.content_type,
                    'position_seconds': position,
                },
            )

        return Response(LessonProgressSerializer(prog).data)


class CourseCommentViewSet(viewsets.ModelViewSet):
    serializer_class = CourseCommentSerializer
    filterset_fields = ['course', 'lesson', 'parent']

    def get_queryset(self):
        return CourseComment.objects.select_related('author', 'course', 'lesson')

    def perform_create(self, serializer):
        comment = serializer.save(author=self.request.user)
        record_learning_event(
            student=self.request.user,
            course=comment.course,
            lesson=comment.lesson,
            event_type=StudentLearningEvent.EventType.COURSE_COMMENTED,
            event_data={'comment_id': comment.id},
            throttle_seconds=5,
        )

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]


class LessonProgressViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = LessonProgressSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['lesson', 'completed']

    def get_queryset(self):
        return LessonProgress.objects.filter(user=self.request.user)
