extends "res://scripts/missions/MissionController.gd"
## Mission Final - Interactividad total
## Cada etapa exige que el jugador ejecute manualmente la logica solicitada

const VICTORY_MESSAGE := "¡Has derrotado a NEMESIS! El núcleo vuelve a estar en control."
const FAILURE_HINT := "Si una etapa no produce un resultado válido, regenera la red para generar otra topología."
const COLOR_PENDING := Color(0.8, 0.8, 0.8, 1.0)
const COLOR_ACTIVE := Color(1.0, 0.8, 0.2, 1.0)
const COLOR_DONE := Color(0.4, 0.85, 0.5, 1.0)

const STAGE_SPECS := [
	{"id": "recon", "title": "1. Reconocimiento", "description": "Sigue el recorrido BFS sin errores."},
	{"id": "path", "title": "2. Camino mínimo", "description": "Selecciona la ruta óptima entre los nodos dados."},
	{"id": "mst", "title": "3. Reconstrucción", "description": "Confirma cada enlace del MST."},
	{"id": "flow", "title": "4. Flujo final", "description": "Encuentra el mejor par fuente/sumidero."}
]

var rng := RandomNumberGenerator.new()
var stage_index := 0
var stage_results: Array = []
var mission_started := false
var graph_builder: GraphBuilder = null
var stage_labels := {}
var active_stage_id := ""

# BFS
var recon_anchor = null
var recon_sequence: Array = []
var recon_progress := 0
var recon_player_order: Array = []

# Camino mínimo
var path_source = null
var path_target = null
var path_sequence: Array = []
var path_progress := 0
var path_player_order: Array = []

# MST
var mst_edges: Array = []
var mst_progress := 0
var mst_pending_node = null
var mst_player_edges: Array = []
var mst_planned_cost := 0.0
var mst_confirmed_nodes := {}

# Flujo
var flow_required := 0
var flow_source = null
var flow_sink = null
var flow_attempts := 0
var flow_last_result: Dictionary = {}

var total_moves := 0
var mistake_count := 0
var stage_move_counters := {}
var stage_mistake_counters := {}

@onready var run_button: Button = %SolveStageButton
@onready var regenerate_button: Button = %RegenerateButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var stage_title_label: Label = %StageTitleLabel
@onready var traversal_status_label: Label = %TraversalStatus
@onready var path_status_label: Label = %PathStatus
@onready var mst_status_label: Label = %MSTStatus
@onready var flow_status_label: Label = %FlowStatus


func _ready() -> void:
	rng.randomize()
	stage_labels = {
		"recon": traversal_status_label,
		"path": path_status_label,
		"mst": mst_status_label,
		"flow": flow_status_label
	}
	_connect_ui()
	_subscribe_to_events()
	graph_builder = get_node_or_null("GraphBuilder") as GraphBuilder
	call_deferred("_init_mission_deferred")


func _init_mission_deferred() -> void:
	call_deferred("init_mission_common", "Mission_Final", "Red lista. Inicia con %s." % STAGE_SPECS[0].title)
	await get_tree().process_frame
	
	# Inicializar métricas de puntuación para misión final
	# Estimación: BFS(n) + Camino(n/2) + MST(n-1) + Flujo(2) = aprox 2.5n movimientos
	if graph:
		var node_count = graph.get_nodes().size()
		optimal_moves = int(node_count * 2.5)  # Estimación de movimientos óptimos
	else:
		optimal_moves = 50  # Default para grafo estándar
	
	time_target = 300.0  # 5 minutos para completar todas las etapas
	
	_reset_progress(true)


func _connect_ui() -> void:
	if run_button:
		run_button.pressed.connect(_on_run_stage_pressed)
	if regenerate_button:
		regenerate_button.pressed.connect(_on_regenerate_pressed)
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.visible = false


func _subscribe_to_events() -> void:
	EventBus.mission_completed.connect(_on_mission_completed)


