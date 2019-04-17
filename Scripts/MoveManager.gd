# Este script controla el movimiento de las entidades por el 
# tablero.

extends Spatial

# Diccionario con las entidades en juego y sus posiciones en el tablero:
var entities
# Cuanto me da el cristal de movmiento:
var energy
# Para el raycast:
var from
var to
var input = false
const ray_length = 1000
# La entidad activa:
var selectedEntity
# La gema activa:
var activeGem
# La mitad del tamaño de la celda:
const cellsize = 0.57

# Convierte el número de una casilla a coordenadas de celda:
func to_cell_coordinates(n):
	var local_n = n - 1
	var fil = local_n / 5
	return Vector2(fil, local_n - fil * 5)

# Sive para comprobar si puedes moverte hasta una coordenada concreta:
func canIMove(coords):
	# Comprobar que no haya ninguna entidad en esa casilla:
	for v in entities.values():
		if v == coords:
			return false 

	# Comprobar que tengo la suficiente energía: (distancia manhattam):
	var dst = abs(entities[selectedEntity][0] - coords[0]) + abs(entities[selectedEntity][1] - coords[1])
	return dst == energy


# Deselecciona la entidad y la gema seleccionadas:
func deselect_all():
	if selectedEntity != null:
			selectedEntity.get_node("Arrow").visible = false
			selectedEntity = null

	if activeGem != null:
		activeGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
		activeGem = null


func _ready():
	selectedEntity = null
	activeGem = null
	
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
	
	# Si pulsas escape se deseleccionan las cosas:
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		deselect_all()


func _physics_process(delta):
	# Lanzar el raycast:
	if input:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)

		# Si ha impactado en algo:
		if not result.empty():
			var node = result["collider"].get_parent()
			
			# Ha seleccionado una entidad:
			if 'pj' == node.name:
				# Desactivar la flecha indicadora:
				if selectedEntity != null:
					selectedEntity.get_node("Arrow").visible = false

				selectedEntity = node.get_parent()
				selectedEntity.get_node("Arrow").visible = true

			# Ha seleccionado una gema:
			elif node.name == 'mg':
				# Desactivar la gema activa, en caso de que la haya:
				if activeGem != null:
					activeGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))

				node.set_material_override(load("res://Art/Gems/m_Gem_selected.tres"))
				activeGem = node.get_parent()
				energy = activeGem.energy

			# Ha seleccionado una casilla:
			elif 'n' in node.name and selectedEntity != null and activeGem != null:
				var n = int(node.name.replace("n", "")) # Obtener el número de celda.
				
				# Comprobar si es una posición válida:
				var new_coords = to_cell_coordinates(n)

				if canIMove(new_coords):
					# Actualizar la posición en este script:
					entities[selectedEntity] = new_coords
					# Mover a la entidad:
					var targetPos = node.global_transform.origin
					selectedEntity.global_transform.origin.x = targetPos.x - cellsize
					selectedEntity.global_transform.origin.z = targetPos.z - cellsize
					# Eliminar la gema de la mano del jugador:
					get_parent().get_node("TurnManager").movementGems.erase(activeGem)
					activeGem.queue_free()
					activeGem = null
					get_parent().get_node("TurnManager").draw()

		input = false
