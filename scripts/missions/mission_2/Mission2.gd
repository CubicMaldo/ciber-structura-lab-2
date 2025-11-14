extends "res://scripts/missions/MissionController.gd"
## Mission 2 - Shortest Path (Dijkstra)
## El jugador debe trazar la ruta más segura entre el Centro de Control y el Servidor Infectado.
## NOTA: El grafo se construye desde el nodo hijo "GraphBuilder" en la escena.

const VICTORY_MESSAGE := "Camino óptimo establecido. Los paquetes maliciosos han sido contenidos."
const DEFAULT_STATUS_PROMPT := "Presiona 'Calcular Ruta' para encontrar el camino más seguro."
const SUCCESS_STATUS_TEMPLATE := "Ruta segura establecida con costo total: %.1f"

var source_key = "Control Center"
var target_key = "Infected Server"
var optimal_path: Array = []
var path_index: int = 0
var total_distance: float = 0.0
var accumulated_distance: float = 0.0
var is_running := false
var awaiting_selection: bool = false

# UI references
@onready var calculate_button: Button = %CalculateButton
@onready var step_button: Button = %StepButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var distance_label: Label = %DistanceLabel
@onready var result_label: RichTextLabel = %ResultLabel

func _ready() -> void:
	_connect_ui_signals()
	_subscribe_to_events()
	mission_id = "Mission_2"
	
	# Obtener el grafo desde el GraphBuilder hijo (desacoplado)
	var graph_builder = get_node_or_null("GraphBuilder") as GraphBuilder
	if graph_builder:
		graph = graph_builder.get_graph()
		print("Mission_2: Grafo cargado desde GraphBuilder con %d nodos" % graph.get_nodes().size())
	else:
		push_error("Mission_2: No se encontró nodo GraphBuilder.")
		graph = Graph.new()
		return
	
	# Hook display if present in scene
	var display = get_node_or_null("GraphDisplay")
	if display:
		setup(graph, display)
		display.display_graph(graph)
		if display.has_signal("node_selected"):
			display.node_selected.connect(_on_graph_node_selected)
	else:
		push_warning("Mission_2: No se encontró GraphDisplay para visualización")
	
	_reset_mission()
	_update_status(DEFAULT_STATUS_PROMPT)
	_mark_source_and_target()


func _mark_source_and_target() -> void:
	"""Marca visualmente el nodo fuente y destino"""
	if not ui or not graph:
		return
	
	# Verificar que los nodos existen
	if not graph.has_vertex(source_key):
		push_warning("Mission_2: No se encontró nodo fuente '%s'" % source_key)
		return
	if not graph.has_vertex(target_key):
		push_warning("Mission_2: No se encontró nodo destino '%s'" % target_key)
		return
	
	# Marcar visualmente
	if ui.has_method("set_node_state"):
		ui.set_node_state(source_key, "highlighted")
		ui.set_node_state(target_key, "root")


func start() -> void:
	"""Calcula el camino óptimo usando Dijkstra"""
	_reset_mission()
	_update_status("Calculando ruta óptima usando algoritmo de Dijkstra...")
	
	# Validar que los nodos existen
	if not graph.has_vertex(source_key):
		_update_status("Error: No se encontró el nodo fuente '%s'" % source_key)
		return
	if not graph.has_vertex(target_key):
		_update_status("Error: No se encontró el nodo destino '%s'" % target_key)
		return
	
	# Calcular camino óptimo usando Dijkstra
	var result = GraphAlgorithms.shortest_path(graph, source_key, target_key)
	
	if not result["reachable"]:
		_handle_unreachable()
		return
	
	optimal_path = result["path"]
	total_distance = result["distance"]
	path_index = 0
	accumulated_distance = 0.0
	
	if optimal_path.is_empty():
		_update_status("Error: No se pudo calcular el camino.")
		return
	
	is_running = true
	awaiting_selection = true
	
	if continue_button:
		continue_button.visible = false
	if step_button:
		step_button.disabled = false
	if calculate_button:
		calculate_button.disabled = true
	
	_update_status("Camino encontrado con costo total: %.1f. Selecciona los nodos en orden para trazar la ruta." % total_distance)
	_update_distance_display()
	
	# Marcar el primer nodo (fuente) automáticamente
	_mark_node_in_path(source_key, true)
	path_index = 1  # Ya visitamos el nodo fuente
	
	if path_index >= optimal_path.size():
		_complete_mission()
		return
	
	_show_next_hint()
	
	# Emit mission logic started
	EventBus.mission_logic_started.emit(mission_id)


