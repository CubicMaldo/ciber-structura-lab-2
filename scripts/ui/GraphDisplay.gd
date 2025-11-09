extends Node2D
## GraphDisplay: visual bridge between Graph.gd (model) and node/edge views.
## Responsibilities:
## - Instantiate `NodeView` and `EdgeView` for each vertex/edge in a Graph
## - Provide methods to step animations and update colors/feedback
## Assumptions about Graph.gd API (adjust if different):
## - graph.get_vertices() -> Array of vertex data (id, meta)
## - graph.get_edges() -> Array of edge data (from_id, to_id, meta)

@export var node_scene: PackedScene
@export var edge_scene: PackedScene

var graph = null
var node_views := {}
var edge_views := []

## Display a Graph instance (model) on screen.
func display_graph(g) -> void:
    graph = g
    _clear()
    if not graph:
        return
    # spawn nodes
    if graph.has_method("get_vertices"):
        for v in graph.get_vertices():
            _spawn_node(v)
    # spawn edges
    if graph.has_method("get_edges"):
        for e in graph.get_edges():
            _spawn_edge(e)
    # Publish that a graph was displayed (payload can be the graph or summary)
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        if eb and eb.has_method("publish"):
            eb.publish("graph_displayed", {"nodes": graph.get_vertices().size() if graph.has_method("get_vertices") else 0, "edges": graph.get_edges().size() if graph.has_method("get_edges") else 0})

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
    node_views[v_data.id if typeof(v_data) == TYPE_DICTIONARY and v_data.has("id") else str(v_data)] = inst
    return inst

func _spawn_edge(e_data) -> Node:
    var inst: Node = null
    if edge_scene:
        inst = edge_scene.instantiate()
        add_child(inst)
        if inst.has_method("setup"):
            inst.setup(e_data)
    else:
        inst = Node2D.new()
        add_child(inst)
    edge_views.append(inst)
    return inst
