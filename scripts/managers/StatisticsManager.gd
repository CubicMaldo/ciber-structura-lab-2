extends Node
## StatisticsManager - Gestiona estadísticas globales acumulativas del jugador

const SAVE_FILE := "user://player_statistics.save"

## Estadísticas acumulativas
var total_play_time: float = 0.0  # En segundos
var total_nodes_visited: int = 0
var total_edges_traversed: int = 0
var total_missions_started: int = 0
var total_missions_completed: int = 0
var total_missions_failed: int = 0
var total_mistakes: int = 0
var total_resources_used: int = 0
var total_algorithms_executed: int = 0

## Estadísticas por algoritmo
var algorithm_usage: Dictionary = {
	"BFS": 0,
	"DFS": 0,
	"Dijkstra": 0,
	"Kruskal": 0,
	"Prim": 0,
	"Ford-Fulkerson": 0,
	"Max-Flow": 0,
	"Min-Cut": 0
}

## Sesión actual
var session_start_time: float = 0.0
var session_play_time: float = 0.0

## Logros acumulativos desbloqueados
var cumulative_achievements: Dictionary = {
	"nodes_100": false,
	"nodes_500": false,
	"nodes_1000": false,
	"nodes_5000": false,
	"missions_10": false,
	"missions_25": false,
	"missions_50": false,
	"missions_100": false,
	"playtime_1h": false,
	"playtime_5h": false,
	"playtime_10h": false,
	"playtime_25h": false,
	"perfect_streak_3": false,
	"perfect_streak_5": false,
	"perfect_streak_10": false,
	"all_algorithms": false,
	"master_efficiency": false
}

var perfect_streak: int = 0
var current_streak: int = 0

signal statistic_updated(stat_name: String, new_value)
signal cumulative_achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal milestone_reached(milestone_type: String, value: int)

func _ready() -> void:
	load_statistics()
	session_start_time = Time.get_unix_time_from_system()
	
	# Conectar a eventos del juego
	EventBus.mission_started.connect(_on_mission_started)
	EventBus.mission_completed.connect(_on_mission_completed)
	EventBus.node_visited.connect(_on_node_visited)
	EventBus.edge_visited.connect(_on_edge_visited)
	EventBus.mission_score_saved.connect(_on_mission_score_saved)
	EventBus.algorithm_executed.connect(_on_algorithm_executed)
	EventBus.mistake_made.connect(_on_mistake_made)
	EventBus.resource_used.connect(_on_resource_used)

func _process(delta: float) -> void:
	# Actualizar tiempo de juego de la sesión
	session_play_time += delta
	total_play_time += delta
	
	# Revisar logros de tiempo cada 60 segundos
	if int(total_play_time) % 60 == 0:
		_check_playtime_achievements()

## Incrementar nodos visitados
func add_nodes_visited(count: int = 1) -> void:
	total_nodes_visited += count
	statistic_updated.emit("total_nodes_visited", total_nodes_visited)
	_check_nodes_achievements()

## Incrementar aristas recorridas
func add_edges_traversed(count: int = 1) -> void:
	total_edges_traversed += count
	statistic_updated.emit("total_edges_traversed", total_edges_traversed)

## Incrementar errores
func add_mistake() -> void:
	total_mistakes += 1
	statistic_updated.emit("total_mistakes", total_mistakes)

## Incrementar recursos usados
func add_resource_used(count: int = 1) -> void:
	total_resources_used += count
	statistic_updated.emit("total_resources_used", total_resources_used)

## Registrar uso de algoritmo
func register_algorithm_usage(algorithm: String) -> void:
	if algorithm_usage.has(algorithm):
		algorithm_usage[algorithm] += 1
		total_algorithms_executed += 1
		statistic_updated.emit("algorithm_usage", algorithm_usage)
		_check_all_algorithms_achievement()

