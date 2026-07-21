from rest_framework.pagination import PageNumberPagination


class FlexiblePagination(PageNumberPagination):
    """Pagination DRF avec page_size configurable côté client (max 200)."""

    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 200
