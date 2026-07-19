from django.contrib import admin

from academic.rewards import award_approval_points

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    Department,
    Document,
    DocumentComment,
    Faculty,
    Favorite,
    Promotion,
    RewardPrize,
    RewardRedemption,
    University,
)


@admin.register(University)
class UniversityAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'country', 'is_active')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name', 'city')


@admin.register(Campus)
class CampusAdmin(admin.ModelAdmin):
    list_display = ('name', 'university')
    list_filter = ('university',)


@admin.register(Faculty)
class FacultyAdmin(admin.ModelAdmin):
    list_display = ('name', 'university', 'campus')
    list_filter = ('university',)
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ('name', 'faculty')
    list_filter = ('faculty__university',)
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name',)


@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ('name', 'department', 'year', 'level')
    list_filter = ('year', 'department', 'level')


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('code', 'title', 'department', 'semester', 'credits')
    list_filter = ('department', 'semester')
    search_fields = ('code', 'title')
    filter_horizontal = ('teachers',)


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = (
        'title',
        'doc_type',
        'author',
        'university',
        'moderation_status',
        'is_approved',
        'points_awarded',
        'downloads',
        'created_at',
    )
    list_filter = (
        'doc_type',
        'moderation_status',
        'is_approved',
        'university',
        'academic_year',
    )
    search_fields = ('title', 'description')
    actions = ['approve_documents', 'reject_documents']

    @admin.action(description='Approuver les documents (crédite les points)')
    def approve_documents(self, request, queryset):
        for doc in queryset.select_related('author'):
            if not doc.is_approved:
                doc.is_approved = True
                doc.moderation_status = 'approved'
                doc.save()
            else:
                award_approval_points(doc)

    @admin.action(description='Refuser les documents')
    def reject_documents(self, request, queryset):
        from accounts.models import AppNotification

        for doc in queryset.select_related('author'):
            doc.is_approved = False
            doc.moderation_status = 'rejected'
            doc.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'updated_at',
                ]
            )
            if doc.author_id:
                AppNotification.objects.create(
                    user_id=doc.author_id,
                    kind=AppNotification.Kind.DOCUMENT_REJECTED,
                    title='Contribution refusée',
                    message=f'Votre contribution « {doc.title} » a été refusée.',
                )


admin.site.register(DocumentComment)
admin.site.register(Favorite)


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ('title', 'university', 'category', 'is_published', 'created_at')
    list_filter = ('university', 'category', 'is_published')


@admin.register(CalendarEvent)
class CalendarEventAdmin(admin.ModelAdmin):
    list_display = ('title', 'university', 'event_type', 'starts_at')
    list_filter = ('university', 'event_type')


@admin.register(RewardPrize)
class RewardPrizeAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'min_points', 'points_cost', 'weight', 'is_active')
    list_filter = ('category', 'is_active')


@admin.register(RewardRedemption)
class RewardRedemptionAdmin(admin.ModelAdmin):
    list_display = ('user', 'prize', 'points_spent', 'created_at')
    list_filter = ('prize__category',)
