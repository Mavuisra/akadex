"""Endpoints de suggestion d'entités académiques (saisie libre)."""

from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Department, Faculty, Promotion, University
from .serializers import (
    DepartmentSerializer,
    FacultySerializer,
    PromotionSerializer,
    UniversitySerializer,
)
from .slug_utils import unique_slug


class SuggestUniversityView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        name = (request.data.get('name') or '').strip()
        city = (request.data.get('city') or '').strip()
        if len(name) < 2:
            return Response(
                {'name': 'Le nom de l’université est trop court.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        existing = University.objects.filter(name__iexact=name).first()
        if existing:
            return Response(UniversitySerializer(existing).data)
        uni = University.objects.create(
            name=name,
            slug=unique_slug(University, name),
            city=city or 'RD Congo',
            country='RD Congo',
            description='Suggestion utilisateur — en attente de validation MINESURSI.',
            is_active=True,
            is_verified=False,
            is_user_suggested=True,
        )
        return Response(
            UniversitySerializer(uni).data,
            status=status.HTTP_201_CREATED,
        )


class SuggestFacultyView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        name = (request.data.get('name') or '').strip()
        university_id = request.data.get('university')
        if len(name) < 2:
            return Response(
                {'name': 'Le nom de la faculté est trop court.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            uni = University.objects.get(pk=int(university_id))
        except (University.DoesNotExist, TypeError, ValueError):
            return Response(
                {'university': 'Université invalide.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        existing = Faculty.objects.filter(
            university=uni,
            name__iexact=name,
        ).first()
        if existing:
            return Response(FacultySerializer(existing).data)
        fac = Faculty.objects.create(
            university=uni,
            name=name,
            slug=unique_slug(Faculty, name, university=uni),
            is_verified=False,
            is_user_suggested=True,
        )
        return Response(
            FacultySerializer(fac).data,
            status=status.HTTP_201_CREATED,
        )


class SuggestDepartmentView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        name = (request.data.get('name') or '').strip()
        faculty_id = request.data.get('faculty')
        university_id = request.data.get('university')
        if len(name) < 2:
            return Response(
                {'name': 'Le nom du département est trop court.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        faculty = None
        try:
            if faculty_id not in (None, ''):
                faculty = Faculty.objects.filter(pk=int(faculty_id)).first()
        except (TypeError, ValueError):
            faculty = None

        if faculty is None and university_id not in (None, ''):
            try:
                uni = University.objects.filter(pk=int(university_id)).first()
            except (TypeError, ValueError):
                uni = None
            if uni:
                faculty, _ = Faculty.objects.get_or_create(
                    university=uni,
                    slug='generale',
                    defaults={
                        'name': 'Faculté générale',
                        'is_verified': False,
                        'is_user_suggested': True,
                    },
                )
        if faculty is None:
            return Response(
                {'faculty': 'Sélectionne d’abord une université (et une faculté si possible).'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing = Department.objects.filter(
            faculty=faculty,
            name__iexact=name,
        ).first()
        if existing:
            return Response(DepartmentSerializer(existing).data)
        try:
            dept = Department.objects.create(
                faculty=faculty,
                name=name,
                slug=unique_slug(Department, name, faculty=faculty),
                is_verified=False,
                is_user_suggested=True,
            )
        except Exception as exc:
            return Response(
                {'detail': f'Impossible de créer le département : {exc}'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(
            DepartmentSerializer(dept).data,
            status=status.HTTP_201_CREATED,
        )


class SuggestPromotionView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        name = (request.data.get('name') or '').strip()
        department_id = request.data.get('department')
        year = request.data.get('year') or timezone.now().year
        try:
            year = int(year)
        except (TypeError, ValueError):
            year = timezone.now().year
        if len(name) < 1:
            return Response(
                {'name': 'Le nom de la promotion est requis.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            dept = Department.objects.get(pk=int(department_id))
        except (Department.DoesNotExist, TypeError, ValueError):
            return Response(
                {'department': 'Département invalide.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        existing = Promotion.objects.filter(
            department=dept,
            name__iexact=name,
            year=year,
        ).first()
        if existing:
            return Response(PromotionSerializer(existing).data)
        promo = Promotion.objects.create(
            department=dept,
            name=name,
            year=year,
            level=name[:64],
            is_verified=False,
            is_user_suggested=True,
        )
        return Response(
            PromotionSerializer(promo).data,
            status=status.HTTP_201_CREATED,
        )
