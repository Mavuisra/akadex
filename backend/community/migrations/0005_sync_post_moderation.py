from django.db import migrations


def sync_post_moderation(apps, schema_editor):
    Post = apps.get_model('community', 'Post')
    Post.objects.filter(is_approved=True).update(moderation_status='approved')
    Post.objects.filter(is_approved=False).exclude(
        moderation_status='rejected'
    ).update(moderation_status='pending')


def noop(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0004_post_moderation_status'),
    ]

    operations = [
        migrations.RunPython(sync_post_moderation, noop),
    ]
