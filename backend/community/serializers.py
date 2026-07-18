from rest_framework import serializers

from .models import AlumniFollow, Post, PostComment, SavedPost


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
    author_role = serializers.CharField(source='author.role', read_only=True)
    author_id = serializers.IntegerField(source='author.id', read_only=True)
    department_name = serializers.CharField(
        source='department.name',
        read_only=True,
        default='',
    )
    kind_display = serializers.CharField(source='get_kind_display', read_only=True)
    is_liked = serializers.SerializerMethodField()
    is_saved = serializers.SerializerMethodField()
    is_following_author = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = [
            'id',
            'author',
            'author_id',
            'author_name',
            'author_role',
            'department',
            'department_name',
            'title',
            'content',
            'kind',
            'kind_display',
            'video_url',
            'tags',
            'likes_count',
            'comments_count',
            'is_approved',
            'is_liked',
            'is_saved',
            'is_following_author',
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

    def get_is_saved(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.saves.filter(user=request.user).exists()

    def get_is_following_author(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return AlumniFollow.objects.filter(
            follower=request.user,
            alumni=obj.author,
        ).exists()


class AlumniFollowSerializer(serializers.ModelSerializer):
    alumni_name = serializers.SerializerMethodField()
    alumni_role = serializers.CharField(source='alumni.role', read_only=True)
    alumni_bio = serializers.CharField(source='alumni.bio', read_only=True)
    alumni_department = serializers.CharField(
        source='alumni.department.name',
        read_only=True,
        default='',
    )

    class Meta:
        model = AlumniFollow
        fields = [
            'id',
            'alumni',
            'alumni_name',
            'alumni_role',
            'alumni_bio',
            'alumni_department',
            'created_at',
        ]
        read_only_fields = ['created_at']

    def get_alumni_name(self, obj):
        return obj.alumni.get_full_name() or obj.alumni.email


class SavedPostSerializer(serializers.ModelSerializer):
    post_detail = PostSerializer(source='post', read_only=True)

    class Meta:
        model = SavedPost
        fields = ['id', 'post', 'post_detail', 'created_at']
        read_only_fields = ['created_at']
