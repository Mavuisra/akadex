"""URLs média sûres (local /media/ ou Supabase S3 déjà absolu)."""


def absolute_media_url(url: str | None, request=None) -> str:
    """Ne pas préfixer une URL Supabase déjà absolue avec le host Django."""
    if not url:
        return ''
    text = str(url).strip()
    if not text:
        return ''
    if text.startswith('http://') or text.startswith('https://'):
        return text
    if request is not None:
        return request.build_absolute_uri(text)
    return text


def file_field_url(file_field, request=None) -> str:
    if not file_field:
        return ''
    try:
        return absolute_media_url(file_field.url, request)
    except ValueError:
        return ''