func _setup_graph() -> void:
	if graph_builder:
		graph = graph_builder.get_graph()
	else:
		graph = Graph.new()
	var display = get_node_or_null("GraphDisplay")
	if display:
		setup(graph, display)
		display.display_graph(graph)
		ui = display
		if display.has_signal("node_selected") and not display.node_selected.is_connected(_on_graph_node_selected):
			display.node_selected.connect(_on_graph_node_selected)


func _reset_progress(reset_graph: bool = false) -> void:
	if reset_graph:
		_regenerate_graph_internal()
	mission_started = false
	stage_index = 0
	stage_results.clear()
	active_stage_id = ""
	total_moves = 0
	mistake_count = 0
	stage_move_counters.clear()
	stage_mistake_counters.clear()
	
	# Reiniciar métricas de MissionController
	moves_count = 0
	mistakes_count = 0
	recon_sequence.clear()
	recon_player_order.clear()
	path_sequence.clear()
	path_player_order.clear()
	mst_edges.clear()
	mst_player_edges.clear()
	mst_confirmed_nodes.clear()
	flow_last_result.clear()
	for spec in STAGE_SPECS:
		stage_move_counters[spec.id] = 0
		stage_mistake_counters[spec.id] = 0
	_set_stage_controls_locked(false)
	if continue_button:
		continue_button.visible = false
	for spec in STAGE_SPECS:
		_update_stage_label(spec.id, "Pendiente", COLOR_PENDING)
	_set_stage_copy()
	_update_status("Red lista. Inicia con %s." % STAGE_SPECS[0].title)
	if detail_label:
		detail_label.text = "[b]Briefing:[/b]\n%s" % STAGE_SPECS[0].description


func _set_stage_copy() -> void:
	if stage_index >= STAGE_SPECS.size():
		return
	var spec = STAGE_SPECS[stage_index]
	if stage_title_label:
		stage_title_label.text = spec.title
	if detail_label:
		detail_label.text = "[b]%s[/b]\n%s" % [spec.title, spec.description]


func _set_stage_controls_locked(locked: bool) -> void:
	if run_button:
		run_button.disabled = locked
		run_button.text = "Etapa en curso..." if locked else "Resolver etapa"
	if regenerate_button:
		regenerate_button.disabled = locked


func _on_run_stage_pressed() -> void:
	if graph == null or graph.get_node_count() == 0:
		_update_status("No hay grafo disponible. Regenera la red.")
		return
	if stage_index >= STAGE_SPECS.size():
		_update_status("Todas las etapas completadas.")
		return
	if active_stage_id != "":
		_update_status("Completa primero la etapa actual.")
		return
	if not mission_started:
		mission_started = true
		EventBus.mission_logic_started.emit(mission_id)
	_set_stage_controls_locked(true)
	var stage_id: String = STAGE_SPECS[stage_index].id
	_start_stage(stage_id)


func _start_stage(stage_id: String) -> void:
	match stage_id:
		"recon":
			_start_recon_stage()
		"path":
			_start_path_stage()
		"mst":
			_start_mst_stage()
		"flow":
			_start_flow_stage()
		_:
			_fail_current_stage(stage_id, "Etapa desconocida.")


func _start_recon_stage() -> void:
	_reset_visuals("weight")
	var node_keys: Array = graph.get_nodes().keys()
	if node_keys.size() <= 1:
		_fail_current_stage("recon", "La red es demasiado pequeña para BFS.")
		return
	recon_anchor = node_keys[rng.randi_range(0, node_keys.size() - 1)]
	recon_sequence = GraphAlgorithms.bfs(graph, recon_anchor, true).get("visited", [])
	if recon_sequence.size() < 2:
		_fail_current_stage("recon", "No se pudo propagar desde %s." % str(recon_anchor))
		return
	recon_progress = 0
	recon_player_order.clear()
	active_stage_id = "recon"
	_update_stage_label("recon", "En progreso", COLOR_ACTIVE)
	_update_status("Selecciona los nodos en orden BFS comenzando en %s." % str(recon_anchor))
	if detail_label:
		detail_label.text = "[b]Objetivo:[/b] Haz clic sobre cada nodo siguiendo el recorrido BFS completo."
	_highlight_next_recon_node()


