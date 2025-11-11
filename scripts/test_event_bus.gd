extends Node
## Test script para verificar que EventBus funciona con señales nativas tipadas
## Para usar: adjuntar a un nodo en una escena de prueba y ejecutar

func _ready() -> void:
	print("=== EventBus Typed Signals Test ===")
	
	# Get EventBus
	if not Engine.has_singleton("EventBus"):
		push_error("EventBus no está registrado como AutoLoad!")
		return
	
	var eb = Engine.get_singleton("EventBus")
	
	# Test 1: Verificar que las señales existen
	print("\n[Test 1] Verificando señales declaradas...")
	var expected_signals = [
		"mission_started",
		"mission_finished",
		"mission_selected",
		"mission_completed",
		"mission_logic_started",
		"mission_change_requested",
		"scene_changed",
		"graph_displayed",
		"node_visited",
		"edge_visited",
		"node_state_changed",
		"edge_state_changed",
		"node_added",
		"node_removed",
		"edge_added",
		"edge_removed"
	]
	
	for sig_name in expected_signals:
		if eb.has_signal(sig_name):
			print("  ✓ Signal '%s' exists" % sig_name)
		else:
			push_error("  ✗ Signal '%s' NOT FOUND!" % sig_name)
	
	# Test 2: Conectar y emitir señales tipadas
	print("\n[Test 2] Probando señales con parámetros tipados...")
	
	# Test mission_started (String)
	eb.mission_started.connect(_on_mission_started_test)
	eb.mission_started.emit("TestMission")
	eb.mission_started.disconnect(_on_mission_started_test)
	
	# Test mission_finished (String, Dictionary)
	eb.mission_finished.connect(_on_mission_finished_test)
	eb.mission_finished.emit("TestMission", {"score": 100, "time": 45.5})
	eb.mission_finished.disconnect(_on_mission_finished_test)
	
	# Test mission_completed (String, bool, Dictionary)
	eb.mission_completed.connect(_on_mission_completed_test)
	eb.mission_completed.emit("TestMission", true, {"nodes_visited": 10})
	eb.mission_completed.disconnect(_on_mission_completed_test)
	
	# Test scene_changed (String)
	eb.scene_changed.connect(_on_scene_changed_test)
	eb.scene_changed.emit("res://scenes/MainMenu.tscn")
	eb.scene_changed.disconnect(_on_scene_changed_test)
	
	print("\n[Test 3] Probando señales de grafo con objetos...")
	
	# Crear un grafo de prueba
	var GraphClass = preload("res://scripts/utils/graphs/Graph.gd")
	var test_graph = GraphClass.new()
	test_graph.add_node("A")
	test_graph.add_node("B")
	test_graph.connect_vertices("A", "B", 1.5)
	
	# Test graph_displayed (Graph)
	eb.graph_displayed.connect(_on_graph_displayed_test)
	eb.graph_displayed.emit(test_graph)
	eb.graph_displayed.disconnect(_on_graph_displayed_test)
	
	# Test node_visited (Vertex)
	var vertex_a = test_graph.get_vertex("A")
	if vertex_a:
		eb.node_visited.connect(_on_node_visited_test)
		eb.node_visited.emit(vertex_a)
		eb.node_visited.disconnect(_on_node_visited_test)
	
	# Test edge_visited (Edge)
	var edge_ab = test_graph.get_edge_resource("A", "B")
	if edge_ab:
		eb.edge_visited.connect(_on_edge_visited_test)
		eb.edge_visited.emit(edge_ab)
		eb.edge_visited.disconnect(_on_edge_visited_test)
	
	# Test node_state_changed (Vertex, String)
	if vertex_a:
		eb.node_state_changed.connect(_on_node_state_changed_test)
		eb.node_state_changed.emit(vertex_a, "visited")
		eb.node_state_changed.disconnect(_on_node_state_changed_test)
	
	print("\n=== Tests completados exitosamente ===")

# Handlers para señales de misiones
func _on_mission_started_test(mission_id: String) -> void:
	print("  ✓ mission_started recibida! mission_id: %s" % mission_id)

func _on_mission_finished_test(mission_id: String, result: Dictionary) -> void:
	print("  ✓ mission_finished recibida! mission_id: %s, result: %s" % [mission_id, result])

func _on_mission_completed_test(mission_id: String, success: bool, data: Dictionary) -> void:
	print("  ✓ mission_completed recibida! mission_id: %s, success: %s, data: %s" % [mission_id, success, data])

func _on_scene_changed_test(scene_path: String) -> void:
	print("  ✓ scene_changed recibida! scene_path: %s" % scene_path)

# Handlers para señales de grafo (objetos tipados)
func _on_graph_displayed_test(graph: Graph) -> void:
	print("  ✓ graph_displayed recibida! Graph con %d nodos" % graph.get_node_count())

func _on_node_visited_test(vertex: Vertex) -> void:
	print("  ✓ node_visited recibida! Vertex key: %s" % vertex.key)

func _on_edge_visited_test(edge: Edge) -> void:
	print("  ✓ edge_visited recibida! Edge weight: %s" % edge.weight)

func _on_node_state_changed_test(vertex: Vertex, state: String) -> void:
	print("  ✓ node_state_changed recibida! Vertex key: %s, state: %s" % [vertex.key, state])
