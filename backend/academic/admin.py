from django.contrib import admin

from academic.rewards import award_approval_points

from .models import (
    Announcement,
    CalendarEvent,
    Campus,
    Course,
    CourseValidationLog,
    Department,
    Document,
    DocumentComment,
    DocumentPeerValidation,
    Faculty,
    Favorite,
    LearningDomain,
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


@admin.register(LearningDomain)
class LearningDomainAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'order', 'is_active')
    list_editable = ('order', 'is_active')
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ('name', 'slug', 'keywords')


class CourseValidationLogInline(admin.TabularInline):
    model = CourseValidationLog
    extra = 0
    readonly_fields = (
        'actor',
        'action',
        'note',
        'domain_slugs',
        'created_at',
    )
    can_delete = False


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = (
        'code',
        'title',
        'department',
        'semester',
        'moderation_status',
        'is_approved',
        'submitted_by',
        'credits',
    )
    list_filter = (
        'moderation_status',
        'is_approved',
        'department__faculty__university',
        'semester',
        'domains',
    )
    search_fields = ('code', 'title', 'teacher_name', 'submitted_by__email')
    filter_horizontal = ('teachers', 'domains')
    readonly_fields = ('validated_by', 'validated_at', 'created_at', 'updated_at')
    inlines = [CourseValidationLogInline]
    actions = ['approve_courses', 'reject_courses', 'request_course_changes']

    @admin.action(description='Valider les cours (domaines déjà associés)')
    def approve_courses(self, request, queryset):
        from django.utils import timezone

        from accounts.models import AppNotification

        for course in queryset.select_related('submitted_by'):
            if not course.domains.exists():
                self.message_user(
                    request,
                    f'« {course.title} » : associez au moins un domaine avant validation.',
                    level='WARNING',
                )
                continue
            course.is_approved = True
            course.moderation_status = Course.ModerationStatus.APPROVED
            course.validated_by = request.user
            course.validated_at = timezone.now()
            course.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'validated_by',
                    'validated_at',
                    'updated_at',
                ]
            )
            CourseValidationLog.objects.create(
                course=course,
                actor=request.user,
                action=CourseValidationLog.Action.APPROVED,
                domain_slugs=','.join(d.slug for d in course.domains.all()),
            )
            if course.submitted_by_id:
                AppNotification.objects.create(
                    user_id=course.submitted_by_id,
                    kind=AppNotification.Kind.GENERAL,
                    title='Cours validé',
                    message=f'Votre cours « {course.title} » a été validé.',
                )

    @admin.action(description='Demander une modification')
    def request_course_changes(self, request, queryset):
        from accounts.models import AppNotification

        for course in queryset.select_related('submitted_by'):
            course.is_approved = False
            course.moderation_status = Course.ModerationStatus.CHANGES_REQUESTED
            course.moderation_note = course.moderation_note or 'Modification demandée'
            course.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'moderation_note',
                    'updated_at',
                ]
            )
            CourseValidationLog.objects.create(
                course=course,
                actor=request.user,
                action=CourseValidationLog.Action.CHANGES_REQUESTED,
                note=course.moderation_note,
            )
            if course.submitted_by_id:
                AppNotification.objects.create(
                    user_id=course.submitted_by_id,
                    kind=AppNotification.Kind.GENERAL,
                    title='Modification demandée',
                    message=(
                        f'Une modification a été demandée pour « {course.title} ».'
                    ),
                )

    @admin.action(description='Rejeter les cours')
    def reject_courses(self, request, queryset):
        from accounts.models import AppNotification

        for course in queryset.select_related('submitted_by'):
            course.is_approved = False
            course.moderation_status = Course.ModerationStatus.REJECTED
            course.save(
                update_fields=[
                    'is_approved',
                    'moderation_status',
                    'updated_at',
                ]
            )
            CourseValidationLog.objects.create(
                course=course,
                actor=request.user,
                action=CourseValidationLog.Action.REJECTED,
            )
            if course.submitted_by_id:
                AppNotification.objects.create(
                    user_id=course.submitted_by_id,
                    kind=AppNotification.Kind.GENERAL,
                    title='Cours refusé',
                    message=f'Votre cours « {course.title} » a été refusé.',
                )


@admin.register(CourseValidationLog)
class CourseValidationLogAdmin(admin.ModelAdmin):
    list_display = ('course', 'action', 'actor', 'created_at')
    list_filter = ('action',)
    search_fields = ('course__title', 'course__code', 'note')
    readonly_fields = (
        'course',
        'actor',
        'action',
        'note',
        'domain_slugs',
        'created_at',
    )


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
        from .peer_validation import peer_validation_count
        from .rewards import FACULTY_PEER_VALIDATIONS_REQUIRED

        for doc in queryset.select_related('author'):
            if doc.is_approved:
                continue
            count = peer_validation_count(doc)
            if doc.moderation_status == 'pending_admin' or count >= FACULTY_PEER_VALIDATIONS_REQUIRED:
                doc.is_approved = True
                doc.moderation_status = 'approved'
                doc.save()
            else:
                self.message_user(
                    request,
                    f'« {doc.title} » : seulement {count}/'
                    f'{FACULTY_PEER_VALIDATIONS_REQUIRED} validations fac.',
                    level='warning',
                )

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


@admin.register(DocumentPeerValidation)
class DocumentPeerValidationAdmin(admin.ModelAdmin):
    list_display = ('document', 'validator', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('document__title', 'validator__email')
