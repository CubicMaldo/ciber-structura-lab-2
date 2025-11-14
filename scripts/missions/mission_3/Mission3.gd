extends "res://scripts/missions/MissionController.gd"
## Mission 3 - RebuildNet (Minimum Spanning Tree)
## El jugador reconstruye la red aplicando Kruskal o Prim para asegurar la conectividad al menor costo.

const VICTORY_MESSAGE := "Reconstrucción completada. Todos los servidores vuelven a estar sincronizados."
const DEFAULT_STATUS_PROMPT := "Selecciona Kruskal o Prim y presiona 'Reconstruir red'."
const SUCCESS_STATUS_TEMPLATE := "Reconstrucción completada. Costo total: %.1f"

@export var algorithm: String = "Kruskal" # "Kruskal" or "Prim"

var mst_edges: Array = []
var edge_index: int = 0
var accumulated_cost: float = 0.0
var planned_cost: float = 0.0
var is_running := false
var awaiting_selection := false
var pending_node = null
var candidate_nodes: Dictionary = {}
var connected_nodes: Dictionary = {}
var components: int = 0

# UI references
@onready var kruskal_button: Button = %KruskalButton
@onready var prim_button: Button = %PrimButton
@onready var start_button: Button = %StartButton
@onready var step_button: Button = %StepButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var cost_label: Label = %CostLabel
@onready var result_label: RichTextLabel = %ResultLabel


func _ready() -> void:
	_connect_ui_signals()
	_subscribe_to_events()
	mission_id = "Mission_3"
	var graph_builder = get_node_or_null("GraphBuilder") as GraphBuilder
	if graph_builder:
		graph = graph_builder.get_graph()
		print("Mission_3: Grafo cargado desde GraphBuilder con %d nodos" % graph.get_nodes().size())
	else:
		push_error("Mission_3: No se encontró nodo GraphBuilder.")
		graph = Graph.new()
		return

	var display = get_node_or_null("GraphDisplay")
	if display:
		setup(graph, display)
		display.display_graph(graph)
		if display.has_signal("node_selected"):
			display.node_selected.connect(_on_graph_node_selected)
	else:
		push_warning("Mission_3: No se encontró GraphDisplay para visualización")

	_reset_mission()
	_update_status(DEFAULT_STATUS_PROMPT)


func set_algorithm(mode: String) -> void:
	algorithm = mode


func start() -> void:
	_reset_mission()
	if not graph:
		_update_status("No se encontró grafo para reconstruir.")
		return
	if graph.get_node_count() == 0:
		_update_status("No hay servidores registrados en la red.")
		return

	var mst_data := GraphAlgorithms.minimum_spanning_tree(graph, algorithm)
	mst_edges = mst_data.get("edges", [])
	planned_cost = float(mst_data.get("cost", 0.0))
	components = int(mst_data.get("components", 0))

	if mst_edges.is_empty():
		_update_status("No se pudo trazar un árbol de expansión mínima. Revisa las conexiones disponibles.")
		return

	is_running = true
	awaiting_selection = true
	edge_index = 0
	pending_node = null
	if continue_button:
		continue_button.visible = false
	if start_button:
		start_button.disabled = true
	if step_button:
		step_button.disabled = false

	_update_status("Plan de reconstrucción listo. Selecciona los nodos del primer enlace seguro (%s)." % algorithm)
	_highlight_current_edge()
	EventBus.mission_logic_started.emit(mission_id)


func step() -> void:
	if not is_running:
		_update_status("Presiona 'Reconstruir red' para iniciar el plan MST.")
		return
	if not awaiting_selection:
		_update_status("La reconstrucción ya está en curso. Completa la conexión actual.")
		return
	_update_status("Selecciona los dos nodos conectados por el siguiente enlace seguro.")
	_highlight_current_edge()


func _reset_mission() -> void:
	mst_edges.clear()
	edge_index = 0
	accumulated_cost = 0.0
	planned_cost = 0.0
	is_running = false
	awaiting_selection = false
	pending_node = null
	candidate_nodes.clear()
	connected_nodes.clear()
	components = 0
	if cost_label:
		cost_label.text = "Costo acumulado: 0.0"
	if result_label:
		result_label.text = ""
	if continue_button:
		continue_button.visible = false
	if step_button:
		step_button.disabled = true
	if start_button:
		start_button.disabled = false
	_reset_visuals()


