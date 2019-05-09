extends Control

var mainGame


func _ready():
	OS.window_fullscreen = true


func _input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		get_tree().quit()

func _on_PartidaIA_pressed():
	get_tree().change_scene("res://Scenes/MainGame.tscn")


func _on_Salir_pressed():
	get_tree().quit()