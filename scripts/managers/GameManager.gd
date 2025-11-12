extends Node
## GameManager (autoload "GameManager")
## Responsibilities:
## - Hold global state (current mission, player progress)
## - Central flow: menu -> mission -> result
## NOTE: Register this script as an AutoLoad (singleton) named "GameManager" in Project Settings.

var current_mission: String = ""

func start_mission(mission_id: String) -> void:
	current_mission = mission_id
	# Use SceneManager autoload by fetching it from the root (avoid direct identifier)
	SceneManager.change_to_mission(mission_id)
	# Emit mission started signal with typed parameter
	EventBus.mission_started.emit(mission_id)

func finish_mission(result: Dictionary) -> void:
	# Record result and emit signal, but don't auto-transition
	# Let the mission scene handle the victory screen and transition
	print("Mission finished:", result)
	# Emit mission finished signal with typed parameters
	EventBus.mission_finished.emit(current_mission, result)
