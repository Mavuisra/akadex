from rest_framework import serializers

from .models import Post, PostComment, PostLike


class PostCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()

    class Meta:
        model = PostComment
        fields = [
            'id',
            'post',
            'author',
            'author_name',
            'content',
            'parent',
            'created_at',
        ]
        read_only_fields = ['author', 'created_at']

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email


class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.SerializerMethodField()
    department_name = serializers.CharField(source='department.name', read_only=True)
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id',
            'author',
            'author_name',
            'department',
            'department_name',
            'title',
            'content',
            'tags',
            'likes_count',
            'comments_count',
            'is_approved',
            'is_liked',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'author',
            'likes_count',
            'comments_count',
            'is_approved',
            'created_at',
            'updated_at',
        ]

    def get_author_name(self, obj):
        return obj.author.get_full_name() or obj.author.email

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.likes.filter(user=request.user).exists()