func _start_path_stage() -> void:
	_reset_visuals("weight")
	var node_keys: Array = graph.get_nodes().keys()
	if node_keys.size() < 2:
		_fail_current_stage("path", "Se requieren al menos dos nodos.")
		return
	var attempt := 0
	var best := {}
	while attempt < 40:
		var source = node_keys[rng.randi_range(0, node_keys.size() - 1)]
		var target = node_keys[rng.randi_range(0, node_keys.size() - 1)]
		if source == target:
			continue
		var data = GraphAlgorithms.shortest_path(graph, source, target)
		if data.get("reachable", false) and data.get("path", []).size() >= 2:
			best = {
				"source": source,
				"target": target,
				"path": data.get("path", []),
				"distance": float(data.get("distance", 0.0))
			}
			break
		attempt += 1
	if best.is_empty():
		_fail_current_stage("path", "No se encontró un camino válido. %s" % FAILURE_HINT)
		return
	path_source = best.source
	path_target = best.target
	path_sequence = best.path
	path_progress = 0
	path_player_order.clear()
	active_stage_id = "path"
	_update_stage_label("path", "En progreso", COLOR_ACTIVE)
	_update_status("Conecta %s → %s siguiendo el camino óptimo." % [str(path_source), str(path_target)])
	if detail_label:
		detail_label.text = "[b]Ruta objetivo:[/b] costo %.2f con %d saltos. Selecciona los nodos en orden." % [best.distance, path_sequence.size()]
	_highlight_next_path_node()


func _start_mst_stage() -> void:
	_reset_visuals("weight")
	var mst_data = GraphAlgorithms.minimum_spanning_tree(graph, "Kruskal")
	mst_edges = mst_data.get("edges", [])
	if mst_edges.is_empty():
		_fail_current_stage("mst", "No se pudo construir un MST. %s" % FAILURE_HINT)
		return
	mst_planned_cost = float(mst_data.get("cost", 0.0))
	mst_progress = 0
	mst_pending_node = null
	mst_player_edges.clear()
	mst_confirmed_nodes.clear()
	active_stage_id = "mst"
	_update_stage_label("mst", "En progreso", COLOR_ACTIVE)
	_update_status("Confirma cada enlace del plan MST (costo %.2f)." % mst_planned_cost)
	if detail_label:
		detail_label.text = "[b]Objetivo:[/b] Selecciona ambos nodos de cada enlace siguiendo el orden mostrado."
	_highlight_current_mst_edge()


func _start_flow_stage() -> void:
	_reset_visuals("both")
	flow_required = _estimate_flow_threshold()
	if flow_required <= 0:
		_fail_current_stage("flow", "No existe flujo útil en esta red.")
		return
	flow_source = null
	flow_sink = null
	flow_attempts = 0
	flow_last_result.clear()
	active_stage_id = "flow"
	_update_stage_label("flow", "En progreso", COLOR_ACTIVE)
	_update_status("Selecciona fuente y sumidero con flujo ≥ %d." % flow_required)
	if detail_label:
		detail_label.text = "[b]Objetivo:[/b] Prueba pares de nodos hasta superar el umbral."


func _on_graph_node_selected(node_key) -> void:
	if active_stage_id == "":
		_update_status("Inicia una etapa antes de interactuar con el grafo.")
		return
	match active_stage_id:
		"recon":
			_handle_recon_selection(node_key)
		"path":
			_handle_path_selection(node_key)
		"mst":
			_handle_mst_selection(node_key)
		"flow":
			_handle_flow_selection(node_key)


