extends "res://scripts/missions/MissionController.gd"
## Mission 4 - FlowGuard (Maximum Flow)
## Calcula flujo entre origen y sumidero usando Ford-Fulkerson o Edmonds-Karp

const VICTORY_MESSAGE := "Flujo seguro establecido. El ataque ha sido contenido. NEMESIS ha sido aislado."
const DEFAULT_STATUS_PROMPT := "Selecciona fuente y sumidero para iniciar el análisis de flujo."

enum SelectionMode { NONE, SOURCE, SINK }

@export var algorithm: String = "Edmonds-Karp"

var selection_mode: SelectionMode = SelectionMode.NONE
var source_key = null
var sink_key = null
var is_computing := false
var last_result: Dictionary = {}
var required_flow := 0
var attempts := 0

@onready var ford_button: Button = %FordButton
@onready var edmonds_button: Button = %EdmondsButton
@onready var select_source_button: Button = %SelectSourceButton
@onready var select_sink_button: Button = %SelectSinkButton
@onready var compute_button: Button = %ComputeButton
@onready var reset_button: Button = %ResetButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var source_label: Label = %SourceLabel
@onready var sink_label: Label = %SinkLabel
@onready var flow_label: Label = %FlowLabel
@onready var result_label: RichTextLabel = %ResultLabel


func _ready() -> void:
	_connect_ui_signals()
	_subscribe_to_events()
	call_deferred("_init_mission_deferred")


func _init_mission_deferred() -> void:
	call_deferred("init_mission_common", "Mission_4", DEFAULT_STATUS_PROMPT)
	await get_tree().process_frame
	_reset_mission()


func start() -> void:
	# La misión depende de las selecciones del jugador; no se auto-resuelve.
	_update_status(DEFAULT_STATUS_PROMPT)


func step() -> void:
	# No hay pasos discretos en esta mision
	pass


func _connect_ui_signals() -> void:
	if ford_button:
		ford_button.pressed.connect(_on_ford_pressed)
	if edmonds_button:
		edmonds_button.pressed.connect(_on_edmonds_pressed)
		edmonds_button.button_pressed = true
	if select_source_button:
		select_source_button.pressed.connect(_on_select_source_pressed)
	if select_sink_button:
		select_sink_button.pressed.connect(_on_select_sink_pressed)
	if compute_button:
		compute_button.pressed.connect(_on_compute_pressed)
		compute_button.disabled = true
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.visible = false


func _subscribe_to_events() -> void:
	EventBus.mission_completed.connect(_on_mission_completed)


func _reset_mission() -> void:
	if graph and graph.has_method("reset_all_flux"):
		graph.reset_all_flux()
	selection_mode = SelectionMode.NONE
	source_key = null
	sink_key = null
	is_computing = false
	last_result.clear()
	attempts = 0
	required_flow = _calculate_required_flow()
	if source_label:
		source_label.text = "Fuente: --"
	if sink_label:
		sink_label.text = "Sumidero: --"
	if flow_label:
		flow_label.text = "Flujo calculado: 0"
	if result_label:
		result_label.text = "Selecciona el origen (Centro de Control) y el sumidero (Servidor de Respaldo).\n\n[b]Objetivo:[/b] Encuentra un par fuente/sumidero con flujo ≥ %d" % required_flow
	if compute_button:
		compute_button.disabled = true
	if continue_button:
		continue_button.visible = false
	_reset_visuals()
	_update_status("Objetivo: Encuentra un flujo máximo ≥ %d" % required_flow)


func _reset_visuals() -> void:
	if not graph or not ui:
		return
	if graph.has_method("get_nodes") and ui.has_method("set_node_state"):
		for node_key in graph.get_nodes().keys():
			ui.set_node_state(node_key, "unvisited")
	if graph.has_method("get_edges") and ui.has_method("set_edge_state"):
		for edge_data in graph.get_edges():
			var a = edge_data.get("source")
			var b = edge_data.get("target")
			ui.set_edge_state(a, b, "default")


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = "Estado: %s" % message


