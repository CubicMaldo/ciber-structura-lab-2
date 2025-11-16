extends Node
## GameManager (autoload "GameManager")
## Responsibilities:
## - Hold global state (current mission, player progress)
## - Central flow: menu -> mission -> result
## NOTE: Register this script as an AutoLoad (singleton) named "GameManager" in Project Settings.

var current_mission: String = ""
var completed_missions: Array = []
var mission_order: Array = ["Mission_1", "Mission_2", "Mission_3", "Mission_4", "Mission_Final"]

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
	# If mission was successful, record it as completed
	var success = result.get("status", "") == "done"
	if success:
		if not completed_missions.has(current_mission):
			completed_missions.append(current_mission)
		# Optionally unlock the next mission in the sequence
		var idx = mission_order.find(current_mission)
		if idx >= 0 and idx + 1 < mission_order.size():
			var next_id = mission_order[idx + 1]
			if not completed_missions.has(next_id):
				# do nothing for now; UI will check unlock rules via is_mission_unlocked()
				pass
	# Optional: save progress here (local storage), later
func is_mission_unlocked(mission_id: String) -> bool:
	# Mission 1 is always unlocked. Other missions require the previous mission to be completed.
	if mission_id == "Mission_1":
		return true
	var idx = mission_order.find(mission_id)
	if idx == -1:
		return false
	# Check previous mission completion
	var prev_id = mission_order[idx - 1] if idx > 0 else ""
	if completed_missions.has(prev_id):
		return true
	return false

func is_mission_completed(mission_id: String) -> bool:
	return completed_missions.has(mission_id)
