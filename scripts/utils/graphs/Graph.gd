## Clase que representa un grafo no dirigido y ponderado. 
## Permite agregar, eliminar y consultar nodos y aristas, con soporte para metadata.
class_name Graph

# ============================================================================
# SEÑALES
# ============================================================================

## Emitida cuando se agrega un nuevo nodo.
signal node_added(key)
## Emitida cuando se elimina un nodo existente.
signal node_removed(key)
## Emitida cuando se agrega una arista entre dos nodos.
signal edge_added(a, b)
## Emitida cuando se elimina una arista entre dos nodos.
signal edge_removed(a, b)

# ============================================================================
# ATRIBUTOS
# ============================================================================

## Diccionario de vértices en el grafo: `{key: Vertex}`.
var vertices: Dictionary[Variant, Vertex] = {}

# ============================================================================
# GESTIÓN DE NODOS
# ============================================================================

## Añade un nodo al grafo o actualiza su metadata.
## [br]
## Argumentos:
## - `key`: Clave del nodo (no puede ser `null`).
## - `meta`: Resource opcional con metadata (ej: VertexMeta, NPCVertexMeta, o cualquier Resource personalizado).
func add_node(key, meta: Resource = null) -> Vertex:
	if key == null:
		push_error("Graph.add_node: key cannot be null")
		return null

	var vertex = vertices.get(key)
	if vertex:
		if meta:
			vertex.meta = meta
		return vertex
	
	vertex = Vertex.new(key, _id_as_int(key), meta)
	vertices[key] = vertex
	emit_signal("node_added", key)
	return vertex


## Garantiza que un nodo exista, creando o actualizando su metadata.
## [br]
## Argumentos:
## - `key`: Identificador del nodo.
## - `meta`: Resource opcional con metadata (ej: VertexMeta, NPCVertexMeta, o cualquier Resource personalizado).
func ensure_node(key, meta: Resource = null) -> Vertex:
	if not vertices.has(key):
		return add_node(key, meta)
	elif meta:
		var v = vertices[key]
		v.meta = meta
		return v
	return vertices.get(key)


## Elimina un nodo y todas sus conexiones.
## [br]
## Argumentos:
## - `key`: Identificador del nodo a eliminar.
func remove_node(key) -> void:
	var v = vertices.get(key)
	if v == null:
		return
	v.dispose()
	vertices.erase(key)
	emit_signal("node_removed", key)


## Cambia la clave utilizada para un vértice existente.
## Devuelve `true` si la operación tuvo éxito.
func rekey_vertex(old_key, new_key) -> bool:
	if old_key == new_key:
		return true
	if new_key == null:
		push_error("Graph.rekey_vertex: new_key cannot be null")
		return false
	var vertex: Vertex = vertices.get(old_key)
	if vertex == null:
		push_warning("Graph.rekey_vertex: old_key %s not found" % [str(old_key)])
		return false
	if vertices.has(new_key):
		push_warning("Graph.rekey_vertex: new_key %s already exists" % [str(new_key)])
		return false
	vertices.erase(old_key)
	vertices[new_key] = vertex
	vertex.key = new_key
	for neighbor_key in vertex.edges.keys():
		var neighbor_vertex: Vertex = vertices.get(neighbor_key)
		if neighbor_vertex and neighbor_vertex.edges.has(old_key):
			var edge: Edge = neighbor_vertex.edges[old_key]
			neighbor_vertex.edges.erase(old_key)
			neighbor_vertex.edges[new_key] = edge
	return true


## Devuelve `true` si el nodo existe en el grafo.
func has_vertex(key) -> bool:
	return vertices.has(key)


## Obtiene el vértice asociado a una clave.
## [br]
## Argumentos:
## - `key`: Clave del vértice.
func get_vertex(key):
	return vertices.get(key)


## Retorna un diccionario con los nodos y su metadata.
## [br]
## Formato:
## ```
## { key: metadata }
## ```
func get_nodes() -> Dictionary:
	var out := {}
	for k in vertices:
		var v = vertices[k]
		out[k] = v.meta.duplicate(true) if v.meta else {}
	return out


## Devuelve el número total de nodos en el grafo.
func get_node_count() -> int:
	return vertices.size()

# ============================================================================
# GESTIÓN DE ARISTAS
# ============================================================================

