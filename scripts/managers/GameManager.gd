extends Node

const PROGRESS_SAVE_PATH := "user://progress.save"

var current_mission: String = ""
var completed_missions: Array = []
var mission_order: Array = ["Mission_1", "Mission_2", "Mission_3", "Mission_4", "Mission_Final"]

func _ready() -> void:
	_load_progress()
	EventBus.mission_completed.connect(_on_eventbus_mission_completed)

func start_mission(mission_id: String) -> void:
	current_mission = mission_id
	# Preferir navegación desacoplada vía SceneManager (separa responsabilidades)
	SceneManager.change_to_mission(mission_id)
	EventBus.mission_started.emit(mission_id)

func finish_mission(result: Dictionary, finished_mission_id: String = "") -> void:
	# Registrar resultado y notificar; no forzar transición (la escena gestiona la UI)
	print("Mission finished:", result)
	# Usar parámetro explícito si está presente (evita ambigüedad)
	var used_mission := finished_mission_id if finished_mission_id != "" else current_mission
	EventBus.mission_finished.emit(used_mission, result)
	# Registrar finalización si fue exitosa
	var success = result.get("status", "") == "done"
	if success:
		_register_completion(used_mission)
		# Mantener la lógica de desbloqueo en el UI/consultas de is_mission_unlocked
		var idx = mission_order.find(used_mission)
		if idx >= 0 and idx + 1 < mission_order.size():
			var next_id = mission_order[idx + 1]
			if not completed_missions.has(next_id):
				pass
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

func _on_eventbus_mission_completed(mission_id: String, success: bool, _result: Dictionary) -> void:
	if success:
		_register_completion(mission_id)

func _register_completion(mission_id: String) -> void:
	if mission_id == "":
		return
	if completed_missions.has(mission_id):
		return
	completed_missions.append(mission_id)
	_save_progress()
	print("GameManager: misión completada -> %s" % mission_id)
	# Evita problemas de formateo con % al imprimir arrays
	print("GameManager: progreso actual %s" % str(completed_missions))

func _save_progress() -> void:
	var data = {
		"completed_missions": completed_missions.duplicate()
	}
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.flush()

func _load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_SAVE_PATH):
		return
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY:
		var stored = parsed.get("completed_missions", [])
		if typeof(stored) == TYPE_ARRAY:
			completed_missions = stored.duplicate()
