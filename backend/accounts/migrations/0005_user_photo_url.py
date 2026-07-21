# Generated manually for photo_url

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0004_messaging_realtime_voice'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='photo_url',
            field=models.URLField(blank=True, max_length=500),
        ),
    ]
