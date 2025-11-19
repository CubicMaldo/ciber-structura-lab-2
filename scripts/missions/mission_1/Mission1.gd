extends "res://scripts/missions/MissionController.gd"
## Mission 1 - Network Tracer (BFS / DFS)
## Jugador recorre un grafo para encontrar el nodo raiz infectado
## Nota: grafo provisto por el nodo hijo GraphBuilder

const RESTORATION_CODE := "RC-42-ALPHA"
const DEFAULT_STATUS_PROMPT := "Selecciona BFS o DFS y presiona 'Iniciar rastreo'."
const SUCCESS_STATUS_TEMPLATE := "Rastreo completado. Has encontrado el nodo raíz del virus: %s."
const THREAT_PENALTY_MISCLICK := 6
const THREAT_REWARD_CORRECT := 2

@export var turn_limit: int = 18

@export var algorithm: String = "BFS" # "BFS" or "DFS"
var visited := {}
var found_clues: Array = []
var is_running := false
var last_current = null
var threat_manager = null
var turns_remaining: int = 0
var rng := RandomNumberGenerator.new()

var traversal_order: Array = []
var traversal_index: int = 0
var awaiting_selection: bool = false
var candidate_nodes: Dictionary = {}

# Referencias UI
@onready var bfs_button: Button = %BFSButton
@onready var dfs_button: Button = %DFSButton
@onready var start_button: Button = %StartButton
@onready var step_button: Button = %StepButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var clues_label: Label = %CluesLabel
@onready var result_label: RichTextLabel = %ResultLabel
@onready var threat_label: Label = %ThreatLabel
@onready var turns_label: Label = %TurnsLabel
@onready var resources_label: Label = %ResourcesLabel
@onready var scan_button: Button = %ScanButton
@onready var firewall_button: Button = %FirewallButton

func _ready() -> void:
	_connect_ui_signals()
	_subscribe_to_events()
	rng.randomize()
	call_deferred("init_mission_common", "Mission_1", DEFAULT_STATUS_PROMPT)

func set_algorithm(alg: String) -> void:
	algorithm = alg

func start() -> void:
	_reset_before_traversal()
	if threat_manager:
		threat_manager.reset_turns(turn_limit)
		turns_remaining = threat_manager.get_turns_remaining()
		_update_turns_display()
		_sync_resource_display(threat_manager.get_resources())
	_update_status("Preparando rastreo %s..." % algorithm)
	var keys: Array = []
	if graph and graph.has_method("get_nodes"):
		keys = graph.get_nodes().keys()
		keys.sort()
	if keys.size() == 0:
		push_error("Mission_1: graph is empty")
		return
	var start_key = keys[0]
	# Compute traversal order using GraphAlgorithms
	var traversal_result: Dictionary = {}
	if algorithm == "DFS":
		traversal_result = GraphAlgorithms.dfs(graph, start_key, true)
	else:
		traversal_result = GraphAlgorithms.bfs(graph, start_key, true)
	
	# Emitir señal de algoritmo ejecutado para estadísticas
	EventBus.algorithm_executed.emit(algorithm, mission_id)
	
	traversal_order = traversal_result.get("visited", [])
	traversal_index = 0
	if traversal_order.is_empty():
		_update_status("No hay servidores conectados para rastrear.")
		return

	var first_key = traversal_order[0]
	var first_vertex = graph.get_vertex(first_key)
	var first_meta: NetworkNodeMeta = first_vertex.meta as NetworkNodeMeta if first_vertex else null
	var first_label = _format_node_label(first_meta, first_key)
	is_running = true
	awaiting_selection = true
	if continue_button:
		continue_button.visible = false
	if step_button:
		step_button.disabled = true
	if start_button:
		start_button.disabled = true
	_update_status("Punto de entrada identificado: %s. Asegurando la conexión inicial..." % first_label)
	_process_player_selection(first_key, true)
	# Emit mission logic started
	EventBus.mission_logic_started.emit(mission_id)

func step() -> void:
	if not is_running:
		_update_status("Inicia la misión y selecciona nodos en el grafo para avanzar.")
		return
	if not awaiting_selection:
		_update_status("El rastreo ya concluyó. Revisa los resultados o presiona 'Continuar'.")
		return
	_update_status("Selecciona el siguiente nodo en el grafo siguiendo %s." % algorithm)
	_show_candidate_hints()



