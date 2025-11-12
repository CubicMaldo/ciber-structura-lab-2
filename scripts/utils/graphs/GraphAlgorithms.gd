class_name GraphAlgorithms
const INF := 1.0e18

## Devuelve el peso promedio de todas las aristas del grafo.
static func average_weight(graph: Graph) -> float:
	if graph == null:
		return 0.0
	var total_weight: float = 0.0
	var edge_count: int = 0
	for edge_info in graph.get_edges():
		total_weight += float(edge_info.get("weight", 0.0))
		edge_count += 1
	if edge_count == 0:
		return 0.0
	return total_weight / float(edge_count)


static func shortest_path(graph: Graph, source, target) -> Dictionary:
	var result := {
		"reachable": false,
		"distance": 0.0,
		"path": []
	}
	if graph == null or source == null or target == null:
		return result
	if source == target:
		if graph.has_vertex(source):
			result["reachable"] = true
			result["path"] = [source]
			result["distance"] = 0.0
		return result
	if not graph.has_vertex(source) or not graph.has_vertex(target):
		return result
	var dist: Dictionary = {}
	var previous: Dictionary = {}
	var pending: Array = [source]
	dist[source] = 0.0
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current = _pop_lowest(pending, dist)
		if visited.has(current):
			continue
		visited[current] = true
		if current == target:
			break
		var neighbor_weights: Dictionary = graph.get_neighbor_weights(current)
		for neighbor in neighbor_weights.keys():
			if visited.has(neighbor):
				continue
			var weight: float = float(neighbor_weights[neighbor])
			if weight < 0.0:
				continue
			var current_dist: float = float(dist.get(current, INF))
			var candidate: float = current_dist + weight
			var existing: float = float(dist.get(neighbor, INF))
			if candidate < existing:
				dist[neighbor] = candidate
				previous[neighbor] = current
				if not pending.has(neighbor):
					pending.append(neighbor)
	if not dist.has(target):
		return result
	var path: Array = []
	var cursor = target
	while true:
		path.insert(0, cursor)
		if cursor == source:
			break
		cursor = previous.get(cursor, null)
		if cursor == null:
			path.clear()
			return result
	result["reachable"] = true
	result["distance"] = float(dist.get(target, 0.0))
	result["path"] = path
	return result


static func mutual_metrics(graph: Graph, a, b, min_weight: float = 0.0) -> Dictionary:
	var result := {
		"count": 0,
		"entries": [],
		"average_weight": 0.0,
		"jaccard_index": 0.0
	}
	if graph == null or a == null or b == null:
		return result
	var weights_a: Dictionary = graph.get_neighbor_weights(a)
	var weights_b: Dictionary = graph.get_neighbor_weights(b)
	var entries: Array = []
	var total_avg: float = 0.0
	for neighbor in weights_a.keys():
		if neighbor == a or neighbor == b:
			continue
		if not weights_b.has(neighbor):
			continue
		var weight_a: float = float(weights_a[neighbor])
		var weight_b: float = float(weights_b[neighbor])
		if weight_a < min_weight or weight_b < min_weight:
			continue
		var avg_weight: float = (weight_a + weight_b) * 0.5
		total_avg += avg_weight
		entries.append({
			"neighbor": neighbor,
			"weight_a": weight_a,
			"weight_b": weight_b,
			"average_weight": avg_weight
		})
	var count := entries.size()
	result["entries"] = entries
	result["count"] = count
	result["average_weight"] = total_avg / float(count) if count > 0 else 0.0
	result["jaccard_index"] = _jaccard_index(weights_a.keys(), weights_b.keys())
	return result


## Realiza un recorrido BFS (Breadth-First Search) desde un nodo inicial.
## Retorna un diccionario con información del recorrido:
## - visited: Array de claves visitadas en orden BFS
## - levels: Dictionary { clave: nivel } indicando la distancia desde el origen
## - parent: Dictionary { clave: padre } para reconstruir caminos
static func bfs(graph: Graph, start_key) -> Dictionary:
	var result := {
		"visited": [],
		"levels": {},
		"parent": {}
	}
	
	if graph == null or start_key == null or not graph.has_vertex(start_key):
		return result
	
	var queue: Array = [start_key]
	var visited: Dictionary = {}
	var levels: Dictionary = {}
	var parent: Dictionary = {}
	
	visited[start_key] = true
	levels[start_key] = 0
	
	while not queue.is_empty():
		var current = queue.pop_front()
		result["visited"].append(current)
		
		var current_level: int = int(levels.get(current, 0))
		var neighbor_weights: Dictionary = graph.get_neighbor_weights(current)
		
		for neighbor in neighbor_weights.keys():
			if visited.has(neighbor):
				continue
			
			visited[neighbor] = true
			levels[neighbor] = current_level + 1
			parent[neighbor] = current
			queue.append(neighbor)
	
	result["levels"] = levels
	result["parent"] = parent
	return result


