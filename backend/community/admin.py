from django.contrib import admin

from .models import AlumniFollow, Post, PostComment, PostLike, SavedPost


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'kind',
        'author',
        'department',
        'likes_count',
        'comments_count',
        'is_approved',
        'created_at',
    )
    list_filter = ('is_approved', 'kind', 'department')
    search_fields = ('title', 'content')


admin.site.register(PostComment)
admin.site.register(PostLike)
admin.site.register(AlumniFollow)
admin.site.register(SavedPost)
