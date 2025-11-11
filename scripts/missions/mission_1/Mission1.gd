extends "res://scripts/missions/MissionController.gd"
## Mission 1 - Network Tracer (BFS / DFS)
## Example controller that wires the Graph model to the GraphDisplay and runs a step-by-step traversal.

var traversal_queue = []
var visited := {}

func _ready() -> void:
    mission_id = "Mission_1"
    # create/load a graph model
    var GraphClass = preload("res://scripts/utils/graphs/Graph.gd")
    graph = GraphClass.new()
    # TODO: populate graph nodes/edges or load from resource
    # Hook display if present in scene
    var display = get_node_or_null("GraphDisplay")
    if display:
        setup(graph, display)
        display.display_graph(graph)

func start() -> void:
    # Start BFS from first vertex if available
    if graph and graph.has_method("get_vertices"):
        var verts = graph.get_vertices()
        if verts.size() > 0:
            var start_v = verts[0]
            traversal_queue = [start_v]
            visited.clear()
    # Emit mission logic started signal with typed parameter
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        eb.mission_logic_started.emit("Mission_1")

func step() -> void:
    if traversal_queue.empty():
        complete({"status":"done"})
        return
    var current_key = traversal_queue.pop_front()
    visited[current_key] = true
    # Example: push neighbors into queue (Graph.gd must expose adjacency)
    if graph.has_method("get_neighbors"):
        for n in graph.get_neighbors(current_key):
            if not visited.has(n):
                traversal_queue.append(n)
    # update display (color change / animation hooks)
    if ui and ui.has_method("highlight_node"):
        ui.highlight_node(current_key)
    # Emit node visited signal with Vertex object
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        var vertex = graph.get_vertex(current_key)
        if vertex:
            eb.node_visited.emit(vertex)
