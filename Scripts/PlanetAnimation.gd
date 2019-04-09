extends MeshInstance

var velocity = 4

func _process(delta):
	rotation_degrees.y += velocity * delta