## Obtener estadísticas como diccionario
func get_statistics() -> Dictionary:
	return {
		"total_play_time": total_play_time,
		"session_play_time": session_play_time,
		"total_nodes_visited": total_nodes_visited,
		"total_edges_traversed": total_edges_traversed,
		"total_missions_started": total_missions_started,
		"total_missions_completed": total_missions_completed,
		"total_missions_failed": total_missions_failed,
		"total_mistakes": total_mistakes,
		"total_resources_used": total_resources_used,
		"total_algorithms_executed": total_algorithms_executed,
		"algorithm_usage": algorithm_usage.duplicate(),
		"perfect_streak": perfect_streak,
		"current_streak": current_streak,
		"cumulative_achievements": cumulative_achievements.duplicate()
	}

## Obtener tasa de éxito
func get_success_rate() -> float:
	if total_missions_started == 0:
		return 0.0
	return (float(total_missions_completed) / float(total_missions_started)) * 100.0

## Obtener eficiencia promedio
func get_average_efficiency() -> float:
	if total_nodes_visited == 0:
		return 100.0
	# Menos errores = más eficiencia
	var error_rate = float(total_mistakes) / float(total_nodes_visited)
	return max(0.0, (1.0 - error_rate) * 100.0)

## Obtener algoritmo más usado
func get_most_used_algorithm() -> String:
	var max_usage = 0
	var most_used = "Ninguno"
	
	for algo in algorithm_usage.keys():
		if algorithm_usage[algo] > max_usage:
			max_usage = algorithm_usage[algo]
			most_used = algo
	
	return most_used if max_usage > 0 else "Ninguno"

## Verificar logros de nodos visitados
func _check_nodes_achievements() -> void:
	if total_nodes_visited >= 100 and not cumulative_achievements["nodes_100"]:
		_unlock_cumulative_achievement("nodes_100", {
			"title": "Explorador Novato",
			"description": "Visita 100 nodos en total",
			"icon": "🗺️"
		})
		milestone_reached.emit("nodes", 100)
	
	if total_nodes_visited >= 500 and not cumulative_achievements["nodes_500"]:
		_unlock_cumulative_achievement("nodes_500", {
			"title": "Cartógrafo",
			"description": "Visita 500 nodos en total",
			"icon": "🧭"
		})
		milestone_reached.emit("nodes", 500)
	
	if total_nodes_visited >= 1000 and not cumulative_achievements["nodes_1000"]:
		_unlock_cumulative_achievement("nodes_1000", {
			"title": "Maestro Explorador",
			"description": "Visita 1000 nodos en total",
			"icon": "🌟"
		})
		milestone_reached.emit("nodes", 1000)
	
	if total_nodes_visited >= 5000 and not cumulative_achievements["nodes_5000"]:
		_unlock_cumulative_achievement("nodes_5000", {
			"title": "Leyenda de las Redes",
			"description": "Visita 5000 nodos en total",
			"icon": "👑"
		})
		milestone_reached.emit("nodes", 5000)

## Verificar logros de misiones completadas
func _check_missions_achievements() -> void:
	if total_missions_completed >= 10 and not cumulative_achievements["missions_10"]:
		_unlock_cumulative_achievement("missions_10", {
			"title": "Veterano",
			"description": "Completa 10 misiones en total",
			"icon": "🎖️"
		})
		milestone_reached.emit("missions", 10)
	
	if total_missions_completed >= 25 and not cumulative_achievements["missions_25"]:
		_unlock_cumulative_achievement("missions_25", {
			"title": "Profesional",
			"description": "Completa 25 misiones en total",
			"icon": "🏅"
		})
		milestone_reached.emit("missions", 25)
	
	if total_missions_completed >= 50 and not cumulative_achievements["missions_50"]:
		_unlock_cumulative_achievement("missions_50", {
			"title": "Experto",
			"description": "Completa 50 misiones en total",
			"icon": "🌟"
		})
		milestone_reached.emit("missions", 50)
	
	if total_missions_completed >= 100 and not cumulative_achievements["missions_100"]:
		_unlock_cumulative_achievement("missions_100", {
			"title": "Campeón",
			"description": "Completa 100 misiones en total",
			"icon": "🏆"
		})
		milestone_reached.emit("missions", 100)

