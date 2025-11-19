extends Node
## AchievementManager (autoload "AchievementManager")
## Registra definiciones de logros/desafíos y evalúa condiciones especiales
## cuando las misiones reportan sus métricas.

signal achievement_unlocked(id: String, data: Dictionary)

const SAVE_PATH := "user://achievements.json"
const DEFAULT_MISSION_SET := ["Mission_1", "Mission_2", "Mission_3", "Mission_4", "Mission_Final"]

var _definitions: Dictionary = {}
var _state: Dictionary = {}

func _ready() -> void:
	_register_default_definitions()
	_load_progress()
	_ensure_state_entries()
	EventBus.mission_completed.connect(_on_mission_completed)


func get_achievement_list() -> Array:
	var items: Array = []
	for id in _definitions.keys():
		items.append(_compose_entry(id, _definitions[id]))
	return items


func get_achievements_for_mission(mission_id: String) -> Array:
	var items: Array = []
	for id in _definitions.keys():
		var def: Dictionary = _definitions[id]
		if def.get("mission_id", "") != mission_id:
			continue
		items.append(_compose_entry(id, def))
	items.sort_custom(Callable(self, "_sort_entries"))
	return items


func has_unlocked(id: String) -> bool:
	return _state.get(id, {}).get("unlocked", false)


func get_achievement_definition(id: String) -> Dictionary:
	return _definitions.get(id, {})


func reset_progress() -> void:
	_state.clear()
	_ensure_state_entries()
	_save_progress()


func _on_mission_completed(mission_id: String, success: bool, result: Dictionary) -> void:
	var progress_changed := false
	var unlocked_any := false
	for id in _definitions.keys():
		var def: Dictionary = _definitions[id]
		if def.get("type", "") == "all_completed":
			var new_value := _get_completed_mission_count()
			if _set_progress_value(id, new_value, def):
				progress_changed = true
			if not has_unlocked(id) and _definition_matches(def, mission_id, result, success) and _is_goal_reached(id, def):
				unlocked_any = _unlock(id, mission_id, result) or unlocked_any
			continue
		if not success:
			continue
		var target_mission: String = def.get("mission_id", "")
		if target_mission != "" and target_mission != mission_id:
			continue
		if _definition_matches(def, mission_id, result, success):
			if _add_progress(id, 1, def):
				progress_changed = true
			if not has_unlocked(id) and _is_goal_reached(id, def):
				unlocked_any = _unlock(id, mission_id, result) or unlocked_any
	if progress_changed or unlocked_any:
		_save_progress()


