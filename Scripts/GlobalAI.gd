#######################################################################################
# Este script contiene la IA global del juego, esta dividida
# en dos niveles:
#	* El primer nivel decide la estrategia global, es decir,
#	  si las entidades deben atacar o replegarse. También
#	  reparte los recursos entre cada entidad.
#	* En el segundo nivel, cada entidad decide como jugar su
#	  turno de forma reactiva.
#######################################################################################

extends Spatial

# Gemas y puntos de acción de la IA:
var movementGems = []
var skillPA = 0

# Variables relacionadas con el Robot:
var robot
var robotTotem
var robotGems = []
var robotSkillPA = 0

# Variables relacionadas con el esqueleto:
var skeleton
var skeletonTotem
var skeletonGems = []
var skeletonSkillPA = 0

# Referencias a los enemigos:
var simbad
var simbadTotem
var boneGolem
var boneTotem

# Variables generales del juego:
var parent
var attack
var move

# Objeto de tipo A*
var movePlanner

# Contiene el órden en el que van a actuar las entidades:
# 0 -> Robot; 1 -> Skeleton; 2 -> Passar Turno
var turnOrder = []

# Almacena si un aliado tiene poca vida:
var robotLowHp = false
var skeletonLowHp = false

# Alamcena si un enemigo tiene poca vida:
var enemyLowHp = false

#######################################################################################

func _ready():
	parent = get_parent()
	
	# Referencias a los elementos de juego:
	robot = get_parent().get_node("EnemyRobot")
	robotTotem = get_parent().get_node("EnemyTotemRobot") 
	skeleton = get_parent().get_node("EnemySkeleton")
	skeletonTotem = get_parent().get_node("EnemyTotemSkeleton")
	simbad = get_parent().get_node("Simbad")
	simbadTotem = get_parent().get_node("TotemSimbad")
	boneGolem = get_parent().get_node("BoneGolem")
	boneTotem = get_parent().get_node("TotemBoneGolem")
	
	# Acciones de mover y atacar:
	move = funcref(get_parent().get_node("MoveManager"), "Move")
	attack = funcref(get_parent().get_node("SkillManager"), "Attack")
	
	# Crear el objeto movePlanner:
	InitAStar()


# Actualiza cuando un totem ha sido destruido:
func notifyTotemDeath(deadTotem):
	match deadTotem:
		skeletonTotem:
			skeletonTotem = null
		robotTotem:
			robotTotem = null
		boneTotem:
			boneTotem = null
		simbadTotem:
			simbadTotem = null

#######################################################################################

# Inicializa el objeto A*:
func InitAStar():
	movePlanner = AStar.new()
	
	# Añadir los nodos:
	for i in range(1, 51):
		movePlanner.add_point(i, get_parent().get_node("Table/n" + str(i)).global_transform.origin)
	
	# Realizar las conexiones por columnas:
	for i in range(10):
		for j in range(1,5):
			movePlanner.connect_points((5*i+j), (5*i+j+1))
	
	# Realizar las conexiones por filas:
	for i in range(1,6):
		for j in range(9):
			movePlanner.connect_points((i+5*j), (i+5*(j+1)))


# Convierte de coordenadas de celda al ID de punto en el algoritmo A*:
func toID(cell):
	return cell[0] * 5 + cell[1] + 1


# Devuelve el nodo mesh asociado a una posición:
func toMesh(cell):
	var aux = toID(cell)
	return get_parent().get_node("Table/n" + str(aux))


# Convierte el número de una casilla a coordenadas de celda:
func toCell(n):
	var local_n = n - 1
	var fil = local_n / 5
	return Vector2(fil, local_n - fil * 5)


# Calcula la distancia Manhattan entre dos celdas:
func dst(a, b):
	return abs(a[0] - b[0]) + abs(a[1] - b[1])


# Devuelve los puntos y el coste a los que se puede mover correctamente,
# acercándose a un objetivo:
func getPosibleMoves(orig, dest, energy):
	var res = Array(movePlanner.get_id_path(toID(orig), toID(dest)))
	# Eliminamos la posición en la que está la propia entidad:
	res.pop_front()
	
	var valid = []
	
	for id in res:
		var distance = dst(orig, toCell(id))
		if not parent.table.values().has(toCell(id)) and distance in energy:
			valid.append([toCell(id), distance])

	return valid


func path(orig, dest, energy):
	# Probamos a buscar un ruta directa hacia el destino:
	var path = getPosibleMoves(orig, dest, energy)
	 # Si no la hay, probamos con las casillas cercanas:
	if path.empty():
		var near = Array(movePlanner.get_point_connections(toID(dest)))
		for id in near:
			path = getPosibleMoves(orig, toCell(id), energy)
			if not path.empty():
				break
	
	return path


#######################################################################################

