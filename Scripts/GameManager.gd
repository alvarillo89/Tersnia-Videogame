# Controla todo el juego:

extends Spatial

# Este diccionario contiene la posición de entidades y totems en el juego:
var table

# Este booleano determina si el jugador puede interactuar con las cosas o no.
var canIAct

# Elementos seleccionados:
var selectedGem = null
var selectedEntity = null
var selectedSkill = null

# Almacena el número de Tótems destruidos por cada jugador:
var destroyed = [0,0]
var gameOver = false

# Gemas del jugador:
var movementGems = []
var skillPA = 0

# Para el raycast:
var from
var to
var input = false
const ray_length = 1000

# Espacio en pantalla entre dos gemas consecutivas:
const GEMS_OFFSET = 0.5

# Referencias:
var camera
var movInstancePos

func _ready():
	# Aquí construimos el diccionario de forma estática, en caso de que
	# exista selección de personajes, debería crearse en función de los
	# personajes seleccionados:
	table = {
		get_node("BoneGolem"): Vector2(1,1),
		get_node("Simbad"): Vector2(1,3),
		get_node("EnemyRobot"): Vector2(8,3),
		get_node("EnemySkeleton"): Vector2(8,1),
		get_node("TotemBoneGolem"): Vector2(0,1),
		get_node("TotemSimbad"): Vector2(0,3),
		get_node("EnemyTotemRobot"): Vector2(9,3),
		get_node("EnemyTotemSkeleton"): Vector2(9,1)
	}
	
	canIAct = true
	camera = get_node("Camera")
	movInstancePos = get_node("MovementGemOrigin").global_transform.origin


func _input(event):
	# Obtener los parámetros del raycast a lanzar:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1 and not gameOver:
		from = camera.project_ray_origin(event.position)
		to = from + camera.project_ray_normal(event.position) * ray_length
		input = true
	
	# Deseleccionar las cosas:
	if event is InputEventKey and event.pressed and event.scancode == KEY_D and not gameOver:
		get_node("Sound/Deselect").play()
		DeselectAll()
	
	# Quitar:
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		get_tree().quit()


func _process(delta):
	# Fin del juego:
	if not gameOver:
		if destroyed[0] == 2:
			get_node("Sound/MainSong").unit_db = 10.0
			get_node("Sound/Defeat").play()
			get_node("HUD/EndGame/CenterContainer/VBoxContainer/Result").text = "DERROTA..."
			get_node("HUD/EndGame").visible = true
			get_node("TurnManager/Timer").stop()
			canIAct = false
			gameOver = true
		elif destroyed[1] == 2:
			get_node("Sound/MainSong").unit_db = 10.0
			get_node("Sound/Victory").play()
			get_node("HUD/EndGame/CenterContainer/VBoxContainer/Result").text = "¡VICTORIA!"
			get_node("HUD/EndGame").visible = true
			get_node("TurnManager/Timer").stop()
			canIAct = false
			gameOver = true


func _physics_process(delta):
	# Lanzar el raycast:
	if input:
		var node = ThrowRay()
		
		if node != null:
			match node.name:
				'pj':
					get_node("Sound/Select").play()
					# Desactivar la entidad activa, en caso de que la haya:
					if selectedEntity != null:
						selectedEntity.get_node("Arrow").visible = false
					# Activar la nueva:
					selectedEntity = node.get_parent()
					selectedEntity.get_node("Arrow").visible = true
					get_node("HUD").setSkillDescriptions(selectedEntity)
				'mg':
					if canIAct:
						get_node("Sound/Gem").play()
						# Desactivar la gema activa, en caso de que la haya:
						if selectedGem != null:
							selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
						# Desactivar la habilidad activa:
						deselectSkill()
						# Activar la nueva:
						node.set_material_override(load("res://Art/Gems/m_Gem_selected.tres"))
						selectedGem = node.get_parent()
				var def:
					if canIAct:
						if 'n' in def:
							# Ha clicado sobre una casilla
							# Para poder hacer una acción hay que tener una gema y una entidad:
							if selectedEntity != null and selectedGem != null:
								var res = get_node("MoveManager").Move(selectedEntity, node, selectedGem.energy, false)
								# Si el movimiento tuvo éxito
								if res:
									get_node("Sound/Move").play()
									# Borrar la gema de la mano del jugador:
									movementGems.erase(selectedGem)
									selectedGem.queue_free()
									selectedGem = null
									Draw()
								else:
									get_node("Sound/Error").play()
							elif selectedEntity != null and selectedSkill != null:
								var cost = selectedEntity.costs[selectedSkill-1]
								var res = get_node("SkillManager").Attack(selectedEntity, node, skillPA, selectedSkill)
								if res:
									# Eliminar los puntos de ataque:
									skillPA -= cost
								else:
									get_node("Sound/Error").play()
									
								# Deseleccionar la habilidad tras lanzarla:
								deselectSkill()


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
		selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
		selectedGem = null
		
	selectedSkill = null
	get_node("HUD").resetHabPanel()


# Deselecciona la habilidad activa:
func deselectSkill():
	match selectedSkill:
		1:
			get_node("HUD/Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ButtonHab1").set_pressed(false)
		2:
			get_node("HUD/Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/ButtonHab2").set_pressed(false)
		3:
			get_node("HUD/Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ButtonHab3").set_pressed(false)

	selectedSkill = null


# Dibuja las gemas:
func Draw():
	for i in range(len(movementGems)):
		var tmp = Vector3(i * GEMS_OFFSET, 0.0, i * GEMS_OFFSET)
		movementGems[i].global_transform.origin = movInstancePos + tmp


func _on_MainSong_finished():
	get_node("Sound/MainSong").play()
