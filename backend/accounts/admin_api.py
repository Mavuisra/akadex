"""API Admin Akadex — CRUD réel, réservé IsAkadexAdmin."""

from __future__ import annotations

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.db.models import Count, Q, Sum
from django.utils import timezone
from rest_framework import permissions, serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import AppNotification
from .permissions import IsAkadexAdmin
from .serializers import AppNotificationSerializer, UserSerializer

User = get_user_model()


class AdminPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = 'page_size'
    max_page_size = 100


class AdminUserSerializer(UserSerializer):
    """Serializer admin : rôle / is_active / mot de passe modifiables."""

    password = serializers.CharField(write_only=True, required=False, allow_blank=True)
    is_active = serializers.BooleanField(required=False)
    is_staff = serializers.BooleanField(required=False)

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + [
            'password',
            'is_active',
            'is_staff',
        ]
        read_only_fields = [
            f
            for f in UserSerializer.Meta.read_only_fields
            if f not in ('role', 'is_active', 'is_staff')
        ]

    def create(self, validated_data):
        password = validated_data.pop('password', None) or User.objects.make_random_password()
        user = User(**validated_data)
        if not user.username:
            base = (user.email or 'user').split('@')[0][:40]
            user.username = base
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for k, v in validated_data.items():
            setattr(instance, k, v)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class AdminUserViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAkadexAdmin]
    serializer_class = AdminUserSerializer
    pagination_class = AdminPagination
    search_fields = [
        'first_name',
        'last_name',
        'postnom',
        'email',
        'username',
        'phone',
    ]
    filterset_fields = ['role', 'is_active', 'university', 'faculty', 'department']
    ordering_fields = ['date_joined', 'last_seen_at', 'email', 'first_name']
    ordering = ['-date_joined']

    def get_queryset(self):
        return User.objects.select_related(
            'university', 'faculty', 'department', 'promotion',
        ).all()

    @action(detail=True, methods=['post'])
    def activate(self, request, pk=None):
        user = self.get_object()
        user.is_active = True
        user.save(update_fields=['is_active'])
        return Response(self.get_serializer(user).data)

    @action(detail=True, methods=['post'])
    def deactivate(self, request, pk=None):
        user = self.get_object()
        if user.pk == request.user.pk:
            return Response(
                {'detail': 'Vous ne pouvez pas vous désactiver vous-même.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user.is_active = False
        user.save(update_fields=['is_active'])
        return Response(self.get_serializer(user).data)


class AdminDashboardView(APIView):
    permission_classes = [IsAkadexAdmin]

    def get(self, request):
        from academic.models import Course, Document, LearningDomain
        from community.models import Post
        from learning.models import LessonProgress, StudentLearningEvent
        from payments.models import CourseDeposit

        now = timezone.now()
        week_ago = now - timedelta(days=7)

        users = User.objects.all()
        courses = Course.objects.all()
        deposits = CourseDeposit.objects.all()

        completed_deposits = deposits.filter(status=CourseDeposit.Status.COMPLETED)
        revenue = completed_deposits.aggregate(s=Sum('amount'))['s'] or 0

        # Activité 7 j (inscriptions users + events)
        activity_7d = []
        today = timezone.localdate()
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            activity_7d.append({
                'date': day.isoformat(),
                'label': day.strftime('%a'),
                'users': users.filter(date_joined__date=day).count(),
                'events': StudentLearningEvent.objects.filter(
                    created_at__date=day,
                ).count(),
                'deposits': deposits.filter(created_at__date=day).count(),
            })

        recent_users = [
            {
                'id': u.id,
                'name': u.get_full_name() or u.email,
                'email': u.email,
                'role': u.role,
                'created_at': u.date_joined.isoformat() if u.date_joined else None,
            }
            for u in users.order_by('-date_joined')[:8]
        ]
        recent_courses = [
            {
                'id': c.id,
                'title': c.title,
                'code': c.code,
                'status': c.moderation_status,
                'created_at': c.created_at.isoformat() if c.created_at else None,
            }
            for c in courses.order_by('-created_at')[:8]
        ]

        enrollments = (
            LessonProgress.objects.values('user_id', 'lesson__module__course_id')
            .distinct()
            .count()
        )

        return Response({
            'users_total': users.count(),
            'students': users.filter(role='student').count(),
            'teachers': users.filter(role='teacher').count(),
            'alumni': users.filter(role='alumni').count(),
            'admins': users.filter(Q(role='admin') | Q(is_staff=True)).count(),
            'users_week': users.filter(date_joined__gte=week_ago).count(),
            'courses_total': courses.count(),
            'courses_published': courses.filter(
                Q(is_approved=True) | Q(moderation_status=Course.ModerationStatus.APPROVED)
            ).count(),
            'courses_pending': courses.filter(
                moderation_status=Course.ModerationStatus.PENDING,
            ).count(),
            'courses_draft': courses.filter(
                moderation_status=Course.ModerationStatus.CHANGES_REQUESTED,
            ).count(),
            'domains': LearningDomain.objects.filter(is_active=True).count(),
            'documents': Document.objects.count(),
            'documents_pending': Document.objects.filter(
                moderation_status__in=('pending_peers', 'pending_admin'),
            ).count(),
            'posts': Post.objects.count(),
            'posts_pending': Post.objects.filter(
                moderation_status='pending',
            ).count(),
            'enrollments': enrollments,
            'payments_total': deposits.count(),
            'payments_completed': completed_deposits.count(),
            'revenue_total': float(revenue),
            'activity_7d': activity_7d,
            'recent_users': recent_users,
            'recent_courses': recent_courses,
        })


class AdminEnrollmentView(APIView):
    """Inscriptions dérivées de LessonProgress (pas de modèle Enrollment)."""

    permission_classes = [IsAkadexAdmin]

    def get(self, request):
        from learning.models import CourseLesson, LessonProgress

        search = (request.query_params.get('search') or '').strip()
        course_id = request.query_params.get('course')

        qs = LessonProgress.objects.select_related(
            'user', 'lesson', 'lesson__module', 'lesson__module__course',
        )
        if course_id:
            qs = qs.filter(lesson__module__course_id=course_id)

        buckets = {}
        for row in qs:
            course = row.lesson.module.course
            key = (row.user_id, course.id)
            b = buckets.get(key)
            if b is None:
                b = {
                    'user_id': row.user_id,
                    'student_name': row.user.get_full_name() or row.user.email,
                    'student_email': row.user.email,
                    'course_id': course.id,
                    'course_title': course.title,
                    'lessons_touched': 0,
                    'lessons_completed': 0,
                    'last_activity': row.updated_at,
                    'enrolled_at': row.updated_at,
                }
                buckets[key] = b
            b['lessons_touched'] += 1
            if row.completed:
                b['lessons_completed'] += 1
            if row.updated_at and (
                b['last_activity'] is None or row.updated_at > b['last_activity']
            ):
                b['last_activity'] = row.updated_at
            if row.updated_at and (
                b['enrolled_at'] is None or row.updated_at < b['enrolled_at']
            ):
                b['enrolled_at'] = row.updated_at

        totals = {}
        for cid in {b['course_id'] for b in buckets.values()}:
            totals[cid] = CourseLesson.objects.filter(module__course_id=cid).count() or 1

        results = []
        for b in buckets.values():
            if search:
                hay = f"{b['student_name']} {b['student_email']} {b['course_title']}".lower()
                if search.lower() not in hay:
                    continue
            total = totals.get(b['course_id'], 1)
            pct = min(100, round(100 * b['lessons_completed'] / total))
            results.append({
                **b,
                'progress_pct': pct,
                'last_activity': (
                    b['last_activity'].isoformat() if b['last_activity'] else None
                ),
                'enrolled_at': (
                    b['enrolled_at'].isoformat() if b['enrolled_at'] else None
                ),
            })
        results.sort(key=lambda r: r['last_activity'] or '', reverse=True)
        return Response({'count': len(results), 'results': results[:200]})


class AdminBroadcastNotificationView(APIView):
    permission_classes = [IsAkadexAdmin]

    def post(self, request):
        title = (request.data.get('title') or '').strip()
        message = (request.data.get('message') or '').strip()
        role = (request.data.get('role') or '').strip()
        user_id = request.data.get('user_id')

        if not title or not message:
            return Response(
                {'detail': 'title et message obligatoires.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qs = User.objects.filter(is_active=True)
        if user_id:
            qs = qs.filter(pk=user_id)
        elif role:
            qs = qs.filter(role=role)

        created = 0
        for u in qs.iterator():
            AppNotification.objects.create(
                user=u,
                kind=AppNotification.Kind.GENERAL,
                title=title[:255],
                message=message,
            )
            created += 1
        return Response({'created': created})

    def get(self, request):
        """Liste globale des notifications (admin)."""
        qs = AppNotification.objects.select_related('user').order_by('-created_at')
        search = (request.query_params.get('search') or '').strip()
        if search:
            qs = qs.filter(
                Q(title__icontains=search)
                | Q(message__icontains=search)
                | Q(user__email__icontains=search)
            )
        paginator = AdminPagination()
        page = paginator.paginate_queryset(qs, request)
        data = []
        for n in page:
            row = AppNotificationSerializer(n).data
            row['user_email'] = n.user.email
            row['user_name'] = n.user.get_full_name() or n.user.email
            data.append(row)
        return paginator.get_paginated_response(data)


class AdminDepositSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.SerializerMethodField()

    class Meta:
        from payments.models import CourseDeposit

        model = CourseDeposit
        fields = [
            'id',
            'deposit_id',
            'user',
            'user_email',
            'user_name',
            'amount',
            'currency',
            'phone',
            'provider',
            'correspondent',
            'status',
            'course_ids',
            'failure_message',
            'created_at',
            'updated_at',
        ]
        read_only_fields = fields

    def get_user_name(self, obj):
        if not obj.user_id:
            return ''
        return obj.user.get_full_name() or obj.user.email


class AdminDepositViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAkadexAdmin]
    serializer_class = AdminDepositSerializer
    pagination_class = AdminPagination
    filterset_fields = ['status', 'provider', 'currency']
    search_fields = ['phone', 'user__email', 'deposit_id']
    ordering = ['-created_at']

    def get_queryset(self):
        from payments.models import CourseDeposit

        return CourseDeposit.objects.select_related('user').all()