## Crea o actualiza una conexión bidireccional entre dos nodos.
## [br]
## Argumentos:
## - `a`: Nodo origen.
## - `b`: Nodo destino.
## - `weight`: Peso de la conexión / capacidad (debe ser positivo).
## - `edge_metadata`: Resource opcional con metadata de la arista.
## - `initial_flux`: Flujo inicial de la arista (por defecto 0).
func add_connection(a, b, weight: float, edge_metadata: Resource = null, initial_flux: int = 0) -> void:
	if a == b:
		push_error("Graph.add_connection: cannot connect node to itself")
		return
	
	if weight < 0.0:
		push_warning("Graph.add_connection: negative weight %f for %s-%s, removing connection" % [weight, a, b])
		remove_connection(a, b)
		return
	
	ensure_node(a)
	ensure_node(b)
	
	var va: Vertex = vertices[a]
	var vb: Vertex = vertices[b]
	var edge: Edge = va.edges.get(b)
	if edge == null:
		edge = Edge.new(va, vb, weight, initial_flux, edge_metadata)
		va.edges[b] = edge
		vb.edges[a] = edge
		emit_signal("edge_added", a, b)
	else:
		edge.weight = weight
		edge.flux = initial_flux
		if edge_metadata != null:
			edge.metadata = edge_metadata


## Conecta dos nodos, creando ambos si no existen.
## [br]
## Argumentos:
## - `a`: Nodo origen.
## - `b`: Nodo destino.
## - `weight`: Peso de la conexión / capacidad (por defecto 1.0).
## - `meta_a`: Resource opcional para metadata del nodo A.
## - `meta_b`: Resource opcional para metadata del nodo B.
## - `edge_metadata`: Resource opcional con metadata de la arista.
## - `initial_flux`: Flujo inicial (por defecto 0).
func connect_vertices(a, b, weight := 1.0, meta_a: Resource = null, meta_b: Resource = null, edge_metadata: Resource = null, initial_flux: int = 0) -> void:
	ensure_node(a, meta_a)
	ensure_node(b, meta_b)
	add_connection(a, b, weight, edge_metadata, initial_flux)


## Elimina la arista entre dos nodos si existe.
## [br]
## Argumentos:
## - `a`: Nodo origen.
## - `b`: Nodo destino.
func remove_connection(a, b) -> void:
	var va: Vertex = vertices.get(a)
	if va == null:
		return
	var edge: Edge = va.edges.get(b)
	if edge == null:
		return

	var src := edge.endpoint_a
	var dst := edge.endpoint_b
	if src:
		src.edges.erase(b)
	if dst:
		dst.edges.erase(a)

	emit_signal("edge_removed", a, b)


## Elimina todos los nodos y aristas del grafo.
## [br]
## Llama internamente a `dispose()` en cada vértice.
func clear() -> void:
	for k in vertices:
		var v: Vertex = vertices[k]
		if v and typeof(v) == TYPE_OBJECT and v.has_method("dispose"):
			v.dispose()
	vertices.clear()

# ============================================================================
# CONSULTAS DE ARISTAS
# ============================================================================

## Devuelve el peso de la arista entre `a` y `b`, o `null` si no existe.
func get_edge_weight(a, b):
	var e = get_edge_resource(a, b)
	return e.weight if e else null


## Obtiene el objeto `Edge` entre dos nodos, si existe.
func get_edge_resource(a, b):
	var va: Vertex = vertices.get(a)
	return va.get_edge_to(b) if va else null


## Devuelve `true` si existe una arista entre `a` y `b`.
func has_edge(a, b) -> bool:
	return get_edge_resource(a, b) != null


## Retorna una lista de aristas sin duplicados.
## [br]
## Cada entrada tiene el formato:
## ```
## { "source": a, "target": b, "weight": w, "flux": f }
## ```
func get_edges() -> Array:
	var out: Array = []
	for a_key in vertices:
		var va: Vertex = vertices[a_key]
		for b_key in va.edges:
			if _is_primary_endpoint(a_key, b_key):
				var e: Edge = va.edges[b_key]
				out.append({
					"source": e.endpoint_a.key,
					"target": e.endpoint_b.key,
					"weight": e.weight,
					"flux": e.flux
				})
	return out


## Devuelve el número total de aristas en el grafo.
func get_edge_count() -> int:
	var deg_sum := 0
	for k in vertices:
		deg_sum += (vertices[k] as Vertex).edges.size()
	return deg_sum >> 1

# ============================================================================
# CONSULTAS DE VECINDAD
# ============================================================================

## Devuelve los pesos de las conexiones del nodo especificado.
func get_neighbor_weights(key) -> Dictionary:
	var v: Vertex = vertices.get(key)
	return v.get_neighbor_weights() if v else {}


## Devuelve una lista de nodos vecinos conectados al nodo dado.
func get_neighbors(key) -> Array:
	var v: Vertex = vertices.get(key)
	return v.get_neighbor_keys() if v else []


## Devuelve el número de conexiones (grado) del nodo dado.
func get_degree(key) -> int:
	var v: Vertex = vertices.get(key)
	return v.degree() if v else 0

