from rest_framework.routers import SimpleRouter
from . import views


router = SimpleRouter()
router.register(prefix='api', viewset=views.CoordinateViewSet)

urlpatterns = []
urlpatterns += router.urls

