from django.db.models import Count, F, Q
from django.utils import timezone
from datetime import timedelta
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response

from .rewards import WHEEL_SPIN_COST, WHEEL_UNLOCK_POINTS

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    CourseValidationLog,
    Department,
    Document,
    DocumentComment,
    Faculty,
    Favorite,
    LearningDomain,
    Promotion,
    RewardPrize,
    RewardRedemption,
    University,
)
from .serializers import (
    AnnouncementSerializer,
    CalendarEventSerializer,
    CampusSerializer,
    CourseContributeSerializer,
    CourseListSerializer,
    CourseSerializer,
    DepartmentSerializer,
    DocumentCommentSerializer,
    DocumentSerializer,
    FacultySerializer,
    FavoriteSerializer,
    LearningDomainSerializer,
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


class LearningDomainViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = LearningDomainSerializer
    lookup_field = 'slug'
    pagination_class = None
    search_fields = ['name', 'slug', 'keywords']

    def get_queryset(self):
        return LearningDomain.objects.filter(is_active=True)


class CourseViewSet(viewsets.ModelViewSet):
    serializer_class = CourseSerializer
    filterset_fields = [
        'department',
        'semester',
        'department__faculty',
        'moderation_status',
        'is_approved',
        'submitted_by',
        'domains',
        'domains__slug',
        'promotion',
    ]
    search_fields = ['code', 'title', 'description', 'teacher_name']
    ordering_fields = ['code', 'title', 'credits', 'created_at', 'updated_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return CourseListSerializer
        if self.action == 'create':
            return CourseContributeSerializer
        return CourseSerializer

    def get_queryset(self):
        qs = (
            Course.objects.select_related(
                'department',
                'department__faculty',
                'department__faculty__university',
                'promotion',
                'submitted_by',
                'validated_by',
            )
            .prefetch_related('teachers', 'domains', 'validation_logs')
            .annotate(
                approved_document_count=Count(
                    'documents',
                    filter=Q(documents__is_approved=True),
                    distinct=True,
                )
            )
        )
        user = self.request.user
        if user.is_authenticated and user.is_staff:
            return qs
        # Spec : pending visible partout avec badge ; rejetés = auteur seulement.
        if user.is_authenticated:
            return qs.filter(
                Q(moderation_status__in=[
                    Course.ModerationStatus.APPROVED,
                    Course.ModerationStatus.PENDING,
                    Course.ModerationStatus.CHANGES_REQUESTED,
                ])
                | Q(submitted_by=user)
            ).distinct()
        return qs.filter(
            moderation_status__in=[
                Course.ModerationStatus.APPROVED,
                Course.ModerationStatus.PENDING,
                Course.ModerationStatus.CHANGES_REQUESTED,
            ]
        )

    def get_permissions(self):
        if self.action == 'create':
            return [permissions.IsAuthenticated()]
        if self.action in (
            'approve',
            'reject',
            'request_changes',
            'destroy',
        ):
            return [permissions.IsAdminUser()]
        if self.action in ('update', 'partial_update'):
            return [permissions.IsAuthenticated()]
        return [permissions.AllowAny()]

    def perform_create(self, serializer):
        import uuid

        from accounts.models import User

        user = self.request.user
        if not user.department_id:
            raise ValidationError(
                {
                    'department': (
                        'Complétez votre département dans le profil '
                        'avant de publier un cours.'
                    )
                }
            )
        code = (serializer.validated_data.get('code') or '').strip()
        if not code:
            prefix = 'ENS' if user.role == User.Role.TEACHER else 'PROP'
            code = f'{prefix}-{uuid.uuid4().hex[:8].upper()}'
        semester = (serializer.validated_data.get('semester') or '').strip()
        if not semester and user.promotion_id:
            semester = user.promotion.level or user.promotion.name

        is_teacher = user.role == User.Role.TEACHER or user.is_staff
        teacher_name = (
            serializer.validated_data.get('teacher_name') or ''
        ).strip()
        if not teacher_name:
            teacher_name = user.get_full_name() or user.email

        if is_teacher:
            course = serializer.save(
                department=user.department,
                promotion=user.promotion,
                submitted_by=user,
                validated_by=user,
                code=code,
                semester=semester,
                teacher_name=teacher_name,
                is_approved=True,
                moderation_status=Course.ModerationStatus.APPROVED,
            )
            course.teachers.add(user)
            CourseValidationLog.objects.create(
                course=course,
                actor=user,
                action=CourseValidationLog.Action.APPROVED,
                note='Publication enseignant',
                domain_slugs=','.join(
                    d.slug for d in course.domains.all()
                ),
            )
            return

        course = serializer.save(
            department=user.department,
            promotion=user.promotion,
            submitted_by=user,
            code=code,
            semester=semester,
            teacher_name=teacher_name,
            is_approved=False,
            moderation_status=Course.ModerationStatus.PENDING,
        )
        CourseValidationLog.objects.create(
            course=course,
            actor=user,
            action=CourseValidationLog.Action.SUBMITTED,
            note='Contribution étudiante',
        )

    def _user_owns_course(self, course, user):
        if user.is_staff:
            return True
        if course.submitted_by_id == user.id:
            return True
        return course.teachers.filter(id=user.id).exists()

    def perform_update(self, serializer):
        from accounts.models import User

        course = self.get_object()
        user = self.request.user
        if user.is_staff:
            serializer.save()
            return

        if not self._user_owns_course(course, user):
            raise PermissionDenied()

        is_teacher = user.role in (User.Role.TEACHER, User.Role.ADMIN)
        if is_teacher:
            # Les enseignants peuvent mettre à jour leurs cours publiés.
            serializer.save()
            return

        if course.moderation_status not in (
            Course.ModerationStatus.PENDING,
            Course.ModerationStatus.CHANGES_REQUESTED,
        ):
            raise PermissionDenied(
                'Seul un cours en attente ou à modifier peut être édité.'
            )
        course = serializer.save(
            is_approved=False,
            moderation_status=Course.ModerationStatus.PENDING,
            moderation_note='',
        )
        CourseValidationLog.objects.create(
            course=course,
            actor=user,
            action=CourseValidationLog.Action.SUBMITTED,
            note='Resoumission après modification',
        )

    @action(detail=True, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def stats(self, request, pk=None):
        """Stats enseignant : visites, étudiants, modules, activité 7 jours."""
        from learning.models import CourseLesson, CourseModule, LessonProgress

        course = self.get_object()
        if not self._user_owns_course(course, request.user) and not request.user.is_staff:
            raise PermissionDenied()

        lesson_ids = CourseLesson.objects.filter(
            module__course=course,
        ).values_list('id', flat=True)
        progress_qs = LessonProgress.objects.filter(lesson_id__in=lesson_ids)
        students = progress_qs.values('user_id').distinct().count()
        completed = progress_qs.filter(completed=True).values('user_id').distinct().count()
        modules = CourseModule.objects.filter(course=course).count()
        lessons = len(lesson_ids)

        # Activité sur 7 jours (mises à jour de progression)
        days = []
        today = timezone.localdate()
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            count = progress_qs.filter(updated_at__date=day).count()
            days.append({'date': day.isoformat(), 'label': day.strftime('%a'), 'value': count})

        return Response({
            'course_id': course.id,
            'views': course.views,
            'students': students,
            'students_completed': completed,
            'modules': modules,
            'lessons': lessons,
            'comments': course.course_comments.count(),
            'activity_7d': days,
        })

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def teacher_dashboard(self, request):
        """Tableau de bord agrégé pour l’enseignant connecté."""
        from learning.models import CourseLesson, LessonProgress

        user = request.user
        courses = (
            Course.objects.filter(Q(submitted_by=user) | Q(teachers=user))
            .distinct()
            .annotate(
                approved_document_count=Count(
                    'documents',
                    filter=Q(documents__is_approved=True),
                    distinct=True,
                )
            )
        )
        course_ids = list(courses.values_list('id', flat=True))
        lesson_ids = list(
            CourseLesson.objects.filter(
                module__course_id__in=course_ids,
            ).values_list('id', flat=True)
        )
        progress_qs = LessonProgress.objects.filter(lesson_id__in=lesson_ids)
        students = progress_qs.values('user_id').distinct().count()
        views_sum = sum(c.views for c in courses)

        per_course = []
        for c in courses.order_by('-views', 'title')[:12]:
            c_lessons = CourseLesson.objects.filter(module__course=c).values_list(
                'id', flat=True
            )
            c_students = (
                LessonProgress.objects.filter(lesson_id__in=c_lessons)
                .values('user_id')
                .distinct()
                .count()
            )
            per_course.append({
                'id': c.id,
                'title': c.title,
                'code': c.code,
                'views': c.views,
                'students': c_students,
                'semester': c.semester,
            })

        days = []
        today = timezone.localdate()
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            count = progress_qs.filter(updated_at__date=day).count()
            days.append({
                'date': day.isoformat(),
                'label': day.strftime('%a'),
                'value': count,
            })

        return Response({
            'courses_count': len(course_ids),
            'views': views_sum,
            'students': students,
            'lessons': len(lesson_ids),
            'activity_7d': days,
            'top_courses': per_course,
        })

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        course = serializer.instance
        out = CourseSerializer(course, context={'request': request})
        headers = self.get_success_headers(out.data)
        return Response(out.data, status=status.HTTP_201_CREATED, headers=headers)

    def _set_domains(self, course, request):
        domain_ids = request.data.get('domain_ids') or request.data.get('domains')
        domain_slugs = request.data.get('domain_slugs')
        domains = []
        if domain_ids:
            domains = list(
                LearningDomain.objects.filter(id__in=domain_ids, is_active=True)
            )
        elif domain_slugs:
            if isinstance(domain_slugs, str):
                domain_slugs = [
                    s.strip() for s in domain_slugs.split(',') if s.strip()
                ]
            domains = list(
                LearningDomain.objects.filter(
                    slug__in=domain_slugs, is_active=True
                )
            )
        if domains:
            course.domains.set(domains)
        return ','.join(d.slug for d in course.domains.all())

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        from accounts.models import AppNotification

        course = self.get_object()
        note = (request.data.get('note') or '').strip()
        domain_csv = self._set_domains(course, request)
        if not course.domains.exists():
            raise ValidationError(
                {
                    'domains': (
                        'Associez au moins un domaine d’apprentissage '
                        'lors de la validation.'
                    )
                }
            )
        course.is_approved = True
        course.moderation_status = Course.ModerationStatus.APPROVED
        course.moderation_note = note
        course.validated_by = request.user
        course.validated_at = timezone.now()
        course.save(
            update_fields=[
                'is_approved',
                'moderation_status',
                'moderation_note',
                'validated_by',
                'validated_at',
                'updated_at',
            ]
        )
        CourseValidationLog.objects.create(
            course=course,
            actor=request.user,
            action=CourseValidationLog.Action.APPROVED,
            note=note,
            domain_slugs=domain_csv,
        )
        if course.submitted_by_id:
            AppNotification.objects.create(
                user_id=course.submitted_by_id,
                kind=AppNotification.Kind.GENERAL,
                title='Cours validé',
                message=f'Votre cours « {course.title} » a été validé.',
            )
        return Response(CourseSerializer(course, context={'request': request}).data)

    @action(
        detail=True,
        methods=['post'],
        permission_classes=[permissions.IsAdminUser],
        url_path='request-changes',
    )
    def request_changes(self, request, pk=None):
        from accounts.models import AppNotification

        course = self.get_object()
        note = (request.data.get('note') or request.data.get('reason') or '').strip()
        if not note:
            raise ValidationError({'note': 'Précisez la modification demandée.'})
        course.is_approved = False
        course.moderation_status = Course.ModerationStatus.CHANGES_REQUESTED
        course.moderation_note = note
        course.save(
            update_fields=[
                'is_approved',
                'moderation_status',
                'moderation_note',
                'updated_at',
            ]
        )
        CourseValidationLog.objects.create(
            course=course,
            actor=request.user,
            action=CourseValidationLog.Action.CHANGES_REQUESTED,
            note=note,
            domain_slugs=','.join(d.slug for d in course.domains.all()),
        )
        if course.submitted_by_id:
            AppNotification.objects.create(
                user_id=course.submitted_by_id,
                kind=AppNotification.Kind.GENERAL,
                title='Modification demandée',
                message=(
                    f'Une modification a été demandée pour « {course.title} ». '
                    f'Motif : {note}'
                ),
            )
        return Response(CourseSerializer(course, context={'request': request}).data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        from accounts.models import AppNotification

        course = self.get_object()
        note = (request.data.get('note') or request.data.get('reason') or '').strip()
        course.is_approved = False
        course.moderation_status = Course.ModerationStatus.REJECTED
        course.moderation_note = note
        course.save(
            update_fields=[
                'is_approved',
                'moderation_status',
                'moderation_note',
                'updated_at',
            ]
        )
        CourseValidationLog.objects.create(
            course=course,
            actor=request.user,
            action=CourseValidationLog.Action.REJECTED,
            note=note,
        )
        if course.submitted_by_id:
            AppNotification.objects.create(
                user_id=course.submitted_by_id,
                kind=AppNotification.Kind.GENERAL,
                title='Cours refusé',
                message=(
                    f'Votre cours « {course.title} » a été refusé.'
                    + (f' Motif : {note}' if note else '')
                ),
            )
        return Response({'status': 'rejected'})


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
            'author__faculty',
            'university',
            'department',
            'department__faculty',
            'course',
        ).annotate(
            _peer_count=Count('peer_validations', distinct=True),
        )
        user = self.request.user
        if user.is_authenticated and user.is_staff:
            return qs

        if user.is_authenticated:
            # Pending visible pour toute la communauté (badge) ; rejetés = auteur seulement.
            pending_statuses = (
                'pending_peers',
                'pending_admin',
                'pending',
                'changes_requested',
            )
            return qs.filter(
                Q(is_approved=True)
                | Q(moderation_status__in=pending_statuses)
                | Q(author=user)
            ).distinct()

        return qs.filter(is_approved=True)

    def get_permissions(self):
        if self.action in ('list', 'retrieve', 'download', 'view'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        user = self.request.user
        extra = {}
        if not serializer.validated_data.get('university') and user.university_id:
            extra['university_id'] = user.university_id
        if not serializer.validated_data.get('department') and user.department_id:
            extra['department_id'] = user.department_id
        doc = serializer.save(
            author=user,
            is_approved=False,
            moderation_status='pending_peers',
            **extra,
        )
        user.contributions_count = F('contributions_count') + 1
        user.save(update_fields=['contributions_count'])
        user.refresh_from_db()
        return doc

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        doc = self.get_object()
        if doc.moderation_status not in ('pending_admin', 'pending_peers', 'pending'):
            if not doc.is_approved:
                return Response(
                    {
                        'detail': (
                            'Seuls les documents en attente de validation admin '
                            'peuvent être approuvés. '
                            f'Statut actuel : {doc.moderation_status}.'
                        ),
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )
        if doc.moderation_status in ('pending_peers', 'pending'):
            from academic.rewards import FACULTY_PEER_VALIDATIONS_REQUIRED
            from academic.peer_validation import peer_validation_count

            count = peer_validation_count(doc)
            if count < FACULTY_PEER_VALIDATIONS_REQUIRED:
                return Response(
                    {
                        'detail': (
                            f'Il manque {FACULTY_PEER_VALIDATIONS_REQUIRED - count} '
                            'validation(s) étudiante(s) de la faculté.'
                        ),
                        'peer_validation_count': count,
                        'peer_validations_required': FACULTY_PEER_VALIDATIONS_REQUIRED,
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )
        doc.is_approved = True
        doc.moderation_status = 'approved'
        doc.rejection_reason = ''
        doc.save()
        return Response(DocumentSerializer(doc, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def peer_validate(self, request, pk=None):
        from academic.peer_validation import PeerValidationError, peer_rate_document

        doc = self.get_object()
        raw = request.data.get('score', request.data.get('rating', 5))
        try:
            score = int(raw)
        except (TypeError, ValueError):
            return Response(
                {'detail': 'La note doit être un entier entre 1 et 5.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            peer_rate_document(request.user, doc, score)
        except PeerValidationError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        doc.refresh_from_db()
        serializer = DocumentSerializer(doc, context={'request': request})
        return Response(serializer.data)

    @action(detail=True, methods=['post'], url_path='rate')
    def rate(self, request, pk=None):
        """Alias explicite : noter un document (1–5 étoiles)."""
        return self.peer_validate(request, pk=pk)

    @action(detail=False, methods=['get'])
    def peer_review_queue(self, request):
        from academic.peer_validation import peer_review_queue_for

        if not request.user.is_authenticated:
            return Response(
                {'detail': 'Authentification requise.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        if not request.user.faculty_id:
            return Response(
                {'detail': 'Complète ta faculté dans ton profil pour noter des documents.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        qs = peer_review_queue_for(request.user)
        page = self.paginate_queryset(qs)
        ser = DocumentSerializer(
            page if page is not None else qs,
            many=True,
            context={'request': request},
        )
        if page is not None:
            return self.get_paginated_response(ser.data)
        return Response(ser.data)

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
        from academic.peer_validation import peer_validation_count
        from academic.rewards import FACULTY_PEER_VALIDATIONS_REQUIRED

        doc = self.get_object()
        user = request.user
        is_author = user.is_authenticated and doc.author_id == user.pk
        is_staff = user.is_authenticated and user.is_staff
        unlocked = (
            doc.is_approved
            or peer_validation_count(doc) >= FACULTY_PEER_VALIDATIONS_REQUIRED
        )
        if not (unlocked or is_author or is_staff):
            count = peer_validation_count(doc)
            return Response(
                {
                    'detail': (
                        'Ce document n’est téléchargeable qu’après '
                        f'{FACULTY_PEER_VALIDATIONS_REQUIRED} validations de la faculté '
                        f'({count}/{FACULTY_PEER_VALIDATIONS_REQUIRED}).'
                    ),
                    'peer_validation_count': count,
                    'peer_validations_required': FACULTY_PEER_VALIDATIONS_REQUIRED,
                    'can_download': False,
                },
                status=status.HTTP_403_FORBIDDEN,
            )

        Document.objects.filter(pk=doc.pk).update(downloads=F('downloads') + 1)
        doc.refresh_from_db()
        return Response(
            {
                'file': request.build_absolute_uri(doc.file.url) if doc.file else None,
                'external_url': doc.external_url or None,
                'downloads': doc.downloads,
                'can_download': True,
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
        from .rewards import (
            FACULTY_PEER_VALIDATIONS_REQUIRED,
            HIGH_TIER_POINTS,
            LOW_TIER_POINTS,
        )

        user = request.user
        unlock = WHEEL_UNLOCK_POINTS
        return Response(
            {
                'points': user.reputation,
                'unlock_points': unlock,
                'spin_cost': WHEEL_SPIN_COST,
                'can_spin': user.reputation >= unlock,
                'peer_validations_required': FACULTY_PEER_VALIDATIONS_REQUIRED,
                'high_tier_points': HIGH_TIER_POINTS,
                'low_tier_points': LOW_TIER_POINTS,
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

        cost = WHEEL_SPIN_COST
        if user.reputation < cost:
            return Response(
                {'detail': 'Points insuffisants pour un tour.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        weights = [max(1, p.weight) for p in prizes]
        prize = random.choices(prizes, weights=weights, k=1)[0]
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
