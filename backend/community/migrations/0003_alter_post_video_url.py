# Generated manually for longer social video URLs

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('community', '0002_alumni_and_learning'),
    ]

    operations = [
        migrations.AlterField(
            model_name='post',
            name='video_url',
            field=models.URLField(blank=True, max_length=1000),
        ),
    ]
