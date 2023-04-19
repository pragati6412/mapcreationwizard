from django.db import models

# Create your models here.
class map(models.Model):
    map_name = models.CharField(max_length=100)
    # array of image names
    
    def __str__(self):
        return self.map_name
    

class image_coordinates(models.Model):
    map= models.IntegerField()
    image_name = models.CharField(max_length=100)
    x_coordinate = models.IntegerField()
    y_coordinate = models.IntegerField()
    new_image_name = models.CharField(max_length=100)
    direction_choices = (('N','N'), ('S','S'), ('E','E'), ('W','W'))
    direction = models.CharField(max_length=1, choices=direction_choices, blank=True, null=True)
    def __str__(self):
        return self.image_name
    
class transitions(models.Model):
    image_name_1= models.CharField(max_length=100)
    image_name_2= models.CharField(max_length=100)
    
    def __str__(self):
        return self.image_name_1+" "+self.image_name_2

    
    