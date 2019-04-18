# Controla todo el juego:

extends Spatial

# Este diccionario contiene toda la información sobre las entidades en juego:
var entities

# Este diccionario contiene toda la información sobre los totems en juego:
var totems

var canIAct

# Elementos seleccionados:
var selectedGem = null
var selectedEntity = null
var selectedSkill = null

# Gemas del jugador:
var movementGems = []
var skillGems = []

# Para el raycast:
var from
var to
var input = false
const ray_length = 1000

# Tipos de gemas:
var gemType
const MOVEMENT = 0
const SKILL = 1

# Espacio en pantalla entre dos gemas consecutivas:
const GEMS_OFFSET = 0.5

# Referencias:
var camera
var movInstancePos
var skiInstancePos


func _ready():
	# Aquí construimos los diccionario de forma estática, en caso de que
	# exista selección de personajes, deberían crearse en función de los
	# personajes seleccionados:
	entities = {
		get_node("BoneGolem"): {
				'pos': Vector2(1,1),
				'ingame': true,
				#'hp': get_node("BoneGolem").HP,
				'hp': 10,
				'dead': false,
				'turnsRemainig': 0
			},
		get_node("Simbad"): {
				'pos': Vector2(1,3),
				'ingame': true,
				#'hp': get_node("Simbad").HP,
				'hp': 10,
				'dead': false,
				'turnsRemainig': 0
			},
		get_node("EnemyRobot"): {
				'pos': Vector2(8,3),
				'ingame': true,
				#'hp': get_node("EnemyRobot").HP,
				'hp': 10,
				'dead': false,
				'turnsRemainig': 0
			},
		get_node("EnemySimbad"): {
				'pos': Vector2(8,1),
				'ingame': true,
				#'hp': get_node("EnemySimbad").HP,
				'hp': 10,
				'dead': false,
				'turnsRemainig': 0
			}
	}
	
	canIAct = true
	camera = get_node("Camera")
	movInstancePos = get_node("MovementGemOrigin").global_transform.origin
	skiInstancePos = get_node("SkillGemOrigin").global_transform.origin
 

func _input(event):
	if canIAct:
		# Obtener los parámetros del raycast a lanzar:
		if event is InputEventMouseButton and event.pressed and event.button_index == 1:
			from = camera.project_ray_origin(event.position)
			to = from + camera.project_ray_normal(event.position) * ray_length
			input = true
		
		# Deseleccionar las cosas:
		if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
			DeselectAll()


func _physics_process(delta):
	# Lanzar el raycast:
	if input:
		var node = ThrowRay()
		
		if node != null:
			match node.name:
				'pj':
					# Desactivar la entidad activa, en caso de que la haya:
					if selectedEntity != null:
						selectedEntity.get_node("Arrow").visible = false
					# Activar la nueva:
					selectedEntity = node.get_parent()
					selectedEntity.get_node("Arrow").visible = true
				'mg':
					# Desactivar la gema activa, en caso de que la haya:
					if selectedGem != null:
						if gemType == MOVEMENT:
							selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
						else:
							selectedGem.get_node("sg").set_material_override(load("res://Art/Gems/m_SkillGem.tres"))
					# Activar la nueva:
					node.set_material_override(load("res://Art/Gems/m_Gem_selected.tres"))
					selectedGem = node.get_parent()
					gemType = MOVEMENT
				'sg':
					# Desactivar la gema activa, en caso de que la haya:
					if selectedGem != null:
						if gemType == MOVEMENT:
							selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
						else:
							selectedGem.get_node("sg").set_material_override(load("res://Art/Gems/m_SkillGem.tres"))
					# Activar la nueva:
					node.set_material_override(load("res://Art/Gems/m_Gem_selected.tres"))
					selectedGem = node.get_parent()
					gemType = SKILL
				var def:
					if 'n' in def:
						# Ha clicado sobre una casilla
						# Para poder hacer una acción hay que tener una gema y una entidad:
						if selectedEntity != null and selectedGem != null:
							if gemType == MOVEMENT:
								var res = get_node("MoveManager").Move(selectedEntity, node, selectedGem.energy)
								# Si el movimiento tuvo éxito
								if res:
									# Borrar la gema de la mano del jugador:
									movementGems.erase(selectedGem)
									selectedGem.queue_free()
									selectedGem = null
									Draw()
							elif gemType == SKILL:
								# Si es una gema de skill, además se requiere que haya elegido una habilidad:
								if selectedSkill != null:
									pass


# Lanza un rayo, devuelve el objeto colisionado o null:
func ThrowRay():
	input = false
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(from, to)

	# Si ha impactado en algo:
	if not result.empty():
		return result["collider"].get_parent()
	else:
		return null


# Deselecciona todas las cosas seleccionadas:
func DeselectAll():
	if selectedEntity != null:
		selectedEntity.get_node("Arrow").visible = false
		selectedEntity = null

	if selectedGem != null:
		if gemType == MOVEMENT:
			selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
		else:
			selectedGem.get_node("sg").set_material_override(load("res://Art/Gems/m_SkillGem.tres"))
		selectedGem = null
		
	if selectedSkill != null:
		pass


# Dibuja las gemas:
func Draw():
	for i in range(len(movementGems)):
		var tmp = Vector3(i * GEMS_OFFSET, 0.0, i * GEMS_OFFSET)
		movementGems[i].global_transform.origin = movInstancePos + tmp
	
	for i in range(len(skillGems)):
		var tmp = Vector3(i * GEMS_OFFSET, 0.0, i * GEMS_OFFSET)
		skillGems[i].global_transform.origin = skiInstancePos + tmp