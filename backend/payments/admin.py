from django.contrib import admin

from .models import CourseDeposit, CoursePurchase


@admin.register(CourseDeposit)
class CourseDepositAdmin(admin.ModelAdmin):
    list_display = (
        'deposit_id',
        'user',
        'amount',
        'currency',
        'provider',
        'status',
        'access_granted',
        'phone',
        'created_at',
    )
    list_filter = ('status', 'provider', 'currency', 'access_granted')
    search_fields = ('deposit_id', 'phone', 'user__email')
    readonly_fields = ('created_at', 'updated_at', 'pawapay_response')


@admin.register(CoursePurchase)
class CoursePurchaseAdmin(admin.ModelAdmin):
    list_display = ('user', 'course', 'deposit', 'created_at')
    search_fields = ('user__email', 'course__code', 'course__title')
    raw_id_fields = ('user', 'course', 'deposit')
