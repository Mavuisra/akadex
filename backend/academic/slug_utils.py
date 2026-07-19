from django.utils.text import slugify


def unique_slug(model, base: str, *, field='slug', **filters) -> str:
    """Génère un slug unique pour un modèle donné."""
    root = slugify(base)[:180] or 'item'
    candidate = root
    n = 2
    while model.objects.filter(**{field: candidate}, **filters).exists():
        candidate = f'{root}-{n}'
        n += 1
    return candidate