func _handle_recon_selection(node_key) -> void:
	if recon_progress >= recon_sequence.size():
		return
	var expected = recon_sequence[recon_progress]
	if node_key != expected:
		_flag_node_error(node_key, "Ese nodo no corresponde al BFS actual.")
		return
	recon_player_order.append(node_key)
	_increment_stage_move("recon")
	var state = "source" if recon_progress == 0 else "visited"
	ui.set_node_state(node_key, state)
	recon_progress += 1
	if recon_progress >= recon_sequence.size():
		var payload := {
			"stage": "recon",
			"anchor": recon_anchor,
			"target_order": recon_sequence.duplicate(),
			"player_order": recon_player_order.duplicate()
		}
		_complete_current_stage(payload)
	else:
		_highlight_next_recon_node()


func _handle_path_selection(node_key) -> void:
	if path_progress >= path_sequence.size():
		return
	var expected = path_sequence[path_progress]
	if node_key != expected:
		_flag_node_error(node_key, "Ese nodo no pertenece al camino óptimo.")
		return
	path_player_order.append(node_key)
	_increment_stage_move("path")
	var state = "source" if path_progress == 0 else ("sink" if path_progress == path_sequence.size() - 1 else "visited")
	ui.set_node_state(node_key, state)
	if path_progress > 0:
		ui.set_edge_state(path_sequence[path_progress - 1], node_key, "visited")
	path_progress += 1
	if path_progress >= path_sequence.size():
		var payload := {
			"stage": "path",
			"source": path_source,
			"target": path_target,
			"path": path_sequence.duplicate(),
			"player_order": path_player_order.duplicate()
		}
		_complete_current_stage(payload)
	else:
		_highlight_next_path_node()


func _handle_mst_selection(node_key) -> void:
	if mst_progress >= mst_edges.size():
		return
	var edge: Dictionary = mst_edges[mst_progress]
	var a = edge.get("source")
	var b = edge.get("target")
	if mst_pending_node == null:
		if node_key != a and node_key != b:
			_flag_node_error(node_key, "Ese nodo no participa en el enlace actual.")
			return
		mst_pending_node = node_key
		_increment_stage_move("mst")
		ui.set_node_state(node_key, "current")
		_update_status("Buen inicio. Selecciona el otro extremo del enlace.")
		return
	if node_key == mst_pending_node:
		_update_status("Elige otro nodo para cerrar la conexión.")
		return
	var expected = a if mst_pending_node == b else b
	if node_key != expected:
		_flag_node_error(node_key, "Ese no es el extremo correcto del enlace.")
		return
	_increment_stage_move("mst")
	ui.set_node_state(mst_pending_node, "visited")
	ui.set_node_state(node_key, "visited")
	ui.set_edge_state(a, b, "visited")
	mst_confirmed_nodes[mst_pending_node] = true
	mst_confirmed_nodes[node_key] = true
	mst_player_edges.append({
		"source": a,
		"target": b,
		"weight": float(edge.get("weight", 0.0))
	})
	mst_pending_node = null
	mst_progress += 1
	if mst_progress >= mst_edges.size():
		var payload := {
			"stage": "mst",
			"edges": mst_edges.duplicate(true),
			"player_edges": mst_player_edges.duplicate(true),
			"cost": mst_planned_cost
		}
		_complete_current_stage(payload)
	else:
		_highlight_current_mst_edge()


func _handle_flow_selection(node_key) -> void:
	if flow_source == null:
		flow_source = node_key
		ui.set_node_state(node_key, "source")
		_update_status("Fuente establecida en %s. Selecciona el sumidero." % str(node_key))
		_increment_stage_move("flow")
		return
	if flow_sink == null:
		if node_key == flow_source:
			_flag_node_error(node_key, "El sumidero debe ser distinto a la fuente.")
			return
		flow_sink = node_key
		ui.set_node_state(node_key, "sink")
		_increment_stage_move("flow")
		_evaluate_flow_choice()
		return
	_update_status("Ya tienes fuente y sumidero. Regenera o reinicia la selección si necesitas otra pareja.")


