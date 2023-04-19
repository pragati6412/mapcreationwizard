from django.contrib import admin
from .models import map, image_coordinates, transitions
# Register your models here.
admin.site.register(map)
admin.site.register(image_coordinates)
admin.site.register(transitions)
