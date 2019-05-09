# Controla el comportamiento de los totems:

extends Spatial

export (int) var hp
export (NodePath) var myEntity
export (int) var myTurn

var entity
var entityDead
var remaining
var spawn

export (Vector2) var spawnPos

func _ready():
	entityDead = false
	remaining = 0
	entity = get_node(myEntity)
	spawn = toMesh(spawnPos)
	get_parent().get_node("TurnManager").connect("turn_passed", self, "_on_Turn_Passed")


func toMesh(cell):
	return get_node('../Table/n' + str(cell[0] * 5 + cell[1] + 1))


func Death():
	get_node("Death").play()


func TakeDamage(damage):
	hp -= damage
	if hp <= 0:
		Death()


func Spawn():
	get_node("Spawn").play()
	var table = get_parent().table
	entityDead = false
	entity.currentHp = entity.MAX_HP
	get_parent().add_child(entity)
	
	# Comprobar si el spawn esta libre:
	if not table.values().has(spawnPos):
		get_parent().get_node("MoveManager").Move(entity, spawn, 1000, true)
		get_parent().table[myEntity] = spawnPos
	else:
		# Buscamos la entidad que nos está estorbando:
		var target
		for entity in table.keys():
			if table[entity] == spawnPos:
				target = entity

		# En función del lado del tablero, probamos nuevas posiciones:
		var mod = 1 if myTurn == 0 else -1

		# Probamos con la posición anterior:
		var newSpawnPos = spawnPos
		newSpawnPos.x += mod

		if not table.values().has(newSpawnPos):
			get_parent().get_node("MoveManager").Move(target, toMesh(newSpawnPos), 1000, true)
			get_parent().get_node("MoveManager").Move(entity, spawn, 1000, true)
			get_parent().table[myEntity] = spawnPos
			get_parent().table[target] = newSpawnPos
		else:
			newSpawnPos = spawnPos
			newSpawnPos.y += 1

			if not table.values().has(newSpawnPos):
				get_parent().get_node("MoveManager").Move(target, toMesh(newSpawnPos), 1000, true)
				get_parent().get_node("MoveManager").Move(entity, spawn, 1000, true)
				get_parent().table[myEntity] = spawnPos
				get_parent().table[target] = newSpawnPos
			else:
				newSpawnPos = spawnPos
				newSpawnPos.y -= 1
	
				if not table.values().has(newSpawnPos):
					get_parent().get_node("MoveManager").Move(target, toMesh(newSpawnPos), 1000, true)
					get_parent().get_node("MoveManager").Move(entity, spawn, 1000, true)
					get_parent().table[myEntity] = spawnPos
					get_parent().table[target] = newSpawnPos


func _on_Turn_Passed(turn):
	if turn == myTurn:
		if entityDead:
			remaining -= 1
	else:
		if remaining <= 0 and entityDead:
			Spawn()


func _on_Death_finished():
	# Si mi entidad es la seleccionada, la deselecciono:
	if get_path_to(get_parent().selectedEntity) == myEntity:
		get_parent().DeselectAll()

	# Anotar la muerte del tótem:
	get_parent().destroyed[myTurn] += 1
	# Quitar las cosas del tablero:
	get_parent().table[self] = Vector2(-1,-1)
	get_parent().table[myEntity] = Vector2(-1,-1)
	# Borrar:
	if not entityDead:
		get_node(myEntity).queue_free()
	self.queue_free()