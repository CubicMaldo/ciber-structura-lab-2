## GraphLayout: algoritmos de posicionamiento para nodos del grafo
## Proporciona layouts circular, grid, y force-directed
class_name GraphLayout

## Posiciona nodos en un círculo
static func circular_layout(node_count: int, radius: float = 200.0, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if node_count == 0:
		return positions
	
	var angle_step := TAU / float(node_count)
	for i in range(node_count):
		var angle := angle_step * i
		var pos := center + Vector2(cos(angle), sin(angle)) * radius
		positions.append(pos)
	
	return positions


## Posiciona nodos en una cuadrícula
static func grid_layout(node_count: int, cols: int = 4, spacing: float = 150.0, center: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if node_count == 0:
		return positions
	
	var rows := ceili(float(node_count) / float(cols))
	var start_x := center.x - (cols - 1) * spacing * 0.5
	var start_y := center.y - (rows - 1) * spacing * 0.5
	
	for i in range(node_count):
		var row : int = int(i / float(cols))
		var col : int = int(i % cols)
		var pos := Vector2(start_x + col * spacing, start_y + row * spacing)
		positions.append(pos)
	
	return positions


## Layout forzado simple (force-directed) - iterativo
## Retorna posiciones después de N iteraciones
static func force_directed_layout(
	node_keys: Array,
	edges: Array,
	iterations: int = 50,
	repulsion: float = 5000.0,
	attraction: float = 0.1,
	damping: float = 0.9,
	center: Vector2 = Vector2.ZERO,
	bounds: Rect2 = Rect2(-400, -300, 800, 600)
) -> Dictionary:
	# Inicializar posiciones aleatorias
	var positions := {}
	var velocities := {}
	
	for key in node_keys:
		positions[key] = center + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		velocities[key] = Vector2.ZERO
	
	# Iterar simulación física
	for _iter in range(iterations):
		var forces := {}
		for key in node_keys:
			forces[key] = Vector2.ZERO
		
		# Fuerza de repulsión entre todos los nodos
		for i in range(node_keys.size()):
			var key_a = node_keys[i]
			for j in range(i + 1, node_keys.size()):
				var key_b = node_keys[j]
				var delta: Vector2 = positions[key_b] - positions[key_a]
				var dist := delta.length()
				if dist < 1.0:
					dist = 1.0
				var force_mag := repulsion / (dist * dist)
				var force_dir := delta.normalized()
				forces[key_a] -= force_dir * force_mag
				forces[key_b] += force_dir * force_mag
		
		# Fuerza de atracción en las aristas
		for edge in edges:
			var key_a = edge.get("source", edge.get("from"))
			var key_b = edge.get("target", edge.get("to"))
			if not positions.has(key_a) or not positions.has(key_b):
				continue
			var delta: Vector2 = positions[key_b] - positions[key_a]
			var dist := delta.length()
			var force_mag := attraction * dist
			var force_dir := delta.normalized()
			forces[key_a] += force_dir * force_mag
			forces[key_b] -= force_dir * force_mag
		
		# Actualizar velocidades y posiciones
		for key in node_keys:
			velocities[key] = (velocities[key] + forces[key]) * damping
			positions[key] += velocities[key]
			# Mantener dentro de límites
			positions[key].x = clampf(positions[key].x, bounds.position.x, bounds.position.x + bounds.size.x)
			positions[key].y = clampf(positions[key].y, bounds.position.y, bounds.position.y + bounds.size.y)
	
	return positions


## Layout jerárquico (árbol) - BFS desde un nodo raíz
static func hierarchical_layout(
	node_keys: Array,
	edges: Array,
	root_key,
	level_spacing: float = 120.0,
	node_spacing: float = 100.0,
	center: Vector2 = Vector2.ZERO
) -> Dictionary:
	var positions := {}
	var adjacency := {}
	
	# Construir lista de adyacencia
	for key in node_keys:
		adjacency[key] = []
	
	for edge in edges:
		var a = edge.get("source", edge.get("from"))
		var b = edge.get("target", edge.get("to"))
		if adjacency.has(a):
			adjacency[a].append(b)
		if adjacency.has(b):
			adjacency[b].append(a)
	
	# BFS para asignar niveles
	var visited := {}
	var levels := {}
	var queue := [root_key]
	visited[root_key] = true
	levels[root_key] = 0
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var current_level = levels[current]
		
		for neighbor in adjacency.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = true
				levels[neighbor] = current_level + 1
				queue.append(neighbor)
	
	# Agrupar por nivel
	var nodes_by_level := {}
	for key in node_keys:
		var level = levels.get(key, 0)
		if not nodes_by_level.has(level):
			nodes_by_level[level] = []
		nodes_by_level[level].append(key)
	
	# Posicionar nodos por nivel
	for level in nodes_by_level.keys():
		var nodes_in_level = nodes_by_level[level]
		var count = nodes_in_level.size()
		var start_x = center.x - (count - 1) * node_spacing * 0.5
		var y = center.y + level * level_spacing
		
		for i in range(count):
			var key = nodes_in_level[i]
			positions[key] = Vector2(start_x + i * node_spacing, y)
	
	return positions
