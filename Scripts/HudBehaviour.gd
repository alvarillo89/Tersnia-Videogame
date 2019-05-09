# Este script contiene el comportamiento del hud

extends Control

var mainScene

# Referencias a los textos de las habilidades:
var hab1
var hab2
var hab3
var hab1cost
var hab2cost
var hab3cost

# Referencias a los botones:
var buttonHab1
var buttonHab2
var buttonHab3

# Referencias a las barras:
var simbadHP
var simbadTotem
var boneHP
var boneTotem
var robotHP
var robotTotem
var skeletonHP
var skeletonTotem


func _ready():
	mainScene = get_parent()
	hab1 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer/Hab1Text")
	hab2 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer2/Hab2Text")
	hab3 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer3/Hab3Text")
	hab1cost = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/Label2")
	hab2cost = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/Label2")
	hab3cost = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/Label2")
	buttonHab1 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ButtonHab1")
	buttonHab2 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/ButtonHab2")
	buttonHab3 = get_node("Skills Related/Panel/MarginContainer/HBoxContainer/VBoxContainer3/HBoxContainer/ButtonHab3")
	
	# Preparar las barras de vida:
	simbadHP = get_node("Player Stats/VBoxContainer/SimbadHP")
	simbadTotem = get_node("Player Stats/VBoxContainer/TotemSimbadHP")
	boneHP = get_node("Player Stats/VBoxContainer/BoneHP")
	boneTotem = get_node("Player Stats/VBoxContainer/TotemBoneHP")
	robotHP = get_node("AI Stats/VBoxContainer/RobotHP")
	robotTotem = get_node("AI Stats/VBoxContainer/TotemRobotHP")
	skeletonHP = get_node("AI Stats/VBoxContainer/SkeletonHP")
	skeletonTotem = get_node("AI Stats/VBoxContainer/TotemSkeletonHP")
	
	simbadHP.value = get_parent().get_node("Simbad").MAX_HP
	simbadHP.max_value = simbadHP.value
	simbadTotem.value = get_parent().get_node("TotemSimbad").hp
	simbadTotem.max_value = simbadTotem.value
	
	boneHP.value = get_parent().get_node("BoneGolem").MAX_HP
	boneHP.max_value = boneHP.value
	boneTotem.value = get_parent().get_node("TotemBoneGolem").hp
	boneTotem.max_value = boneTotem.value
	
	skeletonHP.value = get_parent().get_node("EnemySkeleton").MAX_HP
	skeletonHP.max_value = skeletonHP.value
	skeletonTotem.value = get_parent().get_node("EnemyTotemSkeleton").hp
	skeletonTotem.max_value = skeletonTotem.value
	
	robotHP.value = get_parent().get_node("EnemyRobot").MAX_HP
	robotHP.max_value = robotHP.value
	robotTotem.value = get_parent().get_node("EnemyTotemRobot").hp
	robotTotem.max_value = robotTotem.value


func _process(delta):
	if get_parent().get_node("Simbad") != null:
		simbadHP.value = get_parent().get_node("Simbad").currentHp
	else:
		simbadHP.value = 0
		
	if get_parent().get_node("TotemSimbad") != null:
		simbadTotem.value = get_parent().get_node("TotemSimbad").hp
	else:
		simbadTotem.value = 0
	
	if get_parent().get_node("BoneGolem") != null:
		boneHP.value = get_parent().get_node("BoneGolem").currentHp
	else:
		boneHP.value = 0
	
	if get_parent().get_node("TotemBoneGolem") != null:
		boneTotem.value = get_parent().get_node("TotemBoneGolem").hp
	else:
		boneTotem.value = 0
		
	if get_parent().get_node("EnemySkeleton") != null:
		skeletonHP.value = get_parent().get_node("EnemySkeleton").currentHp
	else:
		skeletonHP.value = 0
	
	if get_parent().get_node("EnemyTotemSkeleton") != null:
		skeletonTotem.value = get_parent().get_node("EnemyTotemSkeleton").hp
	else:
		skeletonTotem.value = 0
	
	if get_parent().get_node("EnemyRobot") != null:
		robotHP.value = get_parent().get_node("EnemyRobot").currentHp
	else:
		robotHP.value = 0
	
	if get_parent().get_node("EnemyTotemRobot") != null:
		robotTotem.value = get_parent().get_node("EnemyTotemRobot").hp
	else:
		robotTotem.value = 0


func resetHabPanel():
	mainScene.selectedSkill = null
	hab1.text = ""
	hab2.text = ""
	hab3.text = ""
	hab1cost.text = "-"
	hab2cost.text = "-"
	hab3cost.text = "-"
	buttonHab1.set_pressed(false)
	buttonHab2.set_pressed(false)
	buttonHab3.set_pressed(false)


func changeHabPanelStatus(newStatus : bool):
	buttonHab1.disabled = !newStatus
	buttonHab2.disabled = !newStatus
	buttonHab3.disabled = !newStatus


func setSkillDescriptions(entity):
	hab1cost.text = str(entity.costs[0])
	hab2cost.text = str(entity.costs[1])
	hab3cost.text = str(entity.costs[2])
	hab1.text = entity.skillDescriptions[0]
	hab2.text = entity.skillDescriptions[1]
	hab3.text = entity.skillDescriptions[2]


# Cuando se pulsa el botón de pasar turno:
func _on_SkipTurnButton_pressed():
	mainScene.get_node("TurnManager").PassTurn()
	# Resetear el timer:
	var timer = mainScene.get_node("TurnManager/Timer") 
	timer.stop()
	timer.wait_time = 20.0
	timer.start()


func _on_ButtonHab1_toggled(button_pressed):
	get_node("HabSelect").play()
	if button_pressed:
		mainScene.selectedSkill = 1
		buttonHab2.set_pressed(false)
		buttonHab3.set_pressed(false)
	
		# Deseleccionar la gema de movimiento:
		if mainScene.selectedGem != null:
			mainScene.selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
			mainScene.selectedGem = null


func _on_ButtonHab2_toggled(button_pressed):
	get_node("HabSelect").play()
	if button_pressed:
		mainScene.selectedSkill = 2
		buttonHab1.set_pressed(false)
		buttonHab3.set_pressed(false)
	
		# Deseleccionar la gema de movimiento:
		if mainScene.selectedGem != null:
			mainScene.selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
			mainScene.selectedGem = null


func _on_ButtonHab3_toggled(button_pressed):
	get_node("HabSelect").play()
	if button_pressed:
		mainScene.selectedSkill = 3
		buttonHab1.set_pressed(false)
		buttonHab2.set_pressed(false)
		
		# Deseleccionar la gema de movimiento:
		if mainScene.selectedGem != null:
			mainScene.selectedGem.get_node("mg").set_material_override(load("res://Art/Gems/m_MovGem.tres"))
			mainScene.selectedGem = null


func _on_ToMenu_pressed():
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
