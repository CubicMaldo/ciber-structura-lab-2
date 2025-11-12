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
	GameManager.finish_mission(result)
	
	var success = result.get("status", "") == "done"
	EventBus.mission_completed.emit(mission_id, success, result)
