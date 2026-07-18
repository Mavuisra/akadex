from django.contrib.auth import get_user_model
from django.db.models import F, Q
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import AlumniFollow, Post, PostComment, PostKind, PostLike, SavedPost
from .serializers import (
    AlumniFollowSerializer,
    PostCommentSerializer,
    PostSerializer,
    SavedPostSerializer,
)

User = get_user_model()

ALUMNI_KINDS = [
    PostKind.ALUMNI_ADVICE,
    PostKind.ALUMNI_PATH,
    PostKind.ALUMNI_CAREER,
    PostKind.ALUMNI_TFC,
    PostKind.ALUMNI_VIDEO,
]


class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    filterset_fields = ['department', 'author', 'kind']
    search_fields = ['title', 'content', 'tags']
    ordering_fields = ['created_at', 'likes_count', 'comments_count']

    def get_queryset(self):
        qs = Post.objects.select_related('author', 'department', 'author__department')
        scope = self.request.query_params.get('scope')
        if scope == 'alumni':
            qs = qs.filter(
                Q(kind__in=ALUMNI_KINDS) | Q(author__role=User.Role.ALUMNI)
            )
        elif scope == 'community':
            qs = qs.exclude(kind__in=ALUMNI_KINDS)

        # Recommandations faculté / département
        dept = self.request.query_params.get('recommend_department')
        if dept:
            qs = qs.filter(
                Q(department_id=dept) | Q(author__department_id=dept)
            )

        if self.request.user.is_staff:
            return qs
        return qs.filter(is_approved=True)

    def perform_create(self, serializer):
        kind = serializer.validated_data.get('kind', PostKind.DISCUSSION)
        user = self.request.user
        if kind in ALUMNI_KINDS and user.role not in (
            User.Role.ALUMNI,
            User.Role.ADMIN,
            User.Role.TEACHER,
        ):
            # Les étudiants peuvent poser des questions, pas publier du contenu alumni
            if kind != PostKind.QUESTION:
                from rest_framework.exceptions import PermissionDenied

                raise PermissionDenied(
                    'Seuls les alumni peuvent publier ce type de contenu.'
                )
        serializer.save(author=user)

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def like(self, request, pk=None):
        post = self.get_object()
        like, created = PostLike.objects.get_or_create(user=request.user, post=post)
        if created:
            Post.objects.filter(pk=post.pk).update(likes_count=F('likes_count') + 1)
            return Response({'liked': True}, status=status.HTTP_201_CREATED)
        like.delete()
        Post.objects.filter(pk=post.pk).update(likes_count=F('likes_count') - 1)
        return Response({'liked': False})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def save_post(self, request, pk=None):
        post = self.get_object()
        saved, created = SavedPost.objects.get_or_create(user=request.user, post=post)
        if created:
            return Response({'saved': True}, status=status.HTTP_201_CREATED)
        saved.delete()
        return Response({'saved': False})


class PostCommentViewSet(viewsets.ModelViewSet):
    serializer_class = PostCommentSerializer
    filterset_fields = ['post', 'parent']

    def get_queryset(self):
        return PostComment.objects.select_related('author', 'post')

    def perform_create(self, serializer):
        comment = serializer.save(author=self.request.user)
        Post.objects.filter(pk=comment.post_id).update(
            comments_count=F('comments_count') + 1
        )

    def get_permissions(self):
        if self.action in ('list', 'retrieve'):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]


class AlumniFollowViewSet(viewsets.ModelViewSet):
    serializer_class = AlumniFollowSerializer
    permission_classes = [permissions.IsAuthenticated]
    http_method_names = ['get', 'post', 'delete', 'head', 'options']

    def get_queryset(self):
        return AlumniFollow.objects.filter(
            follower=self.request.user
        ).select_related('alumni', 'alumni__department')

    def perform_create(self, serializer):
        alumni = serializer.validated_data['alumni']
        if alumni.role != User.Role.ALUMNI and not alumni.is_staff:
            from rest_framework.exceptions import ValidationError

            raise ValidationError({'alumni': 'Cet utilisateur n’est pas un alumni.'})
        if alumni.pk == self.request.user.pk:
            from rest_framework.exceptions import ValidationError

            raise ValidationError({'alumni': 'Tu ne peux pas te suivre toi-même.'})
        serializer.save(follower=self.request.user)

    @action(detail=False, methods=['post'])
    def toggle(self, request):
        alumni_id = request.data.get('alumni')
        if not alumni_id:
            return Response(
                {'detail': 'alumni requis'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            alumni = User.objects.get(pk=alumni_id)
        except User.DoesNotExist:
            return Response({'detail': 'Introuvable'}, status=status.HTTP_404_NOT_FOUND)

        follow, created = AlumniFollow.objects.get_or_create(
            follower=request.user,
            alumni=alumni,
        )
        if created:
            return Response({'following': True}, status=status.HTTP_201_CREATED)
        follow.delete()
        return Response({'following': False})


class SavedPostViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = SavedPostSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SavedPost.objects.filter(user=self.request.user).select_related(
            'post',
            'post__author',
            'post__department',
        )
