from django.contrib import admin

from .models import Conversation, ConversationActivity, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'is_group', 'updated_at')
    filter_horizontal = ('participants',)
    search_fields = ('name', 'participants__email')


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = (
        'conversation',
        'sender',
        'kind',
        'delivery_status',
        'created_at',
        'is_read',
    )
    list_filter = ('kind', 'delivery_status', 'is_read')
    search_fields = ('content', 'sender__email')


@admin.register(ConversationActivity)
class ConversationActivityAdmin(admin.ModelAdmin):
    list_display = (
        'conversation',
        'user',
        'is_typing',
        'is_recording',
        'updated_at',
    )
    list_filter = ('is_typing', 'is_recording')