func _reset_before_traversal() -> void:
	visited.clear()
	found_clues.clear()
	traversal_order.clear()
	traversal_index = 0
	last_current = null
	is_running = false
	awaiting_selection = false
	
	# Reiniciar métricas de puntuación
	moves_count = 0
	mistakes_count = 0
	
	if clues_label:
		clues_label.text = "Pistas: 0"
	if result_label:
		result_label.text = "Rastrea el virus hasta su origen navegando por la red.\n\n[b]Objetivo:[/b] Selecciona BFS o DFS, luego sigue el recorrido haciendo clic en cada nodo en orden para recopilar pistas y encontrar el nodo raíz infectado."
	if continue_button:
		continue_button.visible = false
	if step_button:
		step_button.disabled = true
	if start_button:
		start_button.disabled = false
	if scan_button:
		scan_button.disabled = true
	_clear_candidate_highlights()
	_reset_node_visuals()
	if threat_manager:
		turns_remaining = threat_manager.get_turns_remaining()
		_sync_resource_display(threat_manager.get_resources())
	else:
		turns_remaining = turn_limit
	_update_turns_display()


func _reset_node_visuals() -> void:
	if not graph or not ui:
		return
	if not graph.has_method("get_nodes"):
		return
	var nodes_dict: Dictionary = graph.get_nodes()
	if ui.has_method("set_node_state"):
		for node_key in nodes_dict.keys():
			ui.set_node_state(node_key, "unvisited")
	var node_views_dict = ui.get("node_views")
	if typeof(node_views_dict) == TYPE_DICTIONARY:
		for node_view in node_views_dict.values():
			if node_view and node_view.has_method("hide_clue"):
				node_view.hide_clue()


func _clear_candidate_highlights() -> void:
	if candidate_nodes.is_empty():
		return
	if not ui or not ui.has_method("set_node_state"):
		candidate_nodes.clear()
		return
	for node_key in candidate_nodes.keys():
		if visited.has(node_key):
			continue
		ui.set_node_state(node_key, "unvisited")
	candidate_nodes.clear()


func _show_candidate_hints() -> void:
	_clear_candidate_highlights()
	if not awaiting_selection:
		return
	var expected_key = _get_expected_key()
	if expected_key == null:
		return
	var secondary: Array = []
	if algorithm == "DFS" and last_current != null:
		var last_vertex = graph.get_vertex(last_current)
		if last_vertex:
			for neighbor in last_vertex.get_neighbor_keys():
				if neighbor == expected_key:
					continue
				if visited.has(neighbor):
					continue
				secondary.append(neighbor)
	elif algorithm == "BFS":
		for i in range(0, min(3, traversal_order.size() - traversal_index)):
			var idx_key = traversal_order[traversal_index + i]
			if idx_key == expected_key:
				continue
			if visited.has(idx_key):
				continue
			secondary.append(idx_key)

	_apply_candidate_states(expected_key, secondary)


func _apply_candidate_states(primary_key, secondary: Array) -> void:
	if ui and ui.has_method("set_node_state") and primary_key != null and not visited.has(primary_key):
		ui.set_node_state(primary_key, "candidate")
		candidate_nodes[primary_key] = "candidate"
	for node_key in secondary:
		if ui and ui.has_method("set_node_state") and not visited.has(node_key) and node_key != primary_key:
			ui.set_node_state(node_key, "candidate")
			candidate_nodes[node_key] = "candidate"


# ============================================================================
# SISTEMAS DINÁMICOS (AMENAZA, RECURSOS Y VARIACIÓN DE GRAFO)
# ============================================================================

func _initialize_dynamic_systems() -> void:
	if threat_manager != null:
		return
	threat_manager = _resolve_threat_manager()
	if threat_manager:
		threat_manager.begin_mission_session(mission_id, turn_limit)
		threat_manager.threat_level_changed.connect(_on_threat_level_changed)
		threat_manager.resources_changed.connect(_on_resources_changed)
		threat_manager.turns_changed.connect(_on_turns_changed)
		turns_remaining = threat_manager.get_turns_remaining()
		var current_level = threat_manager.get_threat_level_value()
		var current_state = threat_manager.get_threat_state()
		_on_threat_level_changed(current_level, current_state)
		_sync_resource_display(threat_manager.get_resources())
	else:
		turns_remaining = turn_limit
	_update_turns_display()


func _resolve_threat_manager() -> Node:
	if has_node("/root/ThreatManager"):
		return get_node("/root/ThreatManager")
	if typeof(ThreatManager) == TYPE_OBJECT:
		var candidate: Variant = ThreatManager
		if candidate is Node:
			return candidate
	return null


func _on_threat_level_changed(level: int, state: String) -> void:
	if threat_label:
		var nice_state := state.capitalize()
		threat_label.text = "Amenaza: %d (%s)" % [level, nice_state]
	if state == "critical":
		_update_status("Nivel de amenaza CRÍTICO. Evita errores o usa firewalls.")


