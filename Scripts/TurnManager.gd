# Controla los turnos del juego:

extends Spatial

# Esta señal se emite cuando pasa un turno:
signal turn_passed(turn)

# Turno actual: 0 -> jugador 1 -> IA
var turn = 0

# Número de gemas:
const INITIAL_GEMS = 3
const PER_TURN_GEMS = 2
const LIMIT = 10

# Referencias:
var timeLabel
var currentPlayerLabel
var PALabel

var movGemScene

var lastSecond


func _ready():
	# Cargar los recursos:
	movGemScene = load("res://Prefabs/Movement Gem.tscn")
	timeLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Time Label")
	PALabel = get_parent().get_node("HUD/Action Points/CenterContainer/HBoxContainer/AP counter")
	currentPlayerLabel = get_parent().get_node("HUD/Turn related/HBoxContainer/Turn Label")
	
	# En principio el jugador es quién empieza:
	for i in range(INITIAL_GEMS):
		call_deferred("NewTurn")
		
	get_node("Timer").start()


# Devuelve la energía en función de una probabilidad:
func GetEnergy():
	var prob = randf()

	if prob < 0.1:
		return 1
	elif prob < 0.35:
		return 2
	elif prob < 0.75:
		return 3
	elif prob < 0.9:
		return 4
	else:
		return 5


# Se llama en cada nuevo turno:
func NewTurn():
	if turn == 0:
		# Añadir gemas de movimiento:
		if len(get_parent().movementGems) < LIMIT:
			var node = movGemScene.instance()
			node.energy = GetEnergy()
			get_parent().movementGems.append(node)
			get_parent().add_child(node)
			get_parent().Draw()
			
			# Añadir puntos de acción:
			get_parent().skillPA += GetEnergy()
			if get_parent().skillPA > LIMIT:
				get_parent().skillPA = LIMIT
	else:
		# TODO: Turno de la IA
		pass


# Pasa el turno:
func PassTurn():
	emit_signal("turn_passed", turn)
	turn = (turn + 1)  % 2
	
	# Si es el turno del jugador:
	if turn == 0:
		get_parent().get_node("Sound/PlayerTurn").play()
		get_parent().canIAct = true
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = false
		get_parent().get_node("HUD").changeHabPanelStatus(true)
		currentPlayerLabel.text = "JUGADOR"
		
		for i in range(PER_TURN_GEMS):
			NewTurn()
	else:
		get_parent().get_node("Sound/AITurn").play()
		get_parent().DeselectAll()
		get_parent().canIAct = false
		get_parent().get_node("HUD/Turn related/HBoxContainer/SkipTurnButton").disabled = true
		get_parent().get_node("HUD").changeHabPanelStatus(false)
		currentPlayerLabel.text = "CPU"
		
		for i in range(PER_TURN_GEMS):
			NewTurn()


func _process(delta):
	if not get_parent().gameOver:
		# Actualizar la etiqueta del timer:
		var m = str(int(get_node("Timer").time_left / 60))
		var s = str(int(get_node("Timer").time_left) % 60)
		if len(s) == 1:
			s = '0' + s
	
		timeLabel.text = str(int(m)) + ':' + str(s)
		
		# Actualizar los puntos de acción del jugador:
		PALabel.text = str(get_parent().skillPA)
		
		# Avisar cuando esta a punto de agotarse el turno:
		if 0 <= get_node("Timer").time_left and get_node("Timer").time_left <= 8 and turn == 0:
			if get_node("Timer").time_left <= (lastSecond - 1):
				get_parent().get_node("Sound/CountDown").play()
				lastSecond -= 1
		else:
			lastSecond = 8


func _on_Timer_timeout():
	PassTurn()
	get_node("Timer").start()