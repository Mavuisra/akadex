from django.contrib import admin

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
    list_filter = ('year', 'department')


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
        'is_approved',
        'downloads',
        'created_at',
    )
    list_filter = ('doc_type', 'is_approved', 'university', 'academic_year')
    search_fields = ('title', 'description')
    actions = ['approve_documents']

    @admin.action(description='Approuver les documents sélectionnés')
    def approve_documents(self, request, queryset):
        queryset.update(is_approved=True)


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