func _on_turns_changed(remaining: int) -> void:
	turns_remaining = remaining
	_update_turns_display()


func _update_turns_display() -> void:
	if not turns_label:
		return
	var display_value := "--" if turns_remaining < 0 else str(turns_remaining)
	turns_label.text = "Turnos restantes: %s" % display_value


func _on_resources_changed(resources: Dictionary) -> void:
	_sync_resource_display(resources)


func _sync_resource_display(resources: Dictionary) -> void:
	if resources_label:
		var scans = int(resources.get("scans", 0))
		var firewalls = int(resources.get("firewalls", 0))
		resources_label.text = "Recursos - Escaneos: %d | Firewalls: %d" % [scans, firewalls]
	if scan_button:
		var can_scan = is_running and awaiting_selection and int(resources.get("scans", 0)) > 0
		scan_button.disabled = not can_scan
	if firewall_button:
		firewall_button.disabled = int(resources.get("firewalls", 0)) <= 0


func _consume_turn_for_action(skip_turn: bool) -> void:
	if skip_turn or threat_manager == null:
		return
	turns_remaining = threat_manager.consume_turn()
	_update_turns_display()
	if threat_manager.get_threat_state() == "critical":
		_update_status("Amenaza crítica: cada fallo suma más riesgo.")


func _apply_threat_penalty(amount: int) -> void:
	if threat_manager:
		threat_manager.apply_penalty(amount)


func _reward_micro_progress() -> void:
	if threat_manager:
		threat_manager.apply_relief(THREAT_REWARD_CORRECT)


func _reward_mission_victory() -> void:
	if threat_manager:
		threat_manager.apply_relief(15)
		threat_manager.add_resource("scans", 1)


func _on_scan_pressed() -> void:
	if not is_running or not awaiting_selection:
		_update_status("No hay nodos pendientes para escanear.")
		return
	if not threat_manager or not threat_manager.spend_resource("scans", 1):
		_update_status("Sin escaneos disponibles.")
		return
	
	# Registrar uso de recursos
	resources_used += 1
	EventBus.resource_used.emit("scan", mission_id)
	
	var expected = _get_expected_key()
	if expected == null:
		_update_status("No hay objetivo para revelar.")
		return
	_update_status("Escaneo identifica el siguiente servidor crítico.")
	_process_player_selection(expected, true)


func _on_firewall_pressed() -> void:
	if not threat_manager or not threat_manager.spend_resource("firewalls", 1):
		_update_status("Sin firewalls para desplegar.")
		return
	
	# Registrar uso de recursos
	resources_used += 1
	EventBus.resource_used.emit("firewall", mission_id)
	
	threat_manager.apply_relief(12)
	_update_status("Firewall reforzado. Amenaza reducida.")


func _mutate_graph() -> void:
	if graph == null:
		return
	var nodes_dict: Dictionary = graph.get_nodes()
	if nodes_dict.is_empty():
		return
	var keys: Array = nodes_dict.keys()
	_assign_dynamic_root(keys)
	_inject_shortcuts(keys)


func _assign_dynamic_root(keys: Array) -> void:
	if keys.is_empty():
		return
	var chosen_key = keys[rng.randi_range(0, keys.size() - 1)]
	for key in keys:
		var vertex = graph.get_vertex(key)
		if vertex and vertex.meta is NetworkNodeMeta:
			vertex.meta.is_root = key == chosen_key


func _inject_shortcuts(keys: Array) -> void:
	if keys.size() < 3:
		return
	var added := 0
	var attempts := 0
	while added < 2 and attempts < 10:
		attempts += 1
		var a = keys[rng.randi_range(0, keys.size() - 1)]
		var b = keys[rng.randi_range(0, keys.size() - 1)]
		if a == b or graph.has_edge(a, b):
			continue
		var weight = rng.randf_range(1.0, 4.0)
		graph.add_connection(a, b, weight)
		added += 1


func _format_node_label(node_meta: NetworkNodeMeta, node_key) -> String:
	if node_meta:
		if node_meta.display_name != "":
			return "%s" % node_meta.display_name
		if node_meta.device_type != "":
			return "%s %s" % [node_meta.device_type, str(node_key)]
	return "Servidor %s" % str(node_key)


func _get_expected_key() -> Variant:
	if traversal_index >= traversal_order.size():
		return null
	return traversal_order[traversal_index]


func _on_graph_node_selected(node_key) -> void:
	_process_player_selection(node_key)


