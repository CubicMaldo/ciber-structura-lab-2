extends Node
## Base mission controller
## Scenes representing missions should instance and extend this controller.

signal mission_completed(result)

var graph = null
var ui = null
var mission_id: String = "Mission_Unknown"  ## Override this in derived classes

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
    # Emit mission completed signal via EventBus with typed parameters
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        var success = result.get("status", "") == "done"
        eb.mission_completed.emit(mission_id, success, result)