## Verificar logros de tiempo de juego
func _check_playtime_achievements() -> void:
	var hours = total_play_time / 3600.0
	
	if hours >= 1.0 and not cumulative_achievements["playtime_1h"]:
		_unlock_cumulative_achievement("playtime_1h", {
			"title": "Dedicado",
			"description": "Juega durante 1 hora en total",
			"icon": "⏱️"
		})
	
	if hours >= 5.0 and not cumulative_achievements["playtime_5h"]:
		_unlock_cumulative_achievement("playtime_5h", {
			"title": "Comprometido",
			"description": "Juega durante 5 horas en total",
			"icon": "⏰"
		})
	
	if hours >= 10.0 and not cumulative_achievements["playtime_10h"]:
		_unlock_cumulative_achievement("playtime_10h", {
			"title": "Apasionado",
			"description": "Juega durante 10 horas en total",
			"icon": "🔥"
		})
	
	if hours >= 25.0 and not cumulative_achievements["playtime_25h"]:
		_unlock_cumulative_achievement("playtime_25h", {
			"title": "Maestro del Tiempo",
			"description": "Juega durante 25 horas en total",
			"icon": "⌚"
		})

## Verificar logros de rachas perfectas
func _check_streak_achievements() -> void:
	if perfect_streak >= 3 and not cumulative_achievements["perfect_streak_3"]:
		_unlock_cumulative_achievement("perfect_streak_3", {
			"title": "En Racha",
			"description": "Consigue 3 puntuaciones perfectas seguidas",
			"icon": "🔥"
		})
	
	if perfect_streak >= 5 and not cumulative_achievements["perfect_streak_5"]:
		_unlock_cumulative_achievement("perfect_streak_5", {
			"title": "Imparable",
			"description": "Consigue 5 puntuaciones perfectas seguidas",
			"icon": "⚡"
		})
	
	if perfect_streak >= 10 and not cumulative_achievements["perfect_streak_10"]:
		_unlock_cumulative_achievement("perfect_streak_10", {
			"title": "Perfección Absoluta",
			"description": "Consigue 10 puntuaciones perfectas seguidas",
			"icon": "💎"
		})

func _check_all_algorithms_achievement() -> void:
	var all_used = true
	for algo in ["BFS", "DFS", "Dijkstra", "Kruskal", "Prim", "Ford-Fulkerson"]:
		if algorithm_usage.get(algo, 0) == 0:
			all_used = false
			break
	
	if all_used and not cumulative_achievements.get("all_algorithms", false):
		_unlock_cumulative_achievement("all_algorithms", {
			"title": "Políglota de Algoritmos",
			"description": "Ejecuta todos los algoritmos disponibles",
			"icon": "🧠"
		})

## Desbloquear logro acumulativo
func _unlock_cumulative_achievement(achievement_id: String, achievement_data: Dictionary) -> void:
	cumulative_achievements[achievement_id] = true
	cumulative_achievement_unlocked.emit(achievement_id, achievement_data)
	
	# Notificar al jugador
	if NotificationManager:
		NotificationManager.show_achievement_notification(achievement_id, achievement_data)
	
	# Marcar como desbloqueado en AchievementManager también
	if AchievementManager and AchievementManager.has_method("unlock_achievement"):
		AchievementManager.unlock_achievement(achievement_id, achievement_data)
	
	_save_to_disk()

## Eventos del juego
func _on_mission_started(_mission_id: String) -> void:
	total_missions_started += 1
	statistic_updated.emit("total_missions_started", total_missions_started)
	_save_to_disk()

func _on_mission_completed(_mission_id: String, success: bool, _data: Dictionary) -> void:
	if success:
		total_missions_completed += 1
		current_streak += 1
		statistic_updated.emit("total_missions_completed", total_missions_completed)
		_check_missions_achievements()
	else:
		total_missions_failed += 1
		current_streak = 0
		statistic_updated.emit("total_missions_failed", total_missions_failed)
	
	_save_to_disk()

func _on_node_visited(_vertex) -> void:
	add_nodes_visited(1)