func _process_player_selection(node_key, _is_auto := false) -> void:
	if not graph or not awaiting_selection:
		return
	if not is_running:
		_update_status("Inicia la misión antes de interactuar con el grafo.")
		return
	
	# Contar este movimiento
	if not _is_auto:
		add_move()
	
	_consume_turn_for_action(_is_auto)
	var expected_key = _get_expected_key()
	if expected_key == null:
		awaiting_selection = false
		return
	if node_key != expected_key:
		_handle_incorrect_selection(node_key)
		return
	if visited.has(node_key):
		_update_status("Ese servidor ya fue asegurado. Elige otro destino.")
		add_mistake()  # Error: nodo ya visitado
		return

	awaiting_selection = false
	if last_current != null and last_current != node_key:
		_mark_previous_visited(last_current)

	_set_current(node_key)
	var vertex = graph.get_vertex(node_key)
	visited[node_key] = true
	_reward_micro_progress()
	if vertex:
		var node_meta: NetworkNodeMeta = vertex.meta as NetworkNodeMeta
		var node_label = _format_node_label(node_meta, node_key)
		_update_status("Investigando %s..." % node_label)
		var finished = _handle_vertex_visit(vertex, node_meta, node_key, node_label)
		if finished:
			_clear_candidate_highlights()
			awaiting_selection = false
			is_running = false
			traversal_index = traversal_order.size()
			return

	traversal_index += 1
	if traversal_index >= traversal_order.size():
		_clear_candidate_highlights()
		awaiting_selection = false
		is_running = false
		var exhausted_msg = "El rastreo terminó sin detectar el nodo raíz. " \
			+ "Revisa las pistas recopiladas."
		_update_status(exhausted_msg)
		var exhausted_result := {
			"status": "exhausted",
			"clues": found_clues.duplicate(),
			"order": traversal_order.duplicate(),
			"algorithm": algorithm
		}
		_apply_threat_penalty(8)
		complete(exhausted_result)
		return

	var remaining = traversal_order.size() - traversal_index
	awaiting_selection = true
	var next_msg = "Nodo asegurado. Determina el siguiente servidor usando %s " % algorithm
	next_msg += "(%d restantes)." % remaining
	_update_status(next_msg)
	_show_candidate_hints()
	if threat_manager:
		_sync_resource_display(threat_manager.get_resources())


func _handle_incorrect_selection(node_key) -> void:
	add_mistake()  # Registrar el error
	EventBus.mistake_made.emit(mission_id)  # Emitir señal para estadísticas
	
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "highlighted")
		call_deferred("_reset_highlighted_node", node_key)
		var wrong_msg = "Ese nodo no corresponde al recorrido %s. " % algorithm
		wrong_msg += "Revisa la lógica de %s." % algorithm
		_update_status(wrong_msg)
	_apply_threat_penalty(THREAT_PENALTY_MISCLICK)


func _reset_highlighted_node(node_key) -> void:
	if not ui:
		return
	if visited.has(node_key):
		return
	if ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "unvisited")
	_show_candidate_hints()

# ============================================================================
# UI SETUP AND EVENT HANDLING
# ============================================================================


func _mark_previous_visited(prev_key) -> void:
	# Mark previous node visually and emit the appropriate EventBus signal
	if prev_key == null:
		return
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(prev_key, "visited")
	var prev_v = graph.get_vertex(prev_key)
	if prev_v:
		EventBus.node_state_changed.emit(prev_v, "visited")


func _set_current(node_key) -> void:
	# Update last_current and set UI state for the current node
	last_current = node_key
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "current")
	elif ui and ui.has_method("highlight_node"):
		ui.highlight_node(node_key)


func _handle_vertex_visit(vertex, node_meta: NetworkNodeMeta, node_key, node_label: String) -> bool:
	# Emit node visited and process NetworkNodeMeta (clues, root detection).
	# Returns true if mission completed (root found).
	EventBus.node_visited.emit(vertex)

	if node_meta:
		if node_meta.has_clue():
			var msg = node_meta.hidden_message
			found_clues.append(msg)
			if ui and ui.has_method("show_node_clue"):
				ui.show_node_clue(node_key, msg)
			_update_clues_display()
			print("Pista encontrada en %s: %s" % [str(node_key), msg])

		if node_meta.is_root:
			if ui and ui.has_method("set_node_state"):
				ui.set_node_state(node_key, "root")
			EventBus.node_state_changed.emit(vertex, "root")
			_clear_candidate_highlights()
			_update_status(SUCCESS_STATUS_TEMPLATE % node_label)
			var result = {
				"status": "done",
				"root": node_key,
				"clues": found_clues.duplicate(),
				"restoration_code": RESTORATION_CODE,
				"algorithm": algorithm,
				"order": traversal_order.duplicate()
			}
			_reward_mission_victory()
			complete(result)
			return true

	return false