func step() -> void:
	"""Avanza un paso (para debugging, la interacción principal es por selección de nodos)"""
	if not is_running:
		_update_status("Primero calcula la ruta presionando 'Calcular Ruta'.")
		return
	if not awaiting_selection:
		_update_status("La misión ya concluyó. Presiona 'Continuar' para volver al menú.")
		return
	
	_update_status("Selecciona el siguiente nodo en el grafo: %s" % str(optimal_path[path_index]))


func _handle_unreachable() -> void:
	"""Maneja el caso cuando no hay ruta entre fuente y destino"""
	_update_status("No existe ruta desde '%s' hasta '%s'. El servidor está aislado de la red." % [source_key, target_key])
	is_running = false
	awaiting_selection = false
	if calculate_button:
		calculate_button.disabled = false
	if step_button:
		step_button.disabled = true


func _reset_mission() -> void:
	"""Reinicia el estado de la misión"""
	optimal_path.clear()
	path_index = 0
	total_distance = 0.0
	accumulated_distance = 0.0
	is_running = false
	awaiting_selection = false
	
	if distance_label:
		distance_label.text = "Distancia acumulada: 0.0"
	if result_label:
		result_label.text = ""
	if continue_button:
		continue_button.visible = false
	if step_button:
		step_button.disabled = true
	if calculate_button:
		calculate_button.disabled = false
	
	_reset_node_visuals()
	_mark_source_and_target()


func _reset_node_visuals() -> void:
	"""Reinicia el estado visual de todos los nodos"""
	if not graph or not ui:
		return
	if not graph.has_method("get_nodes"):
		return
	
	var nodes_dict: Dictionary = graph.get_nodes()
	if ui.has_method("set_node_state"):
		for node_key in nodes_dict.keys():
			ui.set_node_state(node_key, "unvisited")


func _show_next_hint() -> void:
	"""Muestra una pista visual del siguiente nodo esperado"""
	if not awaiting_selection or path_index >= optimal_path.size():
		return
	
	var expected_key = optimal_path[path_index]
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(expected_key, "candidate")


func _on_graph_node_selected(node_key) -> void:
	"""Maneja la selección de un nodo por parte del jugador"""
	_process_player_selection(node_key)


func _process_player_selection(node_key) -> void:
	"""Procesa la selección del jugador y valida si es correcta"""
	if not graph or not awaiting_selection:
		return
	
	if not is_running:
		_update_status("Primero calcula la ruta presionando 'Calcular Ruta'.")
		return
	
	if path_index >= optimal_path.size():
		_update_status("Ya completaste la ruta. Presiona 'Continuar' para volver al menú.")
		return
	
	var expected_key = optimal_path[path_index]
	
	if node_key != expected_key:
		_handle_incorrect_selection(node_key, expected_key)
		return
	
	# Selección correcta
	_mark_node_in_path(node_key, false)
	
	# Calcular distancia del segmento
	if path_index > 0:
		var prev_key = optimal_path[path_index - 1]
		var edge_weight = graph.get_edge_weight(prev_key, node_key)
		if edge_weight != null:
			accumulated_distance += edge_weight
			_update_distance_display()
	
	path_index += 1
	
	# Verificar si completamos la ruta
	if path_index >= optimal_path.size():
		_complete_mission()
		return
	
	# Continuar con el siguiente nodo
	var remaining = optimal_path.size() - path_index
	_update_status("Correcto. Selecciona el siguiente nodo en la ruta (%d restantes)." % remaining)
	_show_next_hint()


func _mark_node_in_path(node_key, is_first: bool) -> void:
	"""Marca un nodo como parte del camino óptimo"""
	var vertex = graph.get_vertex(node_key)
	if not vertex:
		return
	
	# Actualizar estado visual
	if is_first:
		if ui and ui.has_method("set_node_state"):
			ui.set_node_state(node_key, "current")
	else:
		if ui and ui.has_method("set_node_state"):
			ui.set_node_state(node_key, "visited")
	
	# Emitir señal
	EventBus.node_visited.emit(vertex)
	
	# Marcar la arista si no es el primer nodo
	if path_index > 0 and path_index < optimal_path.size():
		var prev_key = optimal_path[path_index - 1]
		var edge = graph.get_edge_resource(prev_key, node_key)
		if edge:
			EventBus.edge_visited.emit(edge)


