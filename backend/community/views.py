from django.db.models import F
from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Post, PostComment, PostLike
from .serializers import PostCommentSerializer, PostSerializer


class PostViewSet(viewsets.ModelViewSet):
    serializer_class = PostSerializer
    filterset_fields = ['department', 'author']
    search_fields = ['title', 'content', 'tags']
    ordering_fields = ['created_at', 'likes_count', 'comments_count']

    def get_queryset(self):
        qs = Post.objects.select_related('author', 'department')
        if self.request.user.is_staff:
            return qs
        return qs.filter(is_approved=True)

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

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
