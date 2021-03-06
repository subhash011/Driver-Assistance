from rest_framework.viewsets import ModelViewSet
from .serializers import CoordinateSerializer
from .models import Coordinate


class CoordinateViewSet(ModelViewSet):

    queryset = Coordinate.objects.all()
    serializer_class = CoordinateSerializer

