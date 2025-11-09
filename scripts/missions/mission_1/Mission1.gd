extends "res://scripts/missions/MissionController.gd"
## Mission 1 - Network Tracer (BFS / DFS)
## Example controller that wires the Graph model to the GraphDisplay and runs a step-by-step traversal.

var traversal_queue = []
var visited := {}

func _ready() -> void:
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
    # publish that mission logic started
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        if eb and eb.has_method("publish"):
            eb.publish("mission_logic_started", {"id": "Mission_1"})

func step() -> void:
    if traversal_queue.empty():
        complete({"status":"done"})
        return
    var current = traversal_queue.pop_front()
    visited[current] = true
    # Example: push neighbors into queue (Graph.gd must expose adjacency)
    if graph.has_method("get_neighbors"):
        for n in graph.get_neighbors(current):
            if not visited.has(n):
                traversal_queue.append(n)
    # update display (color change / animation hooks)
    if ui and ui.has_method("highlight_node"):
        ui.highlight_node(current)
    # publish node_visited event
    if Engine.has_singleton("EventBus"):
        var eb2 = Engine.get_singleton("EventBus")
        if eb2 and eb2.has_method("publish"):
            eb2.publish("node_visited", {"node": current})
