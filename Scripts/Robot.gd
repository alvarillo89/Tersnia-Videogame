# Definición de las habilidades del Robot:

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
	skillDescriptions.append("Alcance: 3\n\nInflige un punto de daño al tótem o entidad objetivo.")
	skillDescriptions.append("Alcance: 3\n\nCura dos puntos de vida\na la entidad objetivo")
	skillDescriptions.append("Alcance: Sobre la entidad\n\nCura a todas las entidades aliadas.")
	
	costs.append(1)
	costs.append(3)
	costs.append(6)
	
	ranges.append(3)
	ranges.append(3)
	ranges.append(0)
	
	currentHp = MAX_HP


func TakeDamage(damage):
	currentHp -= damage
	if currentHp <= 0:
		Death()


func Death():
	get_node("Death").play()


# Definir las habilidades:
func Hability1(table, cell):
	get_node("Drain").play()
	var target = null
	
	for ent in table.keys():
		if table[ent] == cell:
			target = ent

	if target != null:
		target.TakeDamage(1)


func Hability2(table, cell):
	get_node("PowerUp").play()
	# Con la habilidad no puedes curar a Totems:
	var target = null
	
	for ent in table.keys():
		if table[ent] == cell:
			target = ent
	
	if target != null:
		if not "Totem" in target.name:
			target.currentHp += 2
			if target.currentHp > target.MAX_HP:
				target.currentHp = target.MAX_HP


func Hability3(table, cell):
	get_node("Teleport").play()
	currentHp = MAX_HP
	
	if get_parent().has_node("EnemyTotemSkeleton"):
		if not get_parent().get_node("EnemyTotemSkeleton").entityDead:
			get_parent().get_node("EnemySkeleton").currentHp = get_parent().get_node("EnemySkeleton").MAX_HP


func _on_Death_finished():
	get_parent().table[self] = Vector2(-1,-1)
	get_node(myTotem).entityDead = true
	get_node(myTotem).remaining = 2
	get_parent().remove_child(self)
