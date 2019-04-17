# Controla los turnos del juego:

extends Spatial

# Turno actual: 0 -> jugador 1 -> IA
var turn = 0
# Listas que almacenan las gemas del jugador:
var movementGems = []
# Referencias a objetos necesarios:
var movInstancePos
var movGemScene
var timeLabel
var currentPlayerLabel
var movementManager
# Espacio en pantalla entre dos gemas consecutivas:
const gems_offset = 0.5


# Dibuja las gemas:
func draw():
	for i in range(len(movementGems)):
		var tmp = Vector3(i * gems_offset, 0.0, i * gems_offset)
		movementGems[i].global_transform.origin = movInstancePos + tmp


# Se llama en cada nuevo turno del jugador:
func newPlayerTurn():
	# Añadir una nueva gema si no hay 10:
	if len(movementGems) < 10:
		var node = movGemScene.instance()
		
		# Determinar la energía:
		var prob = randf()
		
		if prob < 0.1:
			node.energy = 1
		elif prob < 0.35:
			node.energy = 2
		elif prob < 0.75:
			node.energy = 3
		elif prob < 0.9:
			node.energy = 4
		else:
			node.energy = 5

		movementGems.append(node)
		get_parent().add_child(node)
		draw()


# Pasa el turno:
func pass_turn():
	turn = (turn + 1)  % 2
	# Si es el turno del jugador:
	if turn == 0:
		get_parent().add_child(movementManager)
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = false
		currentPlayerLabel.text = "JUGADOR"
		for i in range(2):
			newPlayerTurn()
	else:
		movementManager.deselect_all()
		get_parent().remove_child(movementManager)
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = true
		currentPlayerLabel.text = "CPU"


func _ready():
	# Cargar los recursos:
	movementManager = get_parent().get_node("MoveManager")
	movInstancePos = get_parent().get_node("MovementGemOrigin").global_transform.origin
	movGemScene = load("res://Prefabs/Movement Gem.tscn")
	timeLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Time Label")
	currentPlayerLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Turn Label")
	
	# En principio el jugador es quién empieza:
	for i in range(3):
		call_deferred("newPlayerTurn")
		
	get_node("Timer").start()

func _process(delta):
	# Actualizar la etiqueta del timer:
	var m = str(int(get_node("Timer").time_left / 60))
	var s = str(int(get_node("Timer").time_left) % 60)
	if len(s) == 1:
		s = '0' + s
	timeLabel.text = str(int(m)) + ':' + str(s)

func _on_Timer_timeout():
	pass_turn()
	get_node("Timer").start()