# ============================================================================
# METADATA DIRECTA
# ============================================================================

## Asigna un valor a un campo de metadata de un nodo.
func set_vertex_meta(key, field, value):
	var v = vertices.get(key)
	if v:
		v.meta[field] = value


## Obtiene un campo de metadata de un nodo.
## [br]
## Si el nodo o el campo no existen, devuelve `default`.
func get_vertex_meta(key, field, default = null):
	var v = vertices.get(key)
	return v.meta.get(field, default) if v else default

# ============================================================================
# OPERACIONES DE FLUJO (NETWORK FLOW)
# ============================================================================

## Establece el flujo de una arista entre dos nodos.
## Devuelve `true` si el flujo es válido y se estableció correctamente.
##
## Argumentos:
## - `a`: Nodo origen.
## - `b`: Nodo destino.
## - `flux_value`: Valor de flujo a establecer.
func set_edge_flux(a, b, flux_value: int) -> bool:
	var edge = get_edge_resource(a, b)
	if edge:
		return edge.set_flux(flux_value)
	return false


## Agrega flujo a una arista existente.
## Devuelve `true` si se pudo agregar sin exceder la capacidad.
##
## Argumentos:
## - `a`: Nodo origen.
## - `b`: Nodo destino.
## - `amount`: Cantidad de flujo a agregar (puede ser negativo).
func add_edge_flux(a, b, amount: int) -> bool:
	var edge = get_edge_resource(a, b)
	if edge:
		return edge.add_flux(amount)
	return false


## Obtiene el flujo actual de una arista.
## Devuelve el flujo o 0 si la arista no existe.
func get_edge_flux(a, b) -> int:
	var edge = get_edge_resource(a, b)
	return edge.flux if edge else 0


## Obtiene la capacidad residual de una arista (capacity - flux).
## Devuelve la capacidad residual o 0.0 si la arista no existe.
func get_edge_residual_capacity(a, b) -> float:
	var edge = get_edge_resource(a, b)
	return edge.residual_capacity() if edge else 0.0


## Resetea el flujo de todas las aristas a 0.
func reset_all_flux() -> void:
	for vertex in vertices.values():
		for edge in vertex.edges.values():
			edge.flux = 0


## Devuelve el flujo total que sale de un nodo (suma de flujos salientes).
## Nota: En grafos no dirigidos, esto suma el flujo de todas las aristas conectadas.
func get_outgoing_flux(node_key) -> int:
	var vertex: Vertex = vertices.get(node_key)
	if not vertex:
		return 0
	
	var total_flux := 0
	for edge: Edge in vertex.edges.values():
		total_flux += edge.flux
	return total_flux


## Devuelve información de todas las aristas con flujo.
## Formato: Array de { "source": a, "target": b, "capacity": w, "flux": f, "residual": r }
func get_flow_edges() -> Array:
	var out: Array = []
	for a_key in vertices:
		var va: Vertex = vertices[a_key]
		for b_key in va.edges:
			if _is_primary_endpoint(a_key, b_key):
				var e: Edge = va.edges[b_key]
				out.append({
					"source": e.endpoint_a.key,
					"target": e.endpoint_b.key,
					"capacity": e.weight,
					"flux": e.flux,
					"residual": e.residual_capacity()
				})
	return out

# ============================================================================
# DEPURACIÓN
# ============================================================================

## Imprime en consola todos los nodos y sus conexiones.
## Si `show_flux` es true, muestra información de flujo (flux/capacity).
func debug_print(show_flux: bool = false):
	for k in vertices:
		var v: Vertex = vertices[k]
		if show_flux:
			var connections: Array = []
			for neighbor_key in v.edges:
				var edge: Edge = v.edges[neighbor_key]
				connections.append("%s (flux: %d/%0.1f)" % [str(neighbor_key), edge.flux, edge.weight])
			print("%s -> [%s]" % [str(k), ", ".join(connections)])
		else:
			print("%s -> %s" % [str(k), str(v.get_neighbor_weights())])

# ============================================================================
# INTERNOS
# ============================================================================

## Convierte la clave a entero si aplica, o devuelve -1.
func _id_as_int(k) -> int:
	return int(k) if typeof(k) == TYPE_INT else -1


## Determina un orden estable entre dos claves de nodo.
## [br]
## Esto evita duplicados al iterar sobre aristas.
func _is_primary_endpoint(a, b) -> bool:
	if a == b:
		return false
	var ta := typeof(a)
	var tb := typeof(b)
	if ta != tb:
		return ta < tb
	match ta:
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return a < b
		TYPE_STRING:
			return String(a) < String(b)
		TYPE_OBJECT:
			return (a as Object).get_instance_id() < (b as Object).get_instance_id()
		_:
			return hash(a) < hash(b)
