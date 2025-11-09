extends Node
## Base mission controller
## Scenes representing missions should instance and extend this controller.

signal mission_completed(result)

var graph = null
var ui = null

func setup(graph_model, display_node) -> void:
    graph = graph_model
    ui = display_node

func start() -> void:
    ## Override in derived mission scripts to kick off the algorithm
    pass

func step() -> void:
    ## Override to advance algorithm one step
    pass

func complete(result := {}) -> void:
    emit_signal("mission_completed", result)
    if Engine.has_singleton("GameManager"):
        var gm = Engine.get_singleton("GameManager")
        if gm and gm.has_method("finish_mission"):
            gm.finish_mission(result)
    # publish mission_completed via EventBus as well
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        if eb and eb.has_method("publish"):
            eb.publish("mission_completed", result)