func _evaluate_flow_choice() -> void:
	flow_attempts += 1
	var ff_result = GraphAlgorithms.max_flow_ford_fulkerson(graph, flow_source, flow_sink, true)
	var ek_result = GraphAlgorithms.max_flow_edmonds_karp(graph, flow_source, flow_sink, true)
	var max_flow := int(ek_result.get("max_flow", 0))
	flow_last_result = ek_result.duplicate(true)
	if max_flow >= flow_required:
		_apply_flow_visual(ek_result, flow_source, flow_sink)
		var payload := {
			"stage": "flow",
			"source": flow_source,
			"sink": flow_sink,
			"max_flow": max_flow,
			"threshold": flow_required,
			"attempts": flow_attempts,
			"edmonds_karp": ek_result.duplicate(true),
			"ford_fulkerson": ff_result.duplicate(true)
		}
		_complete_current_stage(payload)
	else:
		_update_status("Flujo %d < %d. Intenta otra pareja." % [max_flow, flow_required])
		if detail_label:
			detail_label.text = "[b]Resultado insuficiente:[/b] %d unidades. Prueba otros nodos." % max_flow
		graph.reset_all_flux()
		flow_source = null
		flow_sink = null
		_reset_visuals("both")


func _estimate_flow_threshold() -> int:
	var node_keys: Array = graph.get_nodes().keys()
	if node_keys.size() < 2:
		return 0
	var best := 0
	for i in range(node_keys.size()):
		for j in range(node_keys.size()):
			if i == j:
				continue
			var result = GraphAlgorithms.max_flow_edmonds_karp(graph, node_keys[i], node_keys[j], true)
			best = max(best, int(result.get("max_flow", 0)))
	return int(ceil(max(1.0, float(best) * 0.75)))


func _highlight_next_recon_node() -> void:
	if ui == null or recon_progress >= recon_sequence.size():
		return
	var next_node = recon_sequence[recon_progress]
	ui.set_node_state(next_node, "source" if recon_progress == 0 else "candidate")


func _highlight_next_path_node() -> void:
	if ui == null or path_progress >= path_sequence.size():
		return
	var next_node = path_sequence[path_progress]
	var state = "source" if path_progress == 0 else ("sink" if path_progress == path_sequence.size() - 1 else "candidate")
	ui.set_node_state(next_node, state)


func _highlight_current_mst_edge() -> void:
	if ui == null or mst_progress >= mst_edges.size():
		return
	var edge: Dictionary = mst_edges[mst_progress]
	var a = edge.get("source")
	var b = edge.get("target")
	if not mst_confirmed_nodes.has(a):
		ui.set_node_state(a, "candidate")
	if not mst_confirmed_nodes.has(b):
		ui.set_node_state(b, "candidate")


func _flag_node_error(node_key, message: String) -> void:
	_register_stage_mistake(active_stage_id)
	_update_status(message)
	if ui == null:
		return
	ui.set_node_state(node_key, "highlighted")
	var timer = get_tree().create_timer(0.45)
	timer.timeout.connect(func():
		if not is_instance_valid(ui):
			return
		if active_stage_id == "mst" and mst_confirmed_nodes.has(node_key):
			ui.set_node_state(node_key, "visited")
		else:
			ui.set_node_state(node_key, "unvisited")
		match active_stage_id:
			"recon":
				_highlight_next_recon_node()
			"path":
				_highlight_next_path_node()
			"mst":
				_highlight_current_mst_edge()
			_:
				pass
	)


func _complete_current_stage(result: Dictionary) -> void:
	var stage_id = active_stage_id
	result["success"] = true
	result["moves_used"] = stage_move_counters.get(stage_id, 0)
	result["mistakes"] = stage_mistake_counters.get(stage_id, 0)
	stage_results.append(result)
	_update_stage_label(stage_id, "Completada", COLOR_DONE)
	active_stage_id = ""
	_set_stage_controls_locked(false)
	stage_index += 1
	if stage_index >= STAGE_SPECS.size():
		_handle_victory()
	else:
		_set_stage_copy()
		_update_status("Etapa asegurada. Avanza a %s." % STAGE_SPECS[stage_index].title)


