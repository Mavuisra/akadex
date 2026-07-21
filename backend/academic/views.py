from django.db.models import Count, F, Q
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from academic.rewards import WHEEL_UNLOCK_POINTS

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
    RewardPrize,
    RewardRedemption,
    University,
)
from .serializers import (
    AnnouncementSerializer,
    CalendarEventSerializer,
    CampusSerializer,
    CourseListSerializer,
    CourseSerializer,
    DepartmentSerializer,
    DocumentCommentSerializer,
    DocumentSerializer,
    FacultySerializer,
    FavoriteSerializer,
    PromotionSerializer,
    RewardPrizeSerializer,
    RewardRedemptionSerializer,
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
    pagination_class = None


class CampusViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Campus.objects.select_related('university')
    serializer_class = CampusSerializer
    filterset_fields = ['university']
    pagination_class = None


class FacultyViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Faculty.objects.select_related('university', 'campus')
    serializer_class = FacultySerializer
    filterset_fields = ['university', 'campus']
    search_fields = ['name']
    pagination_class = None


class DepartmentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Department.objects.select_related('faculty', 'faculty__university')
    serializer_class = DepartmentSerializer
    filterset_fields = ['faculty', 'faculty__university']
    search_fields = ['name']
    pagination_class = None


class PromotionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Promotion.objects.select_related('department')
    serializer_class = PromotionSerializer
    filterset_fields = ['department', 'year', 'level']
    pagination_class = None


class CourseViewSet(viewsets.ModelViewSet):
    serializer_class = CourseSerializer
    filterset_fields = ['department', 'semester', 'department__faculty']
    search_fields = ['code', 'title', 'description']
    ordering_fields = ['code', 'title', 'credits', 'created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return CourseListSerializer
        return CourseSerializer

    def get_queryset(self):
        return (
            Course.objects.select_related(
                'department',
                'department__faculty',
                'department__faculty__university',
            )
            .prefetch_related('teachers')
            .annotate(
                approved_document_count=Count(
                    'documents',
                    filter=Q(documents__is_approved=True),
                    distinct=True,
                )
            )
        )

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
        'department__faculty',
        'course',
        'academic_year',
        'is_featured',
        'author',
        'moderation_status',
        'is_approved',
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
        doc = serializer.save(
            author=self.request.user,
            is_approved=False,
            moderation_status='pending',
        )
        user = self.request.user
        user.contributions_count = F('contributions_count') + 1
        user.save(update_fields=['contributions_count'])
        user.refresh_from_db()
        return doc

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        doc = self.get_object()
        doc.is_approved = True
        doc.moderation_status = 'approved'
        doc.rejection_reason = ''
        doc.save()
        return Response(DocumentSerializer(doc, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        from accounts.models import AppNotification

        doc = self.get_object()
        reason = (request.data.get('reason') or '').strip()
        doc.is_approved = False
        doc.moderation_status = 'rejected'
        doc.rejection_reason = reason
        doc.save(
            update_fields=[
                'is_approved',
                'moderation_status',
                'rejection_reason',
                'updated_at',
            ]
        )
        if doc.author_id:
            AppNotification.objects.create(
                user_id=doc.author_id,
                kind=AppNotification.Kind.DOCUMENT_REJECTED,
                title='Contribution refusée',
                message=(
                    f'Votre contribution « {doc.title} » a été refusée.'
                    + (f' Motif : {reason}' if reason else '')
                ),
            )
        return Response({'status': 'rejected'})

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


class RewardPrizeViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = RewardPrizeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return RewardPrize.objects.filter(is_active=True)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def status(self, request):
        user = request.user
        unlock = WHEEL_UNLOCK_POINTS
        return Response(
            {
                'points': user.reputation,
                'unlock_points': unlock,
                'can_spin': user.reputation >= unlock,
                'history': RewardRedemptionSerializer(
                    RewardRedemption.objects.filter(user=user).select_related('prize')[:20],
                    many=True,
                ).data,
            }
        )

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def spin(self, request):
        import random

        user = request.user
        if user.reputation < WHEEL_UNLOCK_POINTS:
            return Response(
                {
                    'detail': (
                        f'Il te faut au moins {WHEEL_UNLOCK_POINTS} points '
                        'pour tourner la roue.'
                    ),
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        prizes = list(
            RewardPrize.objects.filter(
                is_active=True,
                min_points__lte=user.reputation,
            )
        )
        if not prizes:
            return Response(
                {'detail': 'Aucune récompense disponible.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Coût : celui du prix le moins cher éligible (ou 100)
        cost = min(p.points_cost for p in prizes)
        if user.reputation < cost:
            return Response(
                {'detail': 'Points insuffisants pour un tour.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        weights = [max(1, p.weight) for p in prizes]
        prize = random.choices(prizes, weights=weights, k=1)[0]
        cost = prize.points_cost
        if user.reputation < cost:
            return Response(
                {'detail': 'Points insuffisants pour cette récompense.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user.reputation = F('reputation') - cost
        user.save(update_fields=['reputation'])
        user.refresh_from_db()

        redemption = RewardRedemption.objects.create(
            user=user,
            prize=prize,
            points_spent=cost,
        )
        return Response(
            {
                'prize': RewardPrizeSerializer(prize).data,
                'points_spent': cost,
                'points_remaining': user.reputation,
                'redemption_id': redemption.id,
            }
        )
