# Este script sirve para que la etiqueta de texto se muestre
# encima de la gema:

extends Spatial

# La energía que proporciona la gema:
var energy
# Referencias a la etiqueta y la cámara:
var label
var camera

func _ready():
	camera = get_parent().get_node("Camera")
	label = get_node("Label")
	label.text = str(energy)

func _process(delta):
	var pos = camera.unproject_position(global_transform.origin)
	label.rect_position = pos - (label.rect_size / 2)