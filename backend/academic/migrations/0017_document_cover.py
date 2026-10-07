# Generated manually for document cover images

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('academic', '0016_document_pricing_and_purchase'),
    ]

    operations = [
        migrations.AddField(
            model_name='document',
            name='cover_url',
            field=models.URLField(
                blank=True,
                help_text='Image de couverture (URL publique)',
                max_length=500,
            ),
        ),
        migrations.AddField(
            model_name='document',
            name='cover',
            field=models.ImageField(
                blank=True,
                help_text='Image de couverture uploadée',
                null=True,
                upload_to='document_covers/',
            ),
        ),
    ]
