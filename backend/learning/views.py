from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from academic.models import Course

from .models import CourseComment, CourseLesson, CourseModule, LessonProgress
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
        ).prefetch_related(
            'teachers',
            'modules__lessons',
        )


class CourseModuleViewSet(viewsets.ModelViewSet):
    serializer_class = CourseModuleSerializer
    permission_classes = [IsTeacherOrReadOnly]
    filterset_fields = ['course']

    def get_queryset(self):
        return CourseModule.objects.prefetch_related('lessons').select_related('course')


class CourseLessonViewSet(viewsets.ModelViewSet):
    serializer_class = CourseLessonSerializer
    permission_classes = [IsTeacherOrReadOnly]
    filterset_fields = ['module', 'module__course', 'content_type', 'is_published']

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
        lesson = self.get_object()
        position = int(request.data.get('position_seconds', 0) or 0)
        completed = bool(request.data.get('completed', False))
        prog, _ = LessonProgress.objects.update_or_create(
            user=request.user,
            lesson=lesson,
            defaults={
                'position_seconds': max(0, position),
                'completed': completed,
            },
        )
        return Response(LessonProgressSerializer(prog).data)


class CourseCommentViewSet(viewsets.ModelViewSet):
    serializer_class = CourseCommentSerializer
    filterset_fields = ['course', 'lesson', 'parent']

    def get_queryset(self):
        return CourseComment.objects.select_related('author', 'course', 'lesson')

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

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
