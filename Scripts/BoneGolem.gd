# Definición de las habilidades de BoneGolem:

extends Spatial


# Array que contiene las descripciones de las habilidades:
var skillDescriptions = []

# Parámetros:
var currentHp
const MAX_HP = 10
export (NodePath) var myTotem
var modifier = 0
var costs = []
var ranges = []


func _ready():
	skillDescriptions.append("Alcance: 2\n\nInflige 2 puntos de daño a la\nentidad o tótem objetivo y cúrate\n1 punto de vida.")
	skillDescriptions.append("Alcance: sobre la entidad\n\nReduce el daño recibido por la\nsiguiente habilidad\nen un punto.\n(No puede acumularse)")
	skillDescriptions.append("Alcance: sobre la entidad\n\nRecupera un 40% de los puntos\nde salud perdidos.")
	
	costs.append(3)
	costs.append(2)
	costs.append(4)
	
	ranges.append(2)
	ranges.append(0)
	ranges.append(0)
	
	currentHp = MAX_HP


func TakeDamage(damage):
	if modifier != 0:
		currentHp -= (damage - modifier)
		modifier = 0
	else:
		currentHp -= damage

	if currentHp <= 0:
		Death()


func Death():
	get_node("Death").play()


# Definir las habilidades:
func Hability1(table, cell):
	get_node("Impact").play()
	var target = null
	
	for ent in table.keys():
		if table[ent] == cell:
			target = ent

	if target != null:
		target.TakeDamage(2)
		currentHp += 1
		if currentHp > MAX_HP:
			currentHp = MAX_HP


func Hability2(table, cell):
	get_node("PowerUp").play()
	modifier = 1


func Hability3(table, cell):
	get_node("PowerUp").play()
	var loss = MAX_HP - currentHp
	var percentage = int(loss * 0.4)
	currentHp += percentage
	if currentHp > MAX_HP:
		currentHp = MAX_HP


func _on_Death_finished():
	# Si mi entidad es la seleccionada, la deselecciono:
	if get_parent().selectedEntity == self:
		get_parent().DeselectAll()

	get_parent().table[self] = Vector2(-1,-1)
	get_node(myTotem).entityDead = true
	get_node(myTotem).remaining = 2
	get_parent().remove_child(self)