func _on_ford_pressed() -> void:
	_set_algorithm("Ford-Fulkerson")


func _on_edmonds_pressed() -> void:
	_set_algorithm("Edmonds-Karp")


func _set_algorithm(mode: String) -> void:
	algorithm = mode
	if algorithm == "Ford-Fulkerson":
		if ford_button:
			ford_button.button_pressed = true
		if edmonds_button:
			edmonds_button.button_pressed = false
		_update_status("Algoritmo Ford-Fulkerson seleccionado. Usa DFS para rutas aumentantes.")
	else:
		if edmonds_button:
			edmonds_button.button_pressed = true
		if ford_button:
			ford_button.button_pressed = false
		_update_status("Algoritmo Edmonds-Karp seleccionado. Usa BFS para rutas aumentantes.")


func _on_select_source_pressed() -> void:
	selection_mode = SelectionMode.SOURCE
	_update_status("Haz clic en el nodo que funcionará como fuente.")


func _on_select_sink_pressed() -> void:
	selection_mode = SelectionMode.SINK
	_update_status("Haz clic en el nodo que funcionará como sumidero.")


func _on_reset_pressed() -> void:
	_reset_mission()


func _on_compute_pressed() -> void:
	if source_key == null or sink_key == null:
		_update_status("Define primero la fuente y el sumidero.")
		return
	if source_key == sink_key:
		_update_status("Fuente y sumidero deben ser nodos diferentes.")
		return
	if graph == null:
		_update_status("No hay grafo disponible para calcular.")
		return
	is_computing = true
	_update_status("Calculando flujo máximo usando %s..." % algorithm)
	EventBus.mission_logic_started.emit(mission_id)
	var method = algorithm.to_lower()
	var result := {}
	if method == "ford-fulkerson":
		result = GraphAlgorithms.max_flow_ford_fulkerson(graph, source_key, sink_key, true)
	else:
		result = GraphAlgorithms.max_flow_edmonds_karp(graph, source_key, sink_key, true)
	last_result = result
	_apply_flow_result(result)
	is_computing = false


func _on_continue_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _apply_flow_result(result: Dictionary) -> void:
	var max_flow: int = int(result.get("max_flow", 0))
	attempts += 1
	if flow_label:
		flow_label.text = "Flujo calculado: %d (requerido: %d)" % [max_flow, required_flow]
	if ui:
		if ui.has_method("update_edge_label_mode"):
			ui.update_edge_label_mode("both")
		else:
			ui.edge_label_mode = "both"
	_highlight_source_sink()
	_highlight_flow_edges()
	_show_flow_summary(result)
	
	# Solo completar si se alcanza el umbral
	if max_flow >= required_flow:
		_update_status(VICTORY_MESSAGE)
		if continue_button:
			continue_button.visible = true
		var mission_result = {
			"status": "done",
			"max_flow": max_flow,
			"algorithm": algorithm,
			"source": source_key,
			"sink": sink_key,
			"attempts": attempts,
			"flow_paths": result.get("flow_paths", []).duplicate(true),
			"saturated_edges": result.get("saturated_edges", []).duplicate(true)
		}
		complete(mission_result)
	else:
		_update_status("Flujo insuficiente: %d/%d. Intenta otra combinación." % [max_flow, required_flow])
		# Permitir seleccionar otra pareja
		if graph and graph.has_method("reset_all_flux"):
			graph.reset_all_flux()
		source_key = null
		sink_key = null
		if source_label:
			source_label.text = "Fuente: --"
		if sink_label:
			sink_label.text = "Sumidero: --"
		if compute_button:
			compute_button.disabled = true
		_reset_visuals()


func _highlight_source_sink() -> void:
	if not ui:
		return
	if source_key != null and ui.has_method("set_node_state"):
		ui.set_node_state(source_key, "source")
	if sink_key != null and ui.has_method("set_node_state"):
		ui.set_node_state(sink_key, "sink")


