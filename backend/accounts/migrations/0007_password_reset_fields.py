from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('accounts', '0006_push_device_token'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='password_reset_expires',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='user',
            name='password_reset_token',
            field=models.CharField(blank=True, max_length=64),
        ),
    ]