## Realiza un recorrido DFS (Depth-First Search) iterativo desde un nodo inicial.
## Retorna un diccionario con información del recorrido similar a BFS:
## - visited: Array con el orden de visitas (preorder)
## - levels: Dictionary { clave: nivel }
## - parent: Dictionary { clave: padre }
static func dfs(graph: Graph, start_key) -> Dictionary:
	var result := {
		"visited": [],
		"levels": {},
		"parent": {}
	}

	if graph == null or start_key == null or not graph.has_vertex(start_key):
		return result

	var stack: Array = [start_key]
	var visited: Dictionary = {}
	var levels: Dictionary = {}
	var parent: Dictionary = {}

	levels[start_key] = 0

	while not stack.is_empty():
		var current = stack.pop_back()
		if visited.has(current):
			continue
		visited[current] = true
		result["visited"].append(current)
		var current_level: int = int(levels.get(current, 0))
		# Obtener vecinos y empujar en orden invertido para simular DFS recursivo
		var neighbor_weights: Dictionary = graph.get_neighbor_weights(current)
		var neighbors: Array = []
		for n in neighbor_weights.keys():
			neighbors.append(n)
		# push neighbors in reverse order so the first neighbor is processed first
		for i in range(neighbors.size() - 1, -1, -1):
			var neighbor = neighbors[i]
			if visited.has(neighbor):
				continue
			parent[neighbor] = current
			levels[neighbor] = current_level + 1
			stack.append(neighbor)

	result["levels"] = levels
	result["parent"] = parent
	return result


static func _pop_lowest(queue: Array, distances: Dictionary):
	var best_index := 0
	var best_key = queue[0]
	var best_distance: float = float(distances.get(best_key, INF))
	for i in range(1, queue.size()):
		var candidate = queue[i]
		var candidate_distance: float = float(distances.get(candidate, INF))
		if candidate_distance < best_distance:
			best_distance = candidate_distance
			best_key = candidate
			best_index = i
	queue.remove_at(best_index)
	return best_key


static func _jaccard_index(keys_a: Array, keys_b: Array) -> float:
	if keys_a.is_empty() and keys_b.is_empty():
		return 0.0
	var set_a: Dictionary = {}
	for key in keys_a:
		set_a[key] = true
	var union_map: Dictionary = set_a.duplicate(true)
	var intersection := 0
	for key in keys_b:
		if set_a.has(key):
			intersection += 1
		union_map[key] = true
	var union_size := float(union_map.size())
	if union_size <= 0.0:
		return 0.0
	return float(intersection) / union_size


# ============================================================================
# ALGORITMOS DE FLUJO MÁXIMO (MAXIMUM FLOW)
# ============================================================================

## Calcula el flujo máximo entre dos nodos usando el algoritmo de Edmonds-Karp (BFS).
## Este algoritmo modifica el grafo, estableciendo el flujo en cada arista.
##
## Retorna un diccionario con:
## - max_flow: int - El flujo máximo alcanzado
## - flow_paths: Array - Caminos aumentantes encontrados
## - saturated_edges: Array - Aristas saturadas (flux == capacity)
##
## Argumentos:
## - graph: El grafo (se modificarán los valores de flux en las aristas)
## - source: Nodo fuente
## - sink: Nodo sumidero
## - reset_flux: Si true, resetea todos los flujos antes de calcular (por defecto true)
static func max_flow_edmonds_karp(graph: Graph, source, sink, reset_flux: bool = true) -> Dictionary:
	var result := {
		"max_flow": 0,
		"flow_paths": [],
		"saturated_edges": []
	}
	
	if graph == null or source == null or sink == null:
		return result
	
	if not graph.has_vertex(source) or not graph.has_vertex(sink):
		return result
	
	if source == sink:
		return result
	
	# Resetear flujos si se solicita
	if reset_flux:
		graph.reset_all_flux()
	
	var max_flow := 0
	
	# Mientras exista un camino aumentante
	while true:
		var path_info = _find_augmenting_path_bfs(graph, source, sink)
		if not path_info.has("path") or path_info["path"].is_empty():
			break
		
		var path: Array = path_info["path"]
		var bottleneck: int = path_info["bottleneck"]
		
		# Aumentar flujo en el camino
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]
			graph.add_edge_flux(u, v, bottleneck)
		
		max_flow += bottleneck
		result["flow_paths"].append({
			"path": path,
			"flow": bottleneck
		})
	
	result["max_flow"] = max_flow
	
	# Recopilar aristas saturadas
	var flow_edges = graph.get_flow_edges()
	for edge_info in flow_edges:
		if edge_info["residual"] <= 0.0:
			result["saturated_edges"].append({
				"source": edge_info["source"],
				"target": edge_info["target"],
				"capacity": edge_info["capacity"]
			})
	
	return result


