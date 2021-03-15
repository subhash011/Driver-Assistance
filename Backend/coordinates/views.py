from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet
from rest_framework.views import APIView
from .serializers import CoordinateSerializer
from .models import Coordinate

import numpy as np
from scipy.interpolate import interp1d


class CoordinateViewSet(ModelViewSet):

    queryset = Coordinate.objects.all()
    serializer_class = CoordinateSerializer


class FindObstacles(APIView):

    def post(self, request, format=None):
        theshold = 1
        obstacles = np.array([np.array([obstacle.lat, obstacle.lon]) for obstacle in Coordinate.objects.all()])
        route_pts = np.array(request.data)
        route = interp1d(route_pts[:, 0], route_pts[:, 1])
        preds = route(obstacles[:, 0])
        labels = obstacles[:, 1]
        in_path_index = np.abs(preds-labels) < theshold
        in_path_obs = obstacles[in_path_index]
        return Response(in_path_obs)
