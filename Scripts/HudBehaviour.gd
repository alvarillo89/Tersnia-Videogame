# Este script contiene el comportamiento del hud

extends Control

var mainScene


func _ready():
	mainScene = get_parent()


# Cuando se pulsa el botón de pasar turno:
func _on_SkipTurnButton_pressed():
	mainScene.get_node("TurnManager").pass_turn()
	# Resetear el timer:
	var timer = mainScene.get_node("TurnManager/Timer") 
	timer.stop()
	timer.wait_time = 6.0
	timer.start()

