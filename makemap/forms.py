from django import forms
from .models import map, image_coordinates, transitions

class mapForm(forms.ModelForm):
    class Meta:
        model = map
        fields= ['map_name']

class first_image_coordinatesForm(forms.ModelForm):
    class Meta:
        model = image_coordinates
        fields= ['image_name']
        
        
class ImageCoordinatesForm(forms.ModelForm):
    previous_image = forms.ChoiceField(choices=[])

    class Meta:
        model = image_coordinates
        fields = ['image_name', 'direction']

    def __init__(self, map_instance, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['previous_image'].choices = image_coordinates.objects.filter(map=map_instance).values_list('image_name', flat=True)