func _on_edge_visited(_edge) -> void:
	add_edges_traversed(1)

func _on_mission_score_saved(_mission_id: String, total_score: int, _rank: String, _is_new_best: bool) -> void:
	# Actualizar racha perfecta si aplica
	var score_manager = MissionScoreManager
	if score_manager:
		var best = score_manager.get_best_score(_mission_id)
		if best and best.perfect:
			perfect_streak += 1
			if perfect_streak > current_streak:
				current_streak = perfect_streak
			_check_streak_achievements()
		else:
			perfect_streak = 0
		
		# Verificar logro de eficiencia maestra (score >= 95%)
		if total_score >= 950 and not cumulative_achievements.get("master_efficiency", false):
			_unlock_cumulative_achievement("master_efficiency", {
				"title": "Maestría Absoluta",
				"description": "Obtén una puntuación mayor al 95% en cualquier misión",
				"icon": "🎯"
			})
	
	_save_to_disk()

func _on_algorithm_executed(algorithm_name: String, _mission_id: String) -> void:
	total_algorithms_executed += 1
	if algorithm_usage.has(algorithm_name):
		algorithm_usage[algorithm_name] += 1
	else:
		algorithm_usage[algorithm_name] = 1
	
	statistic_updated.emit("total_algorithms_executed", total_algorithms_executed)
	_check_all_algorithms_achievement()
	_save_to_disk()

func _on_mistake_made(_mission_id: String) -> void:
	add_mistake()
	_save_to_disk()

func _on_resource_used(_resource_type: String, _mission_id: String) -> void:
	add_resource_used(1)
	_save_to_disk()

## Guardar estadísticas en disco
func _save_to_disk() -> void:
	var save_data = {
		"version": 1,
		"total_play_time": total_play_time,
		"total_nodes_visited": total_nodes_visited,
		"total_edges_traversed": total_edges_traversed,
		"total_missions_started": total_missions_started,
		"total_missions_completed": total_missions_completed,
		"total_missions_failed": total_missions_failed,
		"total_mistakes": total_mistakes,
		"total_resources_used": total_resources_used,
		"total_algorithms_executed": total_algorithms_executed,
		"algorithm_usage": algorithm_usage.duplicate(),
		"perfect_streak": perfect_streak,
		"cumulative_achievements": cumulative_achievements.duplicate()
	}
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

## Cargar estadísticas desde disco
func load_statistics() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return
	
	var save_data = file.get_var()
	file.close()
	
	if typeof(save_data) != TYPE_DICTIONARY:
		return
	
	total_play_time = save_data.get("total_play_time", 0.0)
	total_nodes_visited = save_data.get("total_nodes_visited", 0)
	total_edges_traversed = save_data.get("total_edges_traversed", 0)
	total_missions_started = save_data.get("total_missions_started", 0)
	total_missions_completed = save_data.get("total_missions_completed", 0)
	total_missions_failed = save_data.get("total_missions_failed", 0)
	total_mistakes = save_data.get("total_mistakes", 0)
	total_resources_used = save_data.get("total_resources_used", 0)
	total_algorithms_executed = save_data.get("total_algorithms_executed", 0)
	perfect_streak = save_data.get("perfect_streak", 0)
	
	if save_data.has("algorithm_usage"):
		algorithm_usage = save_data.algorithm_usage.duplicate()
	
	if save_data.has("cumulative_achievements"):
		cumulative_achievements = save_data.cumulative_achievements.duplicate()

## Resetear estadísticas (para debug)
func reset_statistics() -> void:
	total_play_time = 0.0
	total_nodes_visited = 0
	total_edges_traversed = 0
	total_missions_started = 0
	total_missions_completed = 0
	total_missions_failed = 0
	total_mistakes = 0
	total_resources_used = 0
	total_algorithms_executed = 0
	perfect_streak = 0
	current_streak = 0
	
	for key in algorithm_usage.keys():
		algorithm_usage[key] = 0
	
	for key in cumulative_achievements.keys():
		cumulative_achievements[key] = false
	
	_save_to_disk()
