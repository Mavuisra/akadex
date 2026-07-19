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
        'moderation_status',
        'is_approved',
        'created_at',
    )
    list_filter = ('moderation_status', 'is_approved', 'kind', 'department')
    search_fields = ('title', 'content')
    actions = ['approve_posts', 'reject_posts']

    @admin.action(description='Valider les publications')
    def approve_posts(self, request, queryset):
        from accounts.models import AppNotification
        from community.models import ModerationStatus

        for post in queryset.select_related('author'):
            post.is_approved = True
            post.moderation_status = ModerationStatus.APPROVED
            post.rejection_reason = ''
            post.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'rejection_reason',
                    'updated_at',
                ]
            )
            AppNotification.objects.create(
                user=post.author,
                kind=AppNotification.Kind.POST_APPROVED,
                title='Publication validée',
                message=(
                    f'Félicitations ! Votre publication « {post.title} » '
                    'a été validée et est maintenant visible.'
                ),
            )

    @admin.action(description='Refuser les publications')
    def reject_posts(self, request, queryset):
        from accounts.models import AppNotification
        from community.models import ModerationStatus

        for post in queryset.select_related('author'):
            post.is_approved = False
            post.moderation_status = ModerationStatus.REJECTED
            post.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'updated_at',
                ]
            )
            AppNotification.objects.create(
                user=post.author,
                kind=AppNotification.Kind.POST_REJECTED,
                title='Publication refusée',
                message=f'Votre publication « {post.title} » a été refusée.',
            )


admin.site.register(PostComment)
admin.site.register(PostLike)
admin.site.register(AlumniFollow)
admin.site.register(SavedPost)