## Encuentra un camino aumentante usando BFS (para Edmonds-Karp).
## Retorna un diccionario con el camino y el cuello de botella.
static func _find_augmenting_path_bfs(graph: Graph, source, sink) -> Dictionary:
	var result := {
		"path": [],
		"bottleneck": 0
	}
	
	var queue: Array = [source]
	var visited: Dictionary = {source: true}
	var parent: Dictionary = {}
	var found := false
	
	# BFS para encontrar camino con capacidad residual
	while not queue.is_empty() and not found:
		var current = queue.pop_front()
		
		if current == sink:
			found = true
			break
		
		var neighbor_weights = graph.get_neighbor_weights(current)
		for neighbor in neighbor_weights.keys():
			if visited.has(neighbor):
				continue
			
			# Verificar si hay capacidad residual
			var residual = graph.get_edge_residual_capacity(current, neighbor)
			if residual > 0.0:
				visited[neighbor] = true
				parent[neighbor] = current
				queue.append(neighbor)
	
	if not found:
		return result
	
	# Reconstruir camino
	var path: Array = []
	var cursor = sink
	while cursor != source:
		path.insert(0, cursor)
		cursor = parent.get(cursor, null)
		if cursor == null:
			return result
	path.insert(0, source)
	
	# Calcular cuello de botella (mínima capacidad residual)
	var bottleneck := INF
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i + 1]
		var residual = graph.get_edge_residual_capacity(u, v)
		bottleneck = min(bottleneck, residual)
	
	result["path"] = path
	result["bottleneck"] = int(bottleneck)
	return result


## Calcula el corte mínimo después de ejecutar un algoritmo de flujo máximo.
## Devuelve los conjuntos de nodos alcanzables desde la fuente (S) y el resto (T).
##
## IMPORTANTE: Ejecuta max_flow_edmonds_karp antes de llamar a esta función.
##
## Retorna:
## - reachable_from_source: Array - Nodos alcanzables desde source usando aristas no saturadas
## - cut_edges: Array - Aristas del corte mínimo
## - cut_capacity: float - Suma de capacidades de las aristas del corte
static func min_cut(graph: Graph, source) -> Dictionary:
	var result := {
		"reachable_from_source": [],
		"cut_edges": [],
		"cut_capacity": 0.0
	}
	
	if graph == null or source == null or not graph.has_vertex(source):
		return result
	
	# BFS usando solo aristas con capacidad residual > 0
	var queue: Array = [source]
	var reachable: Dictionary = {source: true}
	
	while not queue.is_empty():
		var current = queue.pop_front()
		result["reachable_from_source"].append(current)
		
		var neighbor_weights = graph.get_neighbor_weights(current)
		for neighbor in neighbor_weights.keys():
			if reachable.has(neighbor):
				continue
			
			var residual = graph.get_edge_residual_capacity(current, neighbor)
			if residual > 0.0:
				reachable[neighbor] = true
				queue.append(neighbor)
	
	# Encontrar aristas del corte (de S a T)
	var cut_capacity := 0.0
	for node in result["reachable_from_source"]:
		var neighbor_weights = graph.get_neighbor_weights(node)
		for neighbor in neighbor_weights.keys():
			if not reachable.has(neighbor):
				var edge = graph.get_edge_resource(node, neighbor)
				if edge:
					result["cut_edges"].append({
						"source": node,
						"target": neighbor,
						"capacity": edge.weight,
						"flux": edge.flux
					})
					cut_capacity += edge.weight
	
	result["cut_capacity"] = cut_capacity
	return result
