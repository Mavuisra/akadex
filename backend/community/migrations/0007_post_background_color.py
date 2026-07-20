from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0006_academic_share_attachments'),
    ]

    operations = [
        migrations.AddField(
            model_name='post',
            name='background_color',
            field=models.CharField(blank=True, default='', max_length=16),
        ),
    ]