# Comprueba el estatus del juego, si algún aliado tiene poca vida o algún enemigo:
func CheckGameEstatus():
	skeletonLowHp = false
	robotLowHp = false
	enemyLowHp = false
	
	# Comprobar si algún aliado tiene poca vida:
	if is_instance_valid(robotTotem):
		if robot.currentHp > 0:
			if robot.currentHp < (robot.MAX_HP * 0.5):
				robotLowHp = true
	
	if is_instance_valid(skeletonTotem):
		if skeleton.currentHp > 0:
			if skeleton.currentHp < (skeleton.MAX_HP * 0.5):
				skeletonLowHp = true
	
	# Comprobar si algún enemigo tiene poca vida:
	if is_instance_valid(simbadTotem):
		if simbad.currentHp > 0:
			if simbad.currentHp < (simbad.MAX_HP * 0.5):
				enemyLowHp = true
		if simbadTotem.currentHp < (simbadTotem.MAX_HP * 0.5):
			enemyLowHp = true

	if is_instance_valid(boneTotem):
		if boneGolem.currentHp > 0:
			if boneGolem.currentHp < (boneGolem.MAX_HP * 0.5):
				enemyLowHp = true
		if boneTotem.currentHp < (boneTotem.MAX_HP * 0.5):
			enemyLowHp = true


# Asigna recursos a cada entidad:
func AssignResources():
	robotGems.clear()
	skeletonGems.clear()
	
	var localGems = movementGems.duplicate()
	localGems.sort()
	localGems.invert()
	
	var aliveEntities = []
	
	if is_instance_valid(robotTotem):
		if robot.currentHp > 0:
			aliveEntities.append(robot)

	if is_instance_valid(skeletonTotem):
		if skeleton.currentHp > 0:
			aliveEntities.append(skeleton)
	
	# Si una de las dos entidades está muerta, le asignamos todos
	# los recursos a la otra, si ambas están vivas, los repartimos:
	if len(aliveEntities) == 2:
		for i in range(0, len(localGems), 2):
			robotGems.append(localGems[i])
		
		for i in range(1, len(localGems), 2):
			skeletonGems.append(localGems[i])

		# Si hay alguien con poca vida, le damos más recursos al robot:
		# Si un enemigo tiene poca vida, le damos más recursos al skeleton:
		# En cualquier otro caso la mitad a cada uno:
		if robotLowHp or skeletonLowHp:
			robotSkillPA = ceil(skillPA * 0.8)
		elif enemyLowHp:
			robotSkillPA = floor(skillPA * 0.2)
		else:
			robotSkillPA = round(skillPA * 0.5)
		
		skeletonSkillPA = skillPA - robotSkillPA
	elif len(aliveEntities) == 1:
		if aliveEntities[0] == robot:
			robotSkillPA = skillPA
			robotGems = localGems
		else:
			skeletonSkillPA = skillPA
			skeletonGems = localGems


#######################################################################################

# Método think de la IA global, actualiza toda la información que necesitarán 
# las entidades para llevar a cabo su turno:
func Think():
	turnOrder.clear()
	CheckGameEstatus()
	AssignResources()
	
	# Si el skeleton tiene poca vida va primero el robot (para sanarlo):
	if skeletonLowHp:
		if is_instance_valid(robotTotem):
			if robot.currentHp > 0:
				turnOrder.append(0)
				turnOrder.append(1)

	# En cualquier otro caso el turno es aleatorio:
	if turnOrder.empty():
		if is_instance_valid(robotTotem):
			if robot.currentHp > 0:
				turnOrder.append(0)
		
		if is_instance_valid(skeletonTotem):
			if skeleton.currentHp > 0:
				turnOrder.append(1)
		
		randomize()
		if randf() < 0.5:
			turnOrder.invert()

	# Añadimos la acción de pasar turno:
	turnOrder.append(2)
	
	# Empezar el turno: cada 1 segundo se piensa una acción:
	get_node("Timer").start()


# Calcula el score de ese target para ser elegido:
func targetFit(orig, dest, maxHP, currentHP, isEntity, isEntityDead):
	var HP_WEIGHT = 0.2
	var DST_WEIGHT = 0.8
	var mod
	
	if isEntity:
		mod = 1.5
	else:
		if isEntityDead:
			mod = 2.0
		else:
			mod = 1.0
	
	# El mejor target es el cercano con poca vida:
	return ((1 / (float(currentHP) / float(maxHP))) * HP_WEIGHT + (1 / dst(orig, dest)) * DST_WEIGHT) * mod


# Selecciona el objetivo al que atacar: recibe la entidad que está
# Seleccionando target:
func selectAttackTarget(orig):
	var posibleTargets = []
	
	if is_instance_valid(simbadTotem):
		if simbadTotem.currentHp > 0:
			posibleTargets.append(simbadTotem)
		if simbad.currentHp > 0:
			posibleTargets.append(simbad)
	
	if is_instance_valid(boneTotem):
		if boneTotem.currentHp > 0:
			posibleTargets.append(boneTotem)
		if boneGolem.currentHp > 0:
			posibleTargets.append(boneGolem)
	
	# Calculamos el score de cada uno y nos quedamos con el mayor:
	var bestScore = -1000000.0
	var bestScoreIndex = 0
	var index = 0
	for target in posibleTargets:
		var score
		if target.get_script().get_path().get_file() == "Totem.gd":
			score = targetFit(orig, parent.table[target], target.MAX_HP, target.currentHp, false, target.entityDead)
		else:
			score = targetFit(orig, parent.table[target], target.MAX_HP, target.currentHp, true, false)

		if score > bestScore:
			bestScore = score
			bestScoreIndex = index
		index += 1
	
	return parent.table[posibleTargets[bestScoreIndex]]
	
