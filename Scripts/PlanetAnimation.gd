# Anima el planeta del fondo:

extends MeshInstance

# Velocidad a la que rota:
var velocity = 4

func _process(delta):
	rotation_degrees.y += velocity * delta