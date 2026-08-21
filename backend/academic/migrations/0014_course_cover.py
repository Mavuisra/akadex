from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0013_documentpeervalidation_score'),
    ]

    operations = [
        migrations.AddField(
            model_name='course',
            name='cover',
            field=models.ImageField(
                blank=True,
                help_text='Image de couverture uploadée',
                null=True,
                upload_to='course_covers/',
            ),
        ),
    ]