func _fail_current_stage(stage_id: String, message: String) -> void:
	_update_stage_label(stage_id, "Pendiente", COLOR_PENDING)
	active_stage_id = ""
	_update_status(message)
	_set_stage_controls_locked(false)


func _reset_visuals(label_mode: String) -> void:
	if ui == null or graph == null:
		return
	if ui.has_method("update_edge_label_mode"):
		ui.update_edge_label_mode(label_mode)
	else:
		ui.edge_label_mode = label_mode
	if ui.has_method("reset_visual_states"):
		ui.reset_visual_states()
	else:
		for node_key in graph.get_nodes().keys():
			ui.set_node_state(node_key, "unvisited")
		for edge_data in graph.get_edges():
			var a = edge_data.get("source")
			var b = edge_data.get("target")
			ui.set_edge_state(a, b, "default")


func _apply_flow_visual(_flow_result: Dictionary, source, sink) -> void:
	_reset_visuals("both")
	if ui == null:
		return
	ui.set_node_state(source, "source")
	ui.set_node_state(sink, "sink")
	var flow_edges: Array = graph.get_flow_edges()
	for info in flow_edges:
		var flux = int(info.get("flux", 0))
		if flux <= 0:
			continue
		var residual = float(info.get("residual", 0.0))
		var state = "visited" if residual > 0.01 else "highlighted"
		ui.set_edge_state(info.get("source"), info.get("target"), state)


func _handle_victory() -> void:
	_update_status(VICTORY_MESSAGE)
	_set_stage_controls_locked(true)
	if continue_button:
		continue_button.visible = true
	if detail_label:
		detail_label.text = "[center][b]%s[/b][/center]\nEtapas resueltas: %d\nNodo(s): %d\nAristas: %d" % [
			VICTORY_MESSAGE,
			stage_results.size(),
			graph.get_node_count() if graph else 0,
			graph.get_edges().size() if graph else 0
		]
	var payload = {
		"status": "done",
		"stages": stage_results.duplicate(true),
		"node_count": graph.get_node_count() if graph else 0,
		"edge_count": graph.get_edges().size() if graph else 0,
		"moves": total_moves,
		"mistakes": mistake_count,
		"stage_moves": stage_move_counters.duplicate(true),
		"stage_mistakes": stage_mistake_counters.duplicate(true)
	}
	complete(payload)


func _increment_stage_move(stage_id: String, amount: int = 1) -> void:
	if stage_id == "":
		return
	total_moves += amount
	var current_value: int = int(stage_move_counters.get(stage_id, 0))
	stage_move_counters[stage_id] = current_value + amount
	
	# Sincronizar con MissionController para scoring
	moves_count = total_moves


func _register_stage_mistake(stage_id: String) -> void:
	if stage_id == "":
		return
	mistake_count += 1
	var current_value: int = int(stage_mistake_counters.get(stage_id, 0))
	stage_mistake_counters[stage_id] = current_value + 1
	
	# Sincronizar con MissionController para scoring
	mistakes_count = mistake_count


func _on_regenerate_pressed() -> void:
	_reset_progress(true)


func _on_continue_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_mission_completed(completed_id: String, _success: bool, _result: Dictionary) -> void:
	if completed_id != mission_id:
		return
	_set_stage_controls_locked(true)


func _update_stage_label(stage_id: String, text: String, color: Color) -> void:
	var label: Label = stage_labels.get(stage_id, null)
	if label:
		label.text = text
		label.modulate = color


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = "Estado: %s" % message


func _format_sequence(entries: Array) -> String:
	if entries.is_empty():
		return "--"
	var parts: Array = []
	for entry in entries:
		parts.append(str(entry))
	return " -> ".join(parts)


func _regenerate_graph_internal() -> void:
	if graph_builder:
		graph = graph_builder.build_graph()
		if ui:
			setup(graph, ui)
			ui.display_graph(graph)
	else:
		graph = Graph.new()