func _handle_incorrect_selection(selected_key, expected_key) -> void:
	"""Maneja una selección incorrecta del jugador"""
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(selected_key, "highlighted")
		call_deferred("_reset_highlighted_node", selected_key)
	
	_update_status("Incorrecto. Se esperaba '%s', pero seleccionaste '%s'. Intenta de nuevo." % [expected_key, selected_key])


func _reset_highlighted_node(node_key) -> void:
	"""Resetea el resaltado de un nodo después de un error"""
	await get_tree().create_timer(0.5).timeout
	if not ui or not graph:
		return
	
	if ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "unvisited")
	
	_mark_source_and_target()
	_show_next_hint()


func _complete_mission() -> void:
	"""Completa la misión exitosamente"""
	awaiting_selection = false
	is_running = false
	
	# Marcar el nodo destino
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(target_key, "root")
	
	_update_status(SUCCESS_STATUS_TEMPLATE % accumulated_distance)
	
	# Mostrar resultado detallado
	if result_label:
		result_label.text = "[center][b][color=green]%s[/color][/b][/center]\n\n" % VICTORY_MESSAGE
		result_label.text += "Ruta óptima encontrada:\n"
		for i in range(optimal_path.size()):
			var node_key = optimal_path[i]
			result_label.text += "%d. %s" % [i + 1, str(node_key)]
			if i < optimal_path.size() - 1:
				var next_key = optimal_path[i + 1]
				var edge_weight = graph.get_edge_weight(node_key, next_key)
				if edge_weight != null:
					result_label.text += " → (costo: %.1f)" % edge_weight
			result_label.text += "\n"
		result_label.text += "\n[b]Costo total:[/b] %.1f\n" % accumulated_distance
		result_label.text += "[b]Distancia óptima calculada:[/b] %.1f\n" % total_distance
		result_label.text += "\n[center][color=yellow]Presiona 'Continuar' para volver al menú[/color][/center]"
	
	# Emitir señal de completado
	var result = {
		"status": "done",
		"path": optimal_path.duplicate(),
		"distance": accumulated_distance,
		"optimal_distance": total_distance,
		"algorithm": "Dijkstra"
	}
	complete(result)


func _update_status(message: String) -> void:
	"""Actualiza el mensaje de estado"""
	if status_label:
		status_label.text = "Estado: " + message


func _update_distance_display() -> void:
	"""Actualiza la visualización de la distancia acumulada"""
	if distance_label:
		distance_label.text = "Distancia acumulada: %.1f / %.1f" % [accumulated_distance, total_distance]


# ============================================================================
# UI SETUP AND EVENT HANDLING
# ============================================================================

func _connect_ui_signals() -> void:
	"""Conecta las señales de los botones UI"""
	if calculate_button:
		calculate_button.pressed.connect(_on_calculate_pressed)
	
	if step_button:
		step_button.pressed.connect(_on_step_pressed)
		step_button.disabled = true
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.visible = false


func _subscribe_to_events() -> void:
	"""Suscribe a eventos del EventBus"""
	EventBus.node_visited.connect(_on_node_visited)
	EventBus.mission_completed.connect(_on_mission_completed)


func _on_calculate_pressed() -> void:
	"""Maneja el evento del botón Calcular Ruta"""
	start()


func _on_step_pressed() -> void:
	"""Maneja el evento del botón Paso"""
	step()


func _on_continue_pressed() -> void:
	"""Maneja el evento del botón Continuar (volver al menú)"""
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_node_visited(_vertex) -> void:
	"""Maneja el evento de nodo visitado (para listeners externos)"""
	pass  # Ya manejado en _mark_node_in_path


func _on_mission_completed(completed_mission_id: String, success: bool, _result: Dictionary) -> void:
	"""Maneja el evento de misión completada"""
	if completed_mission_id != mission_id:
		return
	
	is_running = false
	
	# Deshabilitar controles
	if step_button:
		step_button.disabled = true
	if calculate_button:
		calculate_button.disabled = true
	
	# Mostrar botón de continuar
	if continue_button:
		continue_button.visible = true
	
	if not success:
		_update_status("La misión no se completó correctamente. Intenta de nuevo.")
