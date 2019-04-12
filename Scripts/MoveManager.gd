# Este script controla el movimiento de las entidades por el 
# tablero.

extends Spatial

var entities

const ray_length = 1000

# Cuanto me da el cristal de movmiento:
var energy = 3

# Para el raycast:
var from
var to
var input = false

# La entidad activa:
var selectedEntity

# La mitad del tamaño de la celda:
const cellsize = 0.57


func to_cell_coordinates(n):
	var local_n = n - 1
	var fil = local_n / 5
	return Vector2(fil, local_n - fil * 5)


func canIMove(coords):
	# Comprobar que no haya ninguna entidad en esa casilla:
	for v in entities.values():
		if v == coords:
			return false 

	# Comprobar que tengo la suficiente energía: (distancia manhattam):
	var dst = abs(entities[selectedEntity][0] - coords[0]) + abs(entities[selectedEntity][1] - coords[1])
	return dst == energy


func _ready():
	selectedEntity = null
	
	# Constuir el diccionario en el que la clave será una entidad
	# y el valor será su posición en coordenadas de celda:
	entities = {
		get_parent().get_node("BoneGolem"): Vector2(1,1),
		get_parent().get_node("Simbad"): Vector2(1,3),
		get_parent().get_node("EnemySimbad"): Vector2(8,1),
		get_parent().get_node("EnemyRobot"): Vector2(8,3)
	}


func _input(event):
	# Obtener las posiciones en las que lanzar el raycast cuando se pulsa el
	# botón
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var camera = get_parent().get_node("Camera")
		from = camera.project_ray_origin(event.position)
		to = from + camera.project_ray_normal(event.position) * ray_length
		input = true
	
	# Si pulsas escape se deselecciona la entidad:
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		selectedEntity.get_node("Arrow").visible = false
		selectedEntity = null


func _physics_process(delta):
	# Lanzar el raycast:
	if input:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)

		# Si ha impactado en algo:
		if not result.empty():
			var node = result["collider"].get_parent()
			
			# Ha seleccionado una entidad:
			if 'pj' in node.name:
				# Desactivar la flecha indicadora:
				if selectedEntity != null:
					selectedEntity.get_node("Arrow").visible = false

				selectedEntity = node.get_parent()
				selectedEntity.get_node("Arrow").visible = true

			# Ha seleccionado una casilla:
			elif 'n' in node.name and selectedEntity != null:
				var n = int(node.name.replace("n", "")) # Obtener el número de celda.
				
				# Comprobar si es una posición válida:
				var new_coords = to_cell_coordinates(n)

				if canIMove(new_coords):
					entities[selectedEntity] = new_coords
					var targetPos = node.global_transform.origin
					selectedEntity.global_transform.origin.x = targetPos.x - cellsize
					selectedEntity.global_transform.origin.z = targetPos.z - cellsize

		input = false