func _reset_visuals() -> void:
	if not graph or not ui:
		return
	var nodes_dict: Dictionary = graph.get_nodes()
	if ui.has_method("set_node_state"):
		for node_key in nodes_dict.keys():
			ui.set_node_state(node_key, "unvisited")
	if graph.has_method("get_edges") and ui.has_method("set_edge_state"):
		for edge_info in graph.get_edges():
			var a = edge_info.get("source")
			var b = edge_info.get("target")
			ui.set_edge_state(a, b, "default")


func _clear_candidate_states() -> void:
	if candidate_nodes.is_empty():
		return
	if not ui or not ui.has_method("set_node_state"):
		candidate_nodes.clear()
		return
	for node_key in candidate_nodes.keys():
		if connected_nodes.has(node_key):
			ui.set_node_state(node_key, "visited")
		else:
			ui.set_node_state(node_key, "unvisited")
	candidate_nodes.clear()


func _highlight_current_edge() -> void:
	_clear_candidate_states()
	if not awaiting_selection:
		return
	if edge_index >= mst_edges.size():
		return
	var edge = mst_edges[edge_index]
	var a = edge.get("source")
	var b = edge.get("target")
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(a, "candidate")
		ui.set_node_state(b, "candidate")
		candidate_nodes[a] = true
		candidate_nodes[b] = true
	if ui and ui.has_method("set_edge_state"):
		ui.set_edge_state(a, b, "active")


func _on_graph_node_selected(node_key) -> void:
	_process_node_selection(node_key)


func _process_node_selection(node_key) -> void:
	if not is_running or not awaiting_selection:
		return
	if edge_index >= mst_edges.size():
		return
	var edge = mst_edges[edge_index]
	var a = edge.get("source")
	var b = edge.get("target")
	if pending_node == null:
		if node_key != a and node_key != b:
			_handle_incorrect_node(node_key, a, b)
			return
		pending_node = node_key
		if ui and ui.has_method("set_node_state"):
			ui.set_node_state(node_key, "current")
		_update_status("Buen inicio. Ahora selecciona el otro extremo para conectar %s ↔ %s." % [str(a), str(b)])
		return

	if node_key == pending_node:
		pending_node = null
		_update_status("Selección cancelada. Elige nuevamente cualquiera de los nodos del enlace indicado.")
		if not connected_nodes.has(node_key) and ui and ui.has_method("set_node_state"):
			ui.set_node_state(node_key, "candidate")
		return

	var expected = b if pending_node == a else a
	if node_key != expected:
		_handle_incorrect_node(node_key, a, b)
		return

	_confirm_edge(edge)


func _confirm_edge(edge: Dictionary) -> void:
	var a = edge.get("source")
	var b = edge.get("target")
	var weight = float(edge.get("weight", 0.0))
	pending_node = null
	awaiting_selection = false
	accumulated_cost += weight
	connected_nodes[a] = true
	connected_nodes[b] = true
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(a, "visited")
		ui.set_node_state(b, "visited")
	if ui and ui.has_method("set_edge_state"):
		ui.set_edge_state(a, b, "visited")
	_update_cost_display()
	_clear_candidate_states()
	var edge_resource = graph.get_edge_resource(a, b)
	if edge_resource:
		EventBus.edge_visited.emit(edge_resource)
	var vertex_a = graph.get_vertex(a)
	var vertex_b = graph.get_vertex(b)
	if vertex_a:
		EventBus.node_state_changed.emit(vertex_a, "visited")
	if vertex_b:
		EventBus.node_state_changed.emit(vertex_b, "visited")

	edge_index += 1
	if edge_index >= mst_edges.size():
		_complete_mission()
		return

	awaiting_selection = true
	_update_status("Conexión asegurada. Quedan %d enlaces por sellar." % (mst_edges.size() - edge_index))
	_highlight_current_edge()