func _register_default_definitions() -> void:
	_definitions.clear()
	_definitions = {
		"mission_1_bfs_master": {
			"title": "Analista BFS",
			"description": "Completa la misión rastreando con BFS.",
			"requirement": "Finaliza usando el botón BFS.",
			"mission_id": "Mission_1",
			"type": "algorithm",
			"value": "BFS",
			"goal": 1,
			"category": "misiones"
		},
		"mission_1_dfs_master": {
			"title": "Cazador DFS",
			"description": "Demuestra control con un rastreo DFS exitoso.",
			"requirement": "Completa la misión usando DFS.",
			"mission_id": "Mission_1",
			"type": "algorithm",
			"value": "DFS",
			"goal": 1,
			"category": "misiones"
		},
		"mission_2_pathfinder": {
			"title": "Cartógrafo",
			"description": "Protege la ruta crítica de Mission 2 en múltiples ocasiones.",
			"requirement": "Completa la misión tres veces.",
			"mission_id": "Mission_2",
			"type": "completion",
			"goal": 3,
			"category": "misiones"
		},
		"mission_2_optimal_route": {
			"title": "Ruta Óptima",
			"description": "Traza exactamente el camino de menor costo.",
			"requirement": "Mantén la distancia acumulada igual al costo óptimo.",
			"mission_id": "Mission_2",
			"type": "distance_match",
			"tolerance": 0.05,
			"goal": 1,
			"category": "precisión"
		},
		"mission_3_kruskal_engineer": {
			"title": "Arquitecto Kruskal",
			"description": "Reconstruye la red aplicando Kruskal.",
			"mission_id": "Mission_3",
			"type": "algorithm",
			"value": "Kruskal",
			"goal": 1,
			"category": "misiones"
		},
		"mission_3_prim_engineer": {
			"title": "Arquitecto Prim",
			"description": "Reconstruye la red aplicando Prim.",
			"mission_id": "Mission_3",
			"type": "algorithm",
			"value": "Prim",
			"goal": 1,
			"category": "misiones"
		},
		"mission_3_budget_guard": {
			"title": "Auditor de Costos",
			"description": "Mantén la reconstrucción dentro del costo planificado.",
			"requirement": "No excedas el costo del MST calculado.",
			"mission_id": "Mission_3",
			"type": "cost_match",
			"tolerance": 0.1,
			"goal": 1,
			"category": "precisión"
		},
		"mission_4_ford_specialist": {
			"title": "Especialista Ford-Fulkerson",
			"description": "Resuelve el flujo usando Ford-Fulkerson.",
			"mission_id": "Mission_4",
			"type": "algorithm",
			"value": "Ford-Fulkerson",
			"goal": 1,
			"category": "misiones"
		},
		"mission_4_edmonds_specialist": {
			"title": "Especialista Edmonds-Karp",
			"description": "Resuelve el flujo usando Edmonds-Karp.",
			"mission_id": "Mission_4",
			"type": "algorithm",
			"value": "Edmonds-Karp",
			"goal": 1,
			"category": "misiones"
		},
		"mission_4_flow_guard": {
			"title": "Guardían del Caudal",
			"description": "Establece un flujo de al menos 12 unidades.",
			"mission_id": "Mission_4",
			"type": "flow_threshold",
			"threshold": 12,
			"goal": 1,
			"category": "precisión"
		},
		"mission_final_perfect": {
			"title": "Operador Impecable",
			"description": "Termina 'Mission Final' sin registrar errores.",
			"requirement": "Completa todas las fases sin errores registrados.",
			"mission_id": "Mission_Final",
			"type": "no_mistakes",
			"threshold": 0,
			"goal": 1,
			"category": "misiones"
		},
		"mission_final_speedrunner": {
			"title": "Rutinas Relámpago",
			"description": "Completa 'Mission Final' usando 30 movimientos o menos.",
			"requirement": "Mantén el contador global en 30 o menos.",
			"mission_id": "Mission_Final",
			"type": "move_limit",
			"threshold": 30,
			"goal": 1,
			"category": "misiones"
		},
		"mission_final_stage_recon": {
			"title": "Recon Maestro",
			"description": "Resuelve la fase de Reconocimiento sin errores.",
			"mission_id": "Mission_Final",
			"type": "stage_perfect",
			"stage_id": "recon",
			"threshold": 0,
			"goal": 1,
			"category": "fases"
		},
		"mission_final_stage_flow": {
			"title": "Flujo impecable",
			"description": "Completa la fase de flujo sin errores.",
			"mission_id": "Mission_Final",
			"type": "stage_perfect",
			"stage_id": "flow",
			"threshold": 0,
			"goal": 1,
			"category": "fases"
		},
		"mission_final_elite": {
			"title": "Operador Constante",
			"description": "Domina la misión final en dos ocasiones.",
			"requirement": "Completa Mission Final dos veces.",
			"mission_id": "Mission_Final",
			"type": "completion",
			"goal": 2,
			"category": "progresion"
		},
		"campaign_complete": {
			"title": "Guardia de la Red",
			"description": "Completa todas las misiones principales.",
			"requirement": "Termina las %d misiones de la campaña." % DEFAULT_MISSION_SET.size(),
			"mission_id": "",
			"type": "all_completed",
			"goal": DEFAULT_MISSION_SET.size(),
			"category": "progresion"
		}
	}


func _definition_matches(def: Dictionary, _mission_id: String, result: Dictionary, success: bool) -> bool:
	var def_type: String = str(def.get("type", ""))
	match def_type:
		"completion":
			return success
		"algorithm":
			if not success:
				return false
			var expected := str(def.get("value", "")).to_lower()
			var used := str(result.get("algorithm", "")).to_lower()
			return expected != "" and expected == used
		"no_mistakes":
			if not success:
				return false
			var mistakes := int(result.get("mistakes", result.get("errors", 9999)))
			return mistakes <= int(def.get("threshold", 0))
		"move_limit":
			if not success:
				return false
			var moves := int(result.get("moves", result.get("actions", 9999)))
			return moves <= int(def.get("threshold", 0))
		"distance_match":
			if not success:
				return false
			var actual := float(result.get("distance", result.get("accumulated_distance", 0.0)))
			var optimal := float(result.get("optimal_distance", actual))
			var tolerance := float(def.get("tolerance", 0.1))
			return abs(actual - optimal) <= tolerance
		"cost_match":
			if not success:
				return false
			var cost := float(result.get("cost", 0.0))
			var planned := float(result.get("planned_cost", cost))
			var tolerance := float(def.get("tolerance", 0.05))
			return cost <= planned + tolerance
		"flow_threshold":
			if not success:
				return false
			var max_flow := int(result.get("max_flow", 0))
			return max_flow >= int(def.get("threshold", 0))
		"stage_perfect":
			if not success:
				return false
			var stage_id := str(def.get("stage_id", ""))
			if stage_id == "":
				return false
			var stage_mistakes: Dictionary = result.get("stage_mistakes", {})
			var mistakes := int(stage_mistakes.get(stage_id, 999))
			return mistakes <= int(def.get("threshold", 0))
		"all_completed":
			return _all_missions_completed()
		_:
			return false