func _highlight_flow_edges() -> void:
	if not ui or not graph:
		return
	var flow_edges = graph.get_flow_edges()
	for edge_info in flow_edges:
		var source = edge_info.get("source")
		var target = edge_info.get("target")
		var flux = edge_info.get("flux", 0)
		var residual = float(edge_info.get("residual", 0.0))
		if flux > 0:
			ui.set_edge_state(source, target, "visited")
			if residual <= 0.0:
				ui.set_edge_state(source, target, "highlighted")


func _show_flow_summary(result: Dictionary) -> void:
	if not result_label:
		return
	var max_flow: int = int(result.get("max_flow", 0))
	var builder := ""
	builder += "[center][b]Flujo seguro establecido[/b][/center]\n"
	builder += "Algoritmo: %s\n" % algorithm
	builder += "Flujo máximo: %d\n\n" % max_flow
	var augmentations: Array = result.get("flow_paths", [])
	if augmentations.is_empty():
		builder += "No se encontraron rutas aumentantes.\n"
	else:
		builder += "Caminos aumentantes:\n"
		for entry in augmentations:
			var path: Array = entry.get("path", [])
			var flow: int = int(entry.get("flow", 0))
			builder += " • %s (Δ=%d)\n" % [_format_path(path), flow]
	var saturated: Array = result.get("saturated_edges", [])
	if not saturated.is_empty():
		builder += "\nAristas saturadas:\n"
		for edge in saturated:
			builder += " • %s -> %s (cap=%.1f)\n" % [str(edge.get("source")), str(edge.get("target")), float(edge.get("capacity", 0.0))]
	builder += "\n%s" % VICTORY_MESSAGE
	result_label.text = builder


func _on_graph_node_selected(node_key) -> void:
	if selection_mode == SelectionMode.NONE:
		_update_status("Presiona 'Definir fuente' o 'Definir sumidero' antes de seleccionar.")
		return
	if selection_mode == SelectionMode.SOURCE:
		_assign_source(node_key)
	else:
		_assign_sink(node_key)
	selection_mode = SelectionMode.NONE
	_maybe_enable_compute()


func _assign_source(node_key) -> void:
	source_key = node_key
	if source_label:
		source_label.text = "Fuente: %s" % str(node_key)
	_highlight_source_sink()
	_update_status("Fuente definida. Ahora selecciona el sumidero o ejecuta el algoritmo si ya está configurado.")


func _assign_sink(node_key) -> void:
	sink_key = node_key
	if sink_label:
		sink_label.text = "Sumidero: %s" % str(node_key)
	_highlight_source_sink()
	_update_status("Sumidero definido. Ejecuta el algoritmo para calcular el flujo máximo.")


func _maybe_enable_compute() -> void:
	if compute_button:
		compute_button.disabled = not (source_key != null and sink_key != null)


func _on_mission_completed(completed_id: String, _success: bool, _result: Dictionary) -> void:
	if completed_id != mission_id:
		return
	if select_source_button:
		select_source_button.disabled = true
	if select_sink_button:
		select_sink_button.disabled = true
	if compute_button:
		compute_button.disabled = true
	if reset_button:
		reset_button.disabled = true


func _format_path(path: Array) -> String:
	var segments: Array = []
	for node in path:
		segments.append(str(node))
	return " -> ".join(segments)


func _calculate_required_flow() -> int:
	# Calcular el flujo máximo posible en el grafo y establecer umbral al 75%
	if graph == null:
		return 5
	var node_keys: Array = graph.get_nodes().keys()
	if node_keys.size() < 2:
		return 5
	var max_possible := 0
	for i in range(min(3, node_keys.size())):
		for j in range(min(3, node_keys.size())):
			if i == j:
				continue
			var result = GraphAlgorithms.max_flow_edmonds_karp(graph, node_keys[i], node_keys[j], false)
			var flow = int(result.get("max_flow", 0))
			if flow > max_possible:
				max_possible = flow
			if graph.has_method("reset_all_flux"):
				graph.reset_all_flux()
	return int(ceil(float(max_possible) * 0.75))
