# Este script controla el lanzamiento de las habilidades:

extends Spatial

# La mitad del tamaño de la celda:
const cellsize = 0.5
# La altura a la que se deben instanciar las partículas:
const particleHeight = 2.486

# Referencia a las particulas:
var particles


func _ready():
	particles = load("res://Prefabs/Particles.tscn")


# Convierte el número de una casilla a coordenadas de celda:
func ToCellCoordinates(n):
	var local_n = n - 1
	var fil = local_n / 5
	return Vector2(fil, local_n - fil * 5)


# Sive para comprobar si puedes atacar según tu rango:
func CanIAttack(entity, coords, energy, skill):
	var table = get_parent().table
	# Comprobar que tengo la suficiente energia para lanzar esa habilidad:
	if energy < entity.costs[skill-1]:
		return false

	# Comprobar si la casilla pulsada está dentro del rango:
	var dst = abs(table[entity][0] - coords[0]) + abs(table[entity][1] - coords[1])
	if entity.ranges[skill-1] == 0:
		return dst == entity.ranges[skill-1]
	else:
		return dst <= entity.ranges[skill-1] and dst > 0


func Attack(entity, pos, energy, skill):
	# Obtener el número de la casilla clicada:
	var n = int(pos.name.replace("n", ""))
	
	# Obtener las coordenadas de la celda:
	var coords = ToCellCoordinates(n)

	if CanIAttack(entity, coords, energy, skill):
		match skill:
			1:
				entity.Hability1(get_parent().table, coords)
			2:
				entity.Hability2(get_parent().table, coords)
			3:
				entity.Hability3(get_parent().table, coords)
		
		# Mostrar el efecto:
		var node = particles.instance()
		get_parent().add_child(node)
		node.global_transform.origin.x = pos.global_transform.origin.x - cellsize
		node.global_transform.origin.y = pos.global_transform.origin.y + cellsize
		node.global_transform.origin.z = pos.global_transform.origin.z - cellsize

		node.get_node("Particles").emitting = true
		
		return true
	return false