func _all_missions_completed() -> bool:
	var completed: Array = GameManager.completed_missions if GameManager else []
	for mission_id in DEFAULT_MISSION_SET:
		if not completed.has(mission_id):
			return false
	return true


func _unlock(id: String, mission_id: String, result: Dictionary) -> bool:
	var entry: Dictionary = _state.get(id, {
		"unlocked": false,
		"timestamp": 0,
		"progress": 0,
		"meta": {}
	})
	entry["unlocked"] = true
	entry["timestamp"] = Time.get_unix_time_from_system()
	entry["meta"] = {
		"mission_id": mission_id,
		"snapshot": result.duplicate(true)
	}
	var goal := int(_definitions.get(id, {}).get("goal", 1))
	entry["progress"] = max(goal, int(entry.get("progress", 0)))
	_state[id] = entry
	achievement_unlocked.emit(id, entry)
	print("Achievement unlocked:", id)
	return true


func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var raw := file.get_as_text()
	file.close()
	if raw.is_empty():
		return
	var data = JSON.parse_string(raw)
	if typeof(data) == TYPE_DICTIONARY:
		_state = data


func _ensure_state_entries() -> void:
	for id in _definitions.keys():
		if not _state.has(id):
			_state[id] = {
				"unlocked": false,
				"timestamp": 0,
				"progress": 0,
				"meta": {}
			}
		else:
			var entry: Dictionary = _state[id]
			if not entry.has("progress"):
				entry["progress"] = 0
			_state[id] = entry


func _compose_entry(id: String, def: Dictionary) -> Dictionary:
	var entry: Dictionary = _state.get(id, {})
	return {
		"id": id,
		"title": def.get("title", id),
		"description": def.get("description", ""),
		"category": def.get("category", "general"),
		"mission_id": def.get("mission_id", ""),
		"requirement": def.get("requirement", def.get("description", "")),
		"goal": int(def.get("goal", 1)),
		"unlocked": entry.get("unlocked", false),
		"timestamp": entry.get("timestamp", 0),
		"meta": entry.get("meta", {}),
		"progress": int(entry.get("progress", 0))
	}


func _add_progress(id: String, amount: int, def: Dictionary) -> bool:
	if amount <= 0:
		return false
	var entry: Dictionary = _state.get(id, {})
	var goal: int = max(1, int(def.get("goal", 1)))
	var current := int(entry.get("progress", 0))
	var next: int = clamp(current + amount, 0, goal)
	if next == current:
		return false
	entry["progress"] = next
	_state[id] = entry
	return true


func _set_progress_value(id: String, value: int, def: Dictionary) -> bool:
	var entry: Dictionary = _state.get(id, {})
	var goal: int = max(1, int(def.get("goal", 1)))
	var clamped: int = clamp(value, 0, goal)
	if int(entry.get("progress", 0)) == clamped:
		return false
	entry["progress"] = clamped
	_state[id] = entry
	return true


func _is_goal_reached(id: String, def: Dictionary) -> bool:
	var goal: int = max(1, int(def.get("goal", 1)))
	var progress := int(_state.get(id, {}).get("progress", 0))
	return progress >= goal


func _get_completed_mission_count() -> int:
	if not GameManager:
		return 0
	return GameManager.completed_missions.size()


func _sort_entries(a: Dictionary, b: Dictionary) -> bool:
	var unlocked_a: bool = bool(a.get("unlocked", false))
	var unlocked_b: bool = bool(b.get("unlocked", false))
	if unlocked_a == unlocked_b:
		return str(a.get("title", "")) < str(b.get("title", ""))
	return not unlocked_a and unlocked_b


func _save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_state, "\t"))
	file.close()