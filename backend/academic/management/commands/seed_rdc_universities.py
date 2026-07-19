"""Charge le catalogue élargi des universités RDC (réf. MINESURSI)."""

from django.core.management.base import BaseCommand
from django.utils.text import slugify

from academic.models import Department, Faculty, Promotion, University
from academic.rdc_universities_data import DEFAULT_PROMOTIONS, RDC_UNIVERSITIES
from academic.slug_utils import unique_slug


class Command(BaseCommand):
    help = (
        'Intègre les universités RDC reconnues (catalogue Akadex / MINESURSI) '
        'avec facultés, départements et promotions LMD.'
    )

    def handle(self, *args, **options):
        created_unis = 0
        for uni_spec in RDC_UNIVERSITIES:
            uni, created = University.objects.update_or_create(
                slug=uni_spec['slug'],
                defaults={
                    'name': uni_spec['name'],
                    'city': uni_spec.get('city', ''),
                    'country': 'RD Congo',
                    'description': (
                        f"{uni_spec.get('sigle', '')} — établissement "
                        'd’enseignement supérieur en RDC (réf. registre MINESURSI).'
                    ).strip(' —'),
                    'is_active': True,
                    'is_verified': True,
                    'is_user_suggested': False,
                },
            )
            if created:
                created_unis += 1

            for fac_spec in uni_spec.get('faculties', []):
                fac_slug = fac_spec.get('slug') or slugify(fac_spec['name'])[:80]
                fac, _ = Faculty.objects.update_or_create(
                    university=uni,
                    slug=fac_slug,
                    defaults={
                        'name': fac_spec['name'],
                        'is_verified': True,
                        'is_user_suggested': False,
                    },
                )
                for dept_name in fac_spec.get('departments', []):
                    dept_slug = slugify(dept_name)[:80] or 'dept'
                    # éviter collision unique
                    if Department.objects.filter(
                        faculty=fac, slug=dept_slug
                    ).exclude(name=dept_name).exists():
                        dept_slug = unique_slug(
                            Department, dept_name, faculty=fac
                        )
                    dept, _ = Department.objects.update_or_create(
                        faculty=fac,
                        slug=dept_slug,
                        defaults={
                            'name': dept_name,
                            'is_verified': True,
                            'is_user_suggested': False,
                        },
                    )
                    year = 2025
                    for level, _order in DEFAULT_PROMOTIONS:
                        Promotion.objects.get_or_create(
                            department=dept,
                            name=f'{level} {dept_name} {year}–{year + 1}',
                            year=year,
                            defaults={
                                'level': level,
                                'is_verified': True,
                                'is_user_suggested': False,
                            },
                        )

        self.stdout.write(
            self.style.SUCCESS(
                f'Catalogue RDC OK — universités actives : '
                f'{University.objects.filter(is_active=True).count()} '
                f'(nouvelles : {created_unis})'
            )
        )
