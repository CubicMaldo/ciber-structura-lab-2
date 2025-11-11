## GraphBuilder: Nodo para construir grafos desde el Inspector de Godot
## Permite al diseñador crear la estructura del grafo visualmente sin código
@tool
class_name GraphBuilder
extends Node

## Lista de nodos del grafo (se puede editar en el Inspector)
@export var nodes: Array[GraphNodeData] = []

## Lista de conexiones entre nodos
@export var connections: Array[GraphConnectionData] = []

## Grafo construido (solo lectura, generado automáticamente)
var graph: Graph = null

## Señal emitida cuando el grafo es reconstruido
signal graph_built(graph: Graph)


func _ready() -> void:
	if not Engine.is_editor_hint():
		# En runtime, construir el grafo automáticamente
		build_graph()


## Construye el grafo a partir de los datos configurados en el Inspector
func build_graph() -> Graph:
	graph = Graph.new()
	
	# Agregar todos los nodos con su metadata
	for node_data in nodes:
		if node_data and node_data.node_key != "":
			var meta = node_data.get_metadata()
			graph.add_node(node_data.node_key, meta)
	
	# Agregar todas las conexiones con su metadata
	for conn in connections:
		if conn and conn.from_node != "" and conn.to_node != "":
			var edge_meta = conn.get_edge_metadata()
			# Graph.connect_vertices acepta edge_metadata como parámetro
			graph.connect_vertices(conn.from_node, conn.to_node, conn.weight, null, null, edge_meta)
	
	graph_built.emit(graph)
	return graph


## Obtiene el grafo construido (construye si es necesario)
func get_graph() -> Graph:
	if graph == null:
		build_graph()
	return graph


## Reconstruye el grafo (útil para hot-reload en el editor)
func rebuild() -> void:
	build_graph()


## Valida que el grafo esté correctamente configurado
func validate() -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": []
	}
	
	# Verificar nodos duplicados
	var seen_keys = {}
	for node_data in nodes:
		if node_data and node_data.node_key != "":
			if seen_keys.has(node_data.node_key):
				result.valid = false
				result.errors.append("Nodo duplicado: '%s'" % node_data.node_key)
			else:
				seen_keys[node_data.node_key] = true
	
	# Verificar conexiones válidas
	for conn in connections:
		if conn:
			if conn.from_node == "":
				result.errors.append("Conexión con from_node vacío")
				result.valid = false
			elif not seen_keys.has(conn.from_node):
				result.warnings.append("Conexión desde nodo inexistente: '%s'" % conn.from_node)
			
			if conn.to_node == "":
				result.errors.append("Conexión con to_node vacío")
				result.valid = false
			elif not seen_keys.has(conn.to_node):
				result.warnings.append("Conexión hacia nodo inexistente: '%s'" % conn.to_node)
	
	if nodes.size() == 0:
		result.warnings.append("El grafo no tiene nodos")
	
	if connections.size() == 0:
		result.warnings.append("El grafo no tiene conexiones")
	
	return result


## Imprime un resumen del grafo en consola (para debugging)
func debug_print() -> void:
	print("\n=== GraphBuilder Debug ===")
	print("Nodos: %d" % nodes.size())
	for node_data in nodes:
		if node_data:
			print("  - %s (%s)" % [node_data.node_key, node_data.display_name])
	
	print("Conexiones: %d" % connections.size())
	for conn in connections:
		if conn:
			print("  - %s -> %s (weight: %.1f)" % [conn.from_node, conn.to_node, conn.weight])
	
	var validation = validate()
	if not validation.valid:
		print("ERRORES:")
		for err in validation.errors:
			print("  ❌ %s" % err)
	
	if validation.warnings.size() > 0:
		print("ADVERTENCIAS:")
		for warn in validation.warnings:
			print("  ⚠️  %s" % warn)
	
	print("========================\n")
