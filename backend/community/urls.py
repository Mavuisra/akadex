from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import PostCommentViewSet, PostViewSet

router = DefaultRouter()
router.register('posts', PostViewSet, basename='post')
router.register('post-comments', PostCommentViewSet, basename='post-comment')

urlpatterns = [
    path('', include(router.urls)),
]
