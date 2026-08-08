from django.contrib import admin

from .models import CourseDeposit


@admin.register(CourseDeposit)
class CourseDepositAdmin(admin.ModelAdmin):
    list_display = (
        'deposit_id',
        'user',
        'amount',
        'currency',
        'provider',
        'status',
        'phone',
        'created_at',
    )
    list_filter = ('status', 'provider', 'currency')
    search_fields = ('deposit_id', 'phone', 'user__email')
    readonly_fields = ('created_at', 'updated_at', 'pawapay_response')
