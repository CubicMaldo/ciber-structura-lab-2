extends "res://scripts/missions/MissionController.gd"
## Mission 1 - Network Tracer (BFS / DFS)
## El jugador recorre un grafo para encontrar el nodo raíz infectado.
## NOTA: El grafo se construye desde el nodo hijo "GraphBuilder" en la escena.

@export var algorithm: String = "BFS" # "BFS" or "DFS"

var traversal_queue: Array = []
var visited := {}
var found_clues: Array = []
var is_running := false
var last_current = null

var traversal_order: Array = []
var traversal_index: int = 0

# UI references
@onready var bfs_button: Button = %BFSButton
@onready var dfs_button: Button = %DFSButton
@onready var start_button: Button = %StartButton
@onready var step_button: Button = %StepButton
@onready var continue_button: Button = %ContinueButton
@onready var status_label: Label = %StatusLabel
@onready var clues_label: Label = %CluesLabel
@onready var result_label: RichTextLabel = %ResultLabel

func _ready() -> void:
	_connect_ui_signals()
	_subscribe_to_events()
	mission_id = "Mission_1"
	
	# Obtener el grafo desde el GraphBuilder hijo (desacoplado)
	var graph_builder = get_node_or_null("GraphBuilder") as GraphBuilder
	if graph_builder:
		graph = graph_builder.get_graph()
		print("Mission_1: Grafo cargado desde GraphBuilder con %d nodos" % graph.get_nodes().size())
	else:
		push_error("Mission_1: No se encontró nodo GraphBuilder.")
		# Crear grafo vacío para evitar crashes
		graph = Graph.new()
		return
	
	# Hook display if present in scene
	var display = get_node_or_null("GraphDisplay")
	if display:
		setup(graph, display)
		display.display_graph(graph)
	else:
		push_warning("Mission_1: No se encontró GraphDisplay para visualización")

func set_algorithm(alg: String) -> void:
	algorithm = alg

func start() -> void:
	# Initialize traversal depending on selected algorithm
	visited.clear()
	traversal_order.clear()
	traversal_index = 0
	var keys: Array = []
	if graph and graph.has_method("get_nodes"):
		keys = graph.get_nodes().keys()
	if keys.size() == 0:
		push_error("Mission_1: graph is empty")
		return
	var start_key = keys[0]
	# Compute traversal order using GraphAlgorithms
	var traversal_result: Dictionary = {}
	if algorithm == "DFS":
		traversal_result = GraphAlgorithms.dfs(graph, start_key)
	else:
		traversal_result = GraphAlgorithms.bfs(graph, start_key)
	traversal_order = traversal_result.get("visited", [])
	traversal_index = 0
	# Emit mission logic started
	EventBus.mission_logic_started.emit(mission_id)

func step() -> void:
	# Orchestrador: obtener siguiente clave y delegar responsabilidades
	var next_key = _get_next_key()
	if next_key == null:
		complete({"status":"done"})
		return
	
	if visited.has(next_key):
		return

	# Marcar previo como visitado si aplica
	if last_current != null and last_current != next_key:
		_mark_previous_visited(last_current)

	# Establecer el nodo actual (modifica last_current y UI)
	_set_current(next_key)

	# Marcar como visitado en el modelo
	visited[next_key] = true

	# Manejar la visita del vértice (emite eventos, descubre pistas, completa si encuentra root)
	var vertex = graph.get_vertex(next_key)
	if vertex:
		var finished = _handle_vertex_visit(vertex, next_key)
		if finished:
			return


# ============================================================================
# UI SETUP AND EVENT HANDLING
# ============================================================================

func _get_next_key() -> Variant:
	# Return next key from traversal_order and advance the index, or null if finished
	if traversal_index >= traversal_order.size():
		return null
	var k = traversal_order[traversal_index]
	traversal_index += 1
	return k


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


func _handle_vertex_visit(vertex, node_key) -> bool:
	# Emit node visited and process NetworkNodeMeta (clues, root detection).
	# Returns true if mission completed (root found).
	EventBus.node_visited.emit(vertex)

	var node_meta = vertex.meta as NetworkNodeMeta
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
			var result = {
				"status":"done",
				"root": node_key,
				"clues": found_clues,
				"restoration_code": "RC-42-ALPHA"
			}
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
	start()
	is_running = true
	if step_button:
		step_button.disabled = false
	if start_button:
		start_button.disabled = true
	_update_status("Búsqueda iniciada...")


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
		
		_update_status("¡MISIÓN COMPLETADA!")
		if result_label:
			result_label.text = "[center][b][color=green]¡ÉXITO![/color][/b][/center]\n\n"
			result_label.text += "[b]Nodo raíz encontrado:[/b] %s\n" % str(root)
			result_label.text += "[b]Código de restauración:[/b] %s\n\n" % code
			result_label.text += "[b]Pistas recopiladas:[/b]\n"
			for i in range(clues.size()):
				result_label.text += "%d. %s\n" % [i + 1, clues[i]]
			result_label.text += "\n[center][color=yellow]Presiona 'Continuar' para volver al menú[/color][/center]"
	else:
		_update_status("Búsqueda completada")
		if result_label:
			result_label.text = "[center][b]Búsqueda finalizada[/b][/center]\n\nRevisar los resultados."


func _update_status(message: String) -> void:
	if status_label:
		status_label.text = "Estado: " + message


func _update_clues_display() -> void:
	if clues_label:
		var clue_count = found_clues.size()
		if clue_count == 0:
			clues_label.text = "Pistas encontradas: 0"
		else:
			clues_label.text = "Pistas encontradas: %d\n" % clue_count
			for i in range(clue_count):
				clues_label.text += "• %s\n" % found_clues[i]
