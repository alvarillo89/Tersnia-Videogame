# Controla los turnos del juego:

extends Spatial

# Turno actual: 0 -> jugador 1 -> IA
var turn = 0

# Número de gemas:
const INITIAL_GEMS = 3
const PER_TURN_GEMS = 2

# Referencias:
var timeLabel
var currentPlayerLabel

var movementGems
var movGemScene

var skillGems
var skillGemScene


func _ready():
	# Cargar los recursos:
	movementGems = get_parent().movementGems
	skillGems = get_parent().skillGems
	movGemScene = load("res://Prefabs/Movement Gem.tscn")
	skillGemScene = load("res://Prefabs/SkillGem.tscn")
	timeLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Time Label")
	currentPlayerLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Turn Label")
	
	# En principio el jugador es quién empieza:
	for i in range(INITIAL_GEMS):
		call_deferred("NewPlayerTurn")
		
	get_node("Timer").start()


# Se llama en cada nuevo turno del jugador:
func NewPlayerTurn():
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
		get_parent().Draw()
	
	if len(skillGems) < 10:
		var node = skillGemScene.instance()
		
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

		skillGems.append(node)
		get_parent().add_child(node)
		get_parent().Draw()


# Pasa el turno:
func PassTurn():
	turn = (turn + 1)  % 2
	
	# Si es el turno del jugador:
	if turn == 0:
		get_parent().canIAct = true
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = false
		currentPlayerLabel.text = "JUGADOR"
		
		# Añadir gemas nuevas:
		for i in range(PER_TURN_GEMS):
			NewPlayerTurn()
	else:
		get_parent().DeselectAll()
		get_parent().canIAct = false
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = true
		currentPlayerLabel.text = "CPU"


func _process(delta):
	# Actualizar la etiqueta del timer:
	var m = str(int(get_node("Timer").time_left / 60))
	var s = str(int(get_node("Timer").time_left) % 60)
	if len(s) == 1:
		s = '0' + s
	timeLabel.text = str(int(m)) + ':' + str(s)


func _on_Timer_timeout():
	PassTurn()
	get_node("Timer").start()