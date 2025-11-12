extends Node2D
## GraphDisplay: Modular visual bridge between Graph.gd (model) and node/edge views
## Uses composition pattern - coordinates GraphLayout, NodeView, and EdgeView components
## Responsibilities:
## - Instantiate NodeView and EdgeView for each vertex/edge
## - Apply layout algorithms to position nodes
## - Provide high-level methods for visual state updates
## - React to EventBus signals for visualization feedback

@export var node_scene: PackedScene
@export var edge_scene: PackedScene
@export_enum("circular", "grid", "force_directed", "hierarchical") var layout_type: String = "circular"
@export var layout_radius: float = 250.0
@export var layout_spacing: float = 150.0

var graph = null
var node_views := {}
var edge_views := []
var layout_component: GraphLayout = null


## Display a Graph instance (model) on screen with automatic layout
func display_graph(g) -> void:
	graph = g
	_clear()
	if not graph:
		return
	
	# Step 1: Spawn nodes
	var node_keys: Array = []
	if graph.has_method("get_nodes"):
		var nodes_dict: Dictionary = graph.get_nodes()
		for key in nodes_dict.keys():
			node_keys.append(key)
			var meta = nodes_dict[key]
			var node_data := {"id": key, "meta": meta}
			_spawn_node(node_data)
	
	# Step 2: Apply layout algorithm to position nodes
	_apply_layout(node_keys)
	
	# Step 3: Spawn edges and link to nodes
	if graph.has_method("get_edges"):
		for e in graph.get_edges():
			_spawn_edge(e)
	
	# Step 4: Emit graph displayed signal
	EventBus.graph_displayed.emit(graph)


## Update the visual state of a specific node by key
func set_node_state(node_key, state: String) -> void:
	if node_views.has(node_key):
		var node_view = node_views[node_key]
		if node_view and node_view.has_method("set_state"):
			node_view.set_state(state)


## Show a clue on a specific node
func show_node_clue(node_key, clue_text: String) -> void:
	if node_views.has(node_key):
		var node_view = node_views[node_key]
		if node_view and node_view.has_method("show_clue"):
			node_view.show_clue(clue_text)


## Highlight a node (legacy method for mission controllers)
func highlight_node(node_key) -> void:
	set_node_state(node_key, "current")


func _clear() -> void:
	for nv in node_views.values():
		if is_instance_valid(nv):
			nv.queue_free()
	node_views.clear()
	for ev in edge_views:
		if is_instance_valid(ev):
			ev.queue_free()
	edge_views.clear()


func _spawn_node(v_data) -> Node:
	var inst: Node = null
	if node_scene:
		inst = node_scene.instantiate()
		add_child(inst)
		if inst.has_method("setup"):
			inst.setup(v_data)
	else:
		inst = Node2D.new()
		add_child(inst)
	
	var key = ""
	if typeof(v_data) == TYPE_DICTIONARY and v_data.has("id"):
		key = v_data.id
	else:
		key = str(v_data)
	node_views[key] = inst
	return inst


func _spawn_edge(e_data) -> Node:
	var inst: Node = null
	if edge_scene:
		inst = edge_scene.instantiate()
		add_child(inst)
		if inst.has_method("setup"):
			inst.setup(e_data)
		
		# Link edge to node views for dynamic positioning
		var source_key = e_data.get("source", e_data.get("from"))
		var target_key = e_data.get("target", e_data.get("to"))
		
		if node_views.has(source_key) and node_views.has(target_key):
			var source_node = node_views[source_key]
			var target_node = node_views[target_key]
			if inst.has_method("set_node_references"):
				inst.set_node_references(source_node, target_node)
	else:
		inst = Node2D.new()
		add_child(inst)
	
	edge_views.append(inst)
	return inst


func _apply_layout(node_keys: Array) -> void:
	if node_keys.size() == 0:
		return
	var positions := {}

	# ensure we have a layout component instance (composed component)
	if layout_component == null:
		# instantiate and attach so it will appear in the scene tree (optional)
		layout_component = GraphLayout.new()
	
	match layout_type:
		"circular":
			var pos_array = layout_component.circular_layout(node_keys.size(), layout_radius, global_position)
			for i in range(node_keys.size()):
				positions[node_keys[i]] = pos_array[i]
		
		"grid":
			var pos_array = layout_component.grid_layout(node_keys.size(), 4, layout_spacing, global_position)
			for i in range(node_keys.size()):
				positions[node_keys[i]] = pos_array[i]
		
		"force_directed":
			var edges = graph.get_edges() if graph.has_method("get_edges") else []
			positions = layout_component.force_directed_layout(
				node_keys, edges, 50, 5000.0, 0.1, 0.9, global_position
			)
		
		"hierarchical":
			var root_key = node_keys[0] if node_keys.size() > 0 else null
			if root_key:
				var edges = graph.get_edges() if graph.has_method("get_edges") else []
				positions = layout_component.hierarchical_layout(
					node_keys, edges, root_key, 120.0, 100.0, global_position
				)
	
	# Apply positions to node views
	for key in positions.keys():
		if node_views.has(key):
			node_views[key].global_position = positions[key]
