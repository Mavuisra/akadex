from django.db.models import F, Q
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    Department,
    Document,
    DocumentComment,
    Faculty,
    Favorite,
    Promotion,
    University,
)
from .serializers import (
    AnnouncementSerializer,
    CalendarEventSerializer,
    CampusSerializer,
    CourseSerializer,
    DepartmentSerializer,
    DocumentCommentSerializer,
    DocumentSerializer,
    FacultySerializer,
    FavoriteSerializer,
    PromotionSerializer,
    UniversitySerializer,
)


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        author = getattr(obj, 'author', None)
        return author == request.user or request.user.is_staff


class UniversityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = University.objects.filter(is_active=True)
    serializer_class = UniversitySerializer
    lookup_field = 'slug'
    search_fields = ['name', 'city', 'country']


class CampusViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Campus.objects.select_related('university')
    serializer_class = CampusSerializer
    filterset_fields = ['university']


class FacultyViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Faculty.objects.select_related('university', 'campus')
    serializer_class = FacultySerializer
    filterset_fields = ['university', 'campus']
    search_fields = ['name']


class DepartmentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Department.objects.select_related('faculty', 'faculty__university')
    serializer_class = DepartmentSerializer
    filterset_fields = ['faculty', 'faculty__university']
    search_fields = ['name']


class PromotionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Promotion.objects.select_related('department')
    serializer_class = PromotionSerializer
    filterset_fields = ['department', 'year', 'level']


class CourseViewSet(viewsets.ModelViewSet):
    queryset = Course.objects.select_related('department').prefetch_related('teachers')
    serializer_class = CourseSerializer
    filterset_fields = ['department', 'semester', 'department__faculty']
    search_fields = ['code', 'title', 'description']
    ordering_fields = ['code', 'title', 'credits', 'created_at']

    def get_permissions(self):
        if self.action in ('create', 'update', 'partial_update', 'destroy'):
            return [permissions.IsAdminUser()]
        return [permissions.AllowAny()]


class DocumentViewSet(viewsets.ModelViewSet):
    serializer_class = DocumentSerializer
    filterset_fields = [
        'doc_type',
        'university',
        'department',
        'course',
        'academic_year',
        'is_featured',
    ]
    search_fields = ['title', 'description', 'author__first_name', 'author__last_name']
    ordering_fields = ['created_at', 'downloads', 'views', 'rating_avg', 'favorites_count']

    def get_queryset(self):
        qs = Document.objects.select_related(
            'author',
            'university',
            'department',
            'course',
        )
        user = self.request.user
        if user.is_authenticated and user.is_staff:
            return qs
        if user.is_authenticated:
            return qs.filter(Q(is_approved=True) | Q(author=user)).distinct()
        return qs.filter(is_approved=True)

    def get_permissions(self):
        if self.action in ('list', 'retrieve', 'download', 'view'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        doc = serializer.save(author=self.request.user, is_approved=False)
        user = self.request.user
        user.contributions_count = F('contributions_count') + 1
        user.reputation = F('reputation') + 10
        user.save(update_fields=['contributions_count', 'reputation'])
        user.refresh_from_db()
        return doc

    @action(detail=True, methods=['post'])
    def view(self, request, pk=None):
        doc = self.get_object()
        Document.objects.filter(pk=doc.pk).update(views=F('views') + 1)
        doc.refresh_from_db()
        return Response(DocumentSerializer(doc, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def download(self, request, pk=None):
        doc = self.get_object()
        Document.objects.filter(pk=doc.pk).update(downloads=F('downloads') + 1)
        doc.refresh_from_db()
        return Response(
            {
                'file': request.build_absolute_uri(doc.file.url) if doc.file else None,
                'external_url': doc.external_url or None,
                'downloads': doc.downloads,
            }
        )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def favorite(self, request, pk=None):
        doc = self.get_object()
        fav, created = Favorite.objects.get_or_create(user=request.user, document=doc)
        if created:
            Document.objects.filter(pk=doc.pk).update(
                favorites_count=F('favorites_count') + 1
            )
            return Response({'favorited': True}, status=status.HTTP_201_CREATED)
        fav.delete()
        Document.objects.filter(pk=doc.pk).update(
            favorites_count=F('favorites_count') - 1
        )
        return Response({'favorited': False})


class DocumentCommentViewSet(viewsets.ModelViewSet):
    serializer_class = DocumentCommentSerializer
    filterset_fields = ['document']

    def get_queryset(self):
        return DocumentComment.objects.select_related('author', 'document')

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related(
            'document',
            'document__author',
            'document__university',
            'document__course',
        )

    def perform_create(self, serializer):
        fav = serializer.save(user=self.request.user)
        Document.objects.filter(pk=fav.document_id).update(
            favorites_count=F('favorites_count') + 1
        )


class AnnouncementViewSet(viewsets.ModelViewSet):
    serializer_class = AnnouncementSerializer
    filterset_fields = ['university', 'category']
    search_fields = ['title', 'body']

    def get_queryset(self):
        qs = Announcement.objects.select_related('university', 'author')
        if self.request.user.is_staff:
            return qs
        return qs.filter(is_published=True)

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [permissions.AllowAny()]
        return [permissions.IsAdminUser()]

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class CalendarEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CalendarEvent.objects.select_related('university')
    serializer_class = CalendarEventSerializer
    filterset_fields = ['university', 'event_type']
    search_fields = ['title', 'description', 'location']
    ordering_fields = ['starts_at']
