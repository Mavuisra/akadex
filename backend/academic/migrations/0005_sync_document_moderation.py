from django.db import migrations


def sync_moderation(apps, schema_editor):
    Document = apps.get_model('academic', 'Document')
    Document.objects.filter(is_approved=True).update(moderation_status='approved')
    Document.objects.filter(is_approved=False).exclude(
        moderation_status='rejected'
    ).update(moderation_status='pending')


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0004_document_moderation_status'),
    ]

    operations = [
        migrations.RunPython(sync_moderation, noop),
    ]
