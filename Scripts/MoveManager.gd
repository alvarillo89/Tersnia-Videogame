# Este script controla el movimiento de las entidades por el 
# tablero.

extends Spatial


# La mitad del tamaño de la celda:
const cellsize = 0.57


# Convierte el número de una casilla a coordenadas de celda:
func ToCellCoordinates(n):
	var local_n = n - 1
	var fil = local_n / 5
	return Vector2(fil, local_n - fil * 5)


# Sive para comprobar si puedes moverte hasta una coordenada concreta:
func CanIMove(entity, coords, energy):
	# Comprobar que no haya ninguna entidad en esa casilla:
	var table = get_parent().table
	for v in table.values():
		if v == coords:
			return false 

	# Comprobar que tengo la suficiente energía: (distancia manhattam):
	var dst = abs(table[entity][0] - coords[0]) + abs(table[entity][1] - coords[1])
	return dst == energy


func Move(entity, destiny, energy, forceMove):
	# Obtener el número de la casilla clicada:
	var n = int(destiny.name.replace("n", ""))
	
	# Obtener las coordenadas de la celda:
	var coords = ToCellCoordinates(n)

	if CanIMove(entity, coords, energy) or forceMove:
		# Actualizar la posición en el GameManager:
		get_parent().table[entity] = coords
		
		# Mover a la entidad:
		var targetPos = destiny.global_transform.origin
		entity.global_transform.origin.x = targetPos.x - cellsize
		entity.global_transform.origin.z = targetPos.z - cellsize
		
		return true
	
	return false