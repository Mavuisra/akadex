from django.contrib import admin

from .models import Post, PostComment, PostLike


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'author',
        'department',
        'likes_count',
        'comments_count',
        'is_approved',
        'created_at',
    )
    list_filter = ('is_approved', 'department')
    search_fields = ('title', 'content')


admin.site.register(PostComment)
admin.site.register(PostLike)