func _handle_incorrect_node(node_key, expected_a, expected_b) -> void:
	if ui and ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "highlighted")
		call_deferred("_reset_highlighted_node", node_key)
	_update_status("Ese servidor no participa en la conexión actual (%s ↔ %s)." % [str(expected_a), str(expected_b)])


func _reset_highlighted_node(node_key) -> void:
	if not ui:
		return
	if connected_nodes.has(node_key):
		if ui.has_method("set_node_state"):
			ui.set_node_state(node_key, "visited")
		return
	if ui.has_method("set_node_state"):
		ui.set_node_state(node_key, "unvisited")
	_highlight_current_edge()


func _complete_mission() -> void:
	awaiting_selection = false
	is_running = false
	if step_button:
		step_button.disabled = true
	if continue_button:
		continue_button.visible = true
	_update_status(SUCCESS_STATUS_TEMPLATE % accumulated_cost)
	if result_label:
		result_label.text = "[center][b][color=green]%s[/color][/b][/center]\n\n" % VICTORY_MESSAGE
		result_label.text += "Algoritmo aplicado: %s\n" % algorithm
		result_label.text += "Enlaces reconstruidos (%d):\n" % mst_edges.size()
		for i in range(mst_edges.size()):
			var edge = mst_edges[i]
			var weight = float(edge.get("weight", 0.0))
			result_label.text += "%d. %s ↔ %s (costo: %.1f)\n" % [i + 1, str(edge.get("source")), str(edge.get("target")), weight]
		result_label.text += "\nCosto total invertido: %.1f\n" % accumulated_cost
		result_label.text += "Componentes atendidos: %d\n" % max(components, 1)
		result_label.text += "\n[center][color=yellow]Presiona 'Continuar' para volver al menú[/color][/center]"

	var result = {
		"status": "done",
		"edges": mst_edges.duplicate(true),
		"cost": accumulated_cost,
		"planned_cost": planned_cost,
		"algorithm": algorithm
	}
	complete(result)


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = "Estado: " + message


func _update_cost_display() -> void:
	if cost_label:
		if planned_cost <= 0.0:
			cost_label.text = "Costo acumulado: %.1f" % accumulated_cost
		else:
			cost_label.text = "Costo acumulado: %.1f / %.1f" % [accumulated_cost, planned_cost]


# ============================================================================
# UI SETUP AND EVENT HANDLING
# ============================================================================

func _connect_ui_signals() -> void:
	if kruskal_button:
		kruskal_button.pressed.connect(_on_kruskal_pressed)
		kruskal_button.button_pressed = true
	if prim_button:
		prim_button.pressed.connect(_on_prim_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if step_button:
		step_button.pressed.connect(_on_step_pressed)
		step_button.disabled = true
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.visible = false


func _subscribe_to_events() -> void:
	EventBus.mission_completed.connect(_on_mission_completed)


func _on_kruskal_pressed() -> void:
	set_algorithm("Kruskal")
	_update_status("Algoritmo Kruskal seleccionado. Ordena los enlaces por costo.")
	if prim_button:
		prim_button.button_pressed = false
	if kruskal_button:
		kruskal_button.button_pressed = true


func _on_prim_pressed() -> void:
	set_algorithm("Prim")
	_update_status("Algoritmo Prim seleccionado. Expande la red desde un nodo inicial.")
	if kruskal_button:
		kruskal_button.button_pressed = false
	if prim_button:
		prim_button.button_pressed = true


func _on_start_pressed() -> void:
	start()


func _on_step_pressed() -> void:
	step()


func _on_continue_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_mission_completed(completed_mission_id: String, success: bool, _result: Dictionary) -> void:
	if completed_mission_id != mission_id:
		return
	is_running = false
	awaiting_selection = false
	if start_button:
		start_button.disabled = true
	if step_button:
		step_button.disabled = true
	if kruskal_button:
		kruskal_button.disabled = true
	if prim_button:
		prim_button.disabled = true
	if continue_button:
		continue_button.visible = true
	if not success:
		_update_status("La reconstrucción no se completó. Intenta nuevamente.")