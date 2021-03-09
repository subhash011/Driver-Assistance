from django.db import models

# Create your models here.


class Coordinate(models.Model):
    lat = models.FloatField(verbose_name='Latitude')
    lon = models.FloatField(verbose_name='Longitude')

    def __str__(self):
        return f'({self.lat}, {self.lon})'

