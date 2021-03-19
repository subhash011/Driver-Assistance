from django.urls import path
from rest_framework.routers import SimpleRouter
from . import views


router = SimpleRouter()
router.register('coordinates', views.CoordinateViewSet)

urlpatterns = [
    path('obstacles/', views.FindObstacles.as_view(), name='findObstacle')
]

urlpatterns += router.urls