func _connect_ui_signals() -> void:
	if bfs_button:
		bfs_button.pressed.connect(_on_bfs_pressed)
		bfs_button.button_pressed = true  # Default selection
	
	if dfs_button:
		dfs_button.pressed.connect(_on_dfs_pressed)
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	if step_button:
		step_button.pressed.connect(_on_step_pressed)
		step_button.disabled = true
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.visible = false  # Hidden until mission completes

	if scan_button:
		scan_button.pressed.connect(_on_scan_pressed)
		scan_button.disabled = true

	if firewall_button:
		firewall_button.pressed.connect(_on_firewall_pressed)


func _subscribe_to_events() -> void:
	EventBus.node_visited.connect(_on_node_visited)
	EventBus.mission_completed.connect(_on_mission_completed)


# ============================================================================
# UI EVENT HANDLERS
# ============================================================================

func _on_bfs_pressed() -> void:
	set_algorithm("BFS")
	_update_status("Algoritmo: BFS seleccionado")
	if dfs_button:
		dfs_button.button_pressed = false
	if bfs_button:
		bfs_button.button_pressed = true


func _on_dfs_pressed() -> void:
	set_algorithm("DFS")
	_update_status("Algoritmo: DFS seleccionado")
	if bfs_button:
		bfs_button.button_pressed = false
	if dfs_button:
		dfs_button.button_pressed = true


func _on_start_pressed() -> void:
	# Establecer movimientos óptimos para el algoritmo seleccionado
	if graph:
		var node_count = graph.get_nodes().size()
		optimal_moves = node_count  # Un clic por nodo = óptimo
	
	# Configurar recursos
	if threat_manager:
		resources_available = threat_manager.get_max_resources()
		resources_used = 0
	
	start()


func _on_step_pressed() -> void:
	step()


func _on_continue_pressed() -> void:
	# Return to mission select after viewing victory screen
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_node_visited(_vertex) -> void:
	# Update clues display (already handled in step(), this is for external listeners)
	_update_clues_display()


func _on_mission_completed(completed_mission_id: String, success: bool, result: Dictionary) -> void:
	if completed_mission_id != mission_id:
		return
	
	is_running = false
	if threat_manager:
		_sync_resource_display(threat_manager.get_resources())
	
	# Disable all control buttons
	if step_button:
		step_button.disabled = true
	if start_button:
		start_button.disabled = true
	if bfs_button:
		bfs_button.disabled = true
	if dfs_button:
		dfs_button.disabled = true
	
	# Show continue button to return to mission select
	if continue_button:
		continue_button.visible = true
	
	if success and result.has("root"):
		var root = result.get("root", "?")
		var code = result.get("restoration_code", "N/A")
		var clues = result.get("clues", [])
		var algorithm_used = result.get("algorithm", algorithm)
		
		var root_label = str(root)
		_update_status(SUCCESS_STATUS_TEMPLATE % root_label)
		if result_label:
			result_label.text = "[center][b][color=green]Rastreo completado" \
				+ "[/color][/b][/center]\n\n"
			result_label.text += "Has encontrado el nodo raíz del virus: %s\n" % root_label
			result_label.text += "Código de restauración desbloqueado: %s\n" % code
			result_label.text += "Algoritmo utilizado: %s\n\n" % algorithm_used
			result_label.text += "[b]Pistas recopiladas:[/b]\n"
			for i in range(clues.size()):
				result_label.text += "%d. %s\n" % [i + 1, clues[i]]
			result_label.text += "\n[center][color=yellow]Presiona 'Continuar' "
			result_label.text += "para volver al menú[/color][/center]"
	else:
		var active_msg = "El rastro del virus sigue activo. "
		active_msg += "Reintenta el análisis o revisa las pistas."
		_update_status(active_msg)
		if result_label:
			result_label.text = "[center][b][color=orange]Rastreo inconcluso" \
				+ "[/color][/b][/center]\n\n"
			var inconclusive_msg = "El virus NEMESIS continúa oculto. Analiza las pistas "
			inconclusive_msg += "y reinicia el rastreo desde el menú."
			result_label.text += inconclusive_msg


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = "Estado: " + message


func _update_clues_display() -> void:
	# Show only a compact counter in the HUD. The full clue text is
	# displayed on the node visuals via `show_node_clue`.
	if clues_label:
		var clue_count = found_clues.size()
		clues_label.text = "Pistas: %d" % clue_count