#######################################################################################

# Metodo think de la entidad robot:
func RobotThink():
	var actionDone = false
	
	# Si ambas entidades están a poca vida lanzo la definitiva:
	if skeletonLowHp and robotLowHp:
		if robotSkillPA >= robot.costs[2]:
			attack.call_func(robot, toMesh(get_parent().table[robot]), robot.costs[2], 3)
			actionDone = true
			robotSkillPA -= robot.costs[2]
	
	# Si tengo poca vida, lanzo definitiva y me curo:
	if not actionDone:
		if robotLowHp:
			if robotSkillPA >= robot.costs[2]:
				attack.call_func(robot, toMesh(get_parent().table[robot]), robot.costs[2], 3)
				actionDone = true
				robotSkillPA -= robot.costs[2]

	# Si mi aliado tiene poca vida lo curo:
	if not actionDone:
		if skeletonLowHp:
			# Miro si está en rango:
			if dst(parent.table[robot], parent.table[skeleton]) <= robot.ranges[1]:
				if robotSkillPA >= robot.costs[1]:
					attack.call_func(robot, toMesh(parent.table[skeleton]), robot.costs[1], 2)
					actionDone = true
					robotSkillPA -= robot.costs[1]
			else:
				# Si no está en rago, me acerco:
				var path = path(parent.table[robot], parent.table[skeleton], robotGems)
				if not path.empty():
					move.call_func(robot, toMesh(path.back()[0]), path.back()[1], false)
					robotGems.erase(int(path.back()[1]))
					get_parent().get_node("Sound/Move").play()
					actionDone = true
	
	# Si todos estamos bien de vida le pego a alguien:
	if not actionDone and not (robotLowHp or skeletonLowHp):
		var objetive = selectAttackTarget(parent.table[robot])
		# Si está cerca le pego:
		if dst(parent.table[robot], objetive) <= robot.ranges[0]:
			if robotSkillPA >= robot.costs[0]:
				attack.call_func(robot, toMesh(objetive), robot.costs[0], 1)
				robotSkillPA -= robot.costs[0]
				actionDone = true
		else:
			var path = path(parent.table[robot], objetive, robotGems)
			if not path.empty():
				move.call_func(robot, toMesh(path.back()[0]), path.back()[1], false)
				robotGems.erase(int(path.back()[1]))
				get_parent().get_node("Sound/Move").play()
				actionDone = true

	if get_parent().get_node("TurnManager").turn == 0:
		return false
	else:
		return actionDone


#######################################################################################

# Método Think de la entidad Skeleton:
func SkeletonThink():
	var actionDone = false
	
	randomize()
	
	var objetive = selectAttackTarget(parent.table[skeleton])
	# Si está cerca le pego: (2 es el rango general del esqueleto):
	if dst(parent.table[skeleton], objetive) <= 2:
		if skeletonSkillPA >= skeleton.costs[2]:
			attack.call_func(skeleton, toMesh(objetive), skeleton.costs[2], 3)
			skeletonSkillPA -= skeleton.costs[2]
			actionDone = true
		if skeletonSkillPA >= skeleton.costs[1] and randf() < 0.1:
			attack.call_func(skeleton, toMesh(parent.table[skeleton]), skeleton.costs[1], 2)
			skeletonSkillPA -= skeleton.costs[1]
			actionDone = true
		elif skeletonSkillPA >= skeleton.costs[0]:
			attack.call_func(skeleton, toMesh(objetive), skeleton.costs[0], 1)
			skeletonSkillPA -= skeleton.costs[0]
			actionDone = true
	else:
		var path = path(parent.table[skeleton], objetive, skeletonGems)
		if not path.empty():
			move.call_func(skeleton, toMesh(path.back()[0]), path.back()[1], false)
			skeletonGems.erase(int(path.back()[1]))
			get_parent().get_node("Sound/Move").play()
			actionDone = true

	if get_parent().get_node("TurnManager").turn == 0:
		return false
	else:
		return actionDone

#######################################################################################

func _on_Timer_timeout():
	var somethingDone
	
	match(turnOrder.front()):
		0:
			somethingDone = RobotThink()
			if not somethingDone:
				turnOrder.pop_front()
			get_node("Timer").start()
		1:
			somethingDone = SkeletonThink()
			if not somethingDone:
				turnOrder.pop_front()
			get_node("Timer").start()
		2:
			# Pasar turno:
			skillPA = robotSkillPA + skeletonSkillPA
			movementGems = robotGems + skeletonGems
			get_parent().get_node("HUD").SkipTurn()