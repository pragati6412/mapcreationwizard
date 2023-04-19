from django.shortcuts import render
from .forms import mapForm, ImageCoordinatesForm, first_image_coordinatesForm
from django.shortcuts import redirect
from .models import map, image_coordinates, transitions
import subprocess
from django import forms
# Create your views here.
graph_file_text="""
graph grid
{
	fontname="Helvetica,Arial,sans-serif"
	node [fontname="Helvetica,Arial,sans-serif" color="red" shape="circle" width=0.5 height=0.5 fontcolor="white"]
	edge [fontname="Helvetica,Arial,sans-serif"]
	layout=dot
	bgcolor="transparent"
	labelloc = "t"
	node [shape="circle" width=0.5 height=0.5]
    edge [weight=1000 style=bold color="blue"]

"""
def home(request):
    return render(request, 'makemap/home.html')

graph_file_text="""
graph grid
{
	fontname="Helvetica,Arial,sans-serif"
	node [fontname="Helvetica,Arial,sans-serif" color="red" shape="circle" width=0.5 height=0.5 fontcolor="white"]
	edge [fontname="Helvetica,Arial,sans-serif"]
	layout=dot
	bgcolor="transparent"
	labelloc = "t"
	node [shape="circle" width=0.5 height=0.5]
    edge [weight=1000 style=bold color="blue"]
"""

def map_creation(request):
    form= mapForm()
    if request.method == 'POST':
        form = mapForm(request.POST)
        if form.is_valid():
            current_map = form.save()
            request.session['current_map'] = current_map.pk
            return redirect('first_image_coordinates')
        
    return render(request, 'makemap/map_creation.html', {'form':form})



def first_image_coordinates(request):
    form = first_image_coordinatesForm()
    current_map_pk = request.session.get('current_map')
    current_map = map.objects.get(pk=current_map_pk)

    if request.method == 'POST':
        form = first_image_coordinatesForm(request.POST)
        if form.is_valid():
            image = form.save(commit=False)
            image.x_coordinate = 0
            image.y_coordinate = 0
            image.map = current_map_pk
            image.new_image_name = str(image.x_coordinate) + "_" + str(image.y_coordinate)
            image.save()
            with open("static/makemap/graph.dot", "w") as text_file:
                text_file.write(graph_file_text)
                text_file.write("\t" + image.image_name + ";\n")
                text_file.write("}\n")
            request.session['current_map'] = current_map.pk
            # add entry of old image name and new image name in csv file
            with open("static/makemap/grid.csv", "w") as text_file:
                text_file.write(image.image_name + "," + image.new_image_name + "\n")
            # empty the transitions table
            with open("static/makemap/transitions.csv", "w") as text_file:
                text_file.write("")
            # run the graphviz command to create the image
            subprocess.call(["dot", "-Tsvg", "static/makemap/graph.dot", "-o", "static/makemap/graph.svg"])
            return redirect('image_coordinates')

    return render(request, 'makemap/first_image_coordinates.html', {'form': form})


def image_coordinates1(request):
    current_map_pk = request.session.get('current_map')
    prev_img_dict=None
    class ImageCoordinatesForm(forms.ModelForm):
        previous_image= forms.ModelChoiceField(queryset=image_coordinates.objects.filter(map=current_map_pk))
        #make the previous image dictionary
        
        # print(image_coordinates.objects.filter(map=current_map_pk).values_list('image_name', flat=True))
        class Meta:
            model = image_coordinates
            fields = ['image_name', 'direction']
            
    image_coordinatesForm= ImageCoordinatesForm()
    if request.method == 'POST':
        form = ImageCoordinatesForm(request.POST)
        if form.is_valid():
            previous_image= form.cleaned_data['previous_image']
            previous_image= image_coordinates.objects.get(image_name=previous_image)
            new_image=form.save(commit=False)
            new_image.map= current_map_pk
            direction= form.cleaned_data['direction']
            delta_x= 0
            delta_y=0
            
            # find the point in graph file where } is present and start writing from there (reaplace } with new node and })
            file=open("static/makemap/graph.dot",'r')
            data= file.read()
            file.close()
            
            # erase the last }
            while(data[-1] != '}'):
                data= data[:-1]
            data= data[:-1]
            if direction== 'N':
                delta_y=22
                
                data += "\t"+new_image.image_name+" -- "+previous_image.image_name+";\n"
            elif direction== 'S':
                delta_y=-22
                data += "\t"+previous_image.image_name+" -- "+new_image.image_name+";\n"
            elif direction== 'E':
                delta_x=22
                data += "\t"+"rank=same {"+previous_image.image_name+" -- "+new_image.image_name+"};\n"
            elif direction== 'W':
                delta_x=-22
                data += "\t"+"rank=same {"+new_image.image_name+" -- "+previous_image.image_name+"};\n"
            data += "}"
            
            file=open("static/makemap/graph.dot",'w')
            file.write(data)
            file.close()
            
            new_image.x_coordinate= previous_image.x_coordinate+delta_x
            new_image.y_coordinate= previous_image.y_coordinate+delta_y
            new_image.new_image_name= str(new_image.x_coordinate)+"_"+str(new_image.y_coordinate)
            new_image.save()
            # add entry of old image name and new image name in csv file
            with open("static/makemap/grid.csv", "a") as text_file:
                text_file.write(new_image.image_name + "," + new_image.new_image_name + "\n")
            # add an entry of transition front previous image to new image in csv file
            with open("static/makemap/transitions.csv", "a") as text_file:
                text_file.write(previous_image.image_name + "," + new_image.image_name + "\n")
            # run the graphviz command to create the image
            subprocess.call(["dot", "-Tsvg", "static/makemap/graph.dot", "-o", "static/makemap/graph.svg"])
            return redirect('image_coordinates')
    return render(request, 'makemap/image_coordinates.html', {'form':image_coordinatesForm})
