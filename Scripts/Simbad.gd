# Definición de las habilidades de Simbad:

extends Spatial


# Array que contiene las descripciones de las habilidades:
var skillDescriptions = []

# Parámetros:
var currentHp
const MAX_HP = 12
export (NodePath) var myTotem
var modifier = 0
var costs = []
var ranges = []


func _ready():
	skillDescriptions.append("Alcance: 2\n\nInflige 2 puntos de daño a la\nentidad o tótem objetivo.")
	skillDescriptions.append("Alcance: sobre la entidad\n\nAumenta el daño de la\nsiguiente habilidad\nen un punto.\n(No puede acumularse)")
	skillDescriptions.append("Alcance: 2\n\nInflige 4 puntos de daño a la\nentidad o tótem objetivo.")
	
	costs.append(2)
	costs.append(2)
	costs.append(6)
	
	ranges.append(2)
	ranges.append(0)
	ranges.append(2)
	
	currentHp = MAX_HP


func TakeDamage(damage):
	currentHp -= damage
	if currentHp <= 0:
		Death()


func Death():
	get_node("Death").play()


# Definir las habilidades:
func Hability1(table, cell):
	get_node("Sword").play()
	var target = null
	
	for ent in table.keys():
		if table[ent] == cell:
			target = ent

	if target != null:
		if modifier != 0:
			target.TakeDamage(2 + modifier)
			modifier = 0
		else:
			target.TakeDamage(2)


func Hability2(table, cell):
	get_node("PowerUp").play()
	modifier = 1


func Hability3(table, cell):
	get_node("Sword").play()
	var target = null
	
	for ent in table.keys():
		if table[ent] == cell:
			target = ent

	if target != null:
		if modifier != 0:
			target.TakeDamage(4 + modifier)
			modifier = 0
		else:
			target.TakeDamage(4)


func _on_Death_finished():
	# Si mi entidad es la seleccionada, la deselecciono:
	if get_parent().selectedEntity == self:
		get_parent().DeselectAll()

	get_parent().table[self] = Vector2(-1,-1)
	get_node(myTotem).entityDead = true
	get_node(myTotem).remaining = 2
	get_parent().remove_child(self)
