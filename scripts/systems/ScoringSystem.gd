extends Node
## ScoringSystem - Sistema de puntuación robusto para misiones
## Calcula scores basados en eficiencia, tiempo, movimientos y recursos

## Representa el resultado de puntuación de una misión
class MissionScore:
	var mission_id: String
	var total_score: int = 0
	var efficiency_score: int = 0
	var time_score: int = 0
	var moves_score: int = 0
	var resource_score: int = 0
	var mistakes: int = 0
	var completion_time: float = 0.0
	var moves_used: int = 0
	var optimal_moves: int = 0
	var resources_used: int = 0
	var resources_available: int = 0
	var rank: String = "none"  # "gold", "silver", "bronze", "none"
	var perfect: bool = false
	var completed: bool = false
	var timestamp: int = 0
	
	func _init(p_mission_id: String):
		mission_id = p_mission_id
		timestamp = int(Time.get_unix_time_from_system())
	
	func to_dict() -> Dictionary:
		return {
			"mission_id": mission_id,
			"total_score": total_score,
			"efficiency_score": efficiency_score,
			"time_score": time_score,
			"moves_score": moves_score,
			"resource_score": resource_score,
			"mistakes": mistakes,
			"completion_time": completion_time,
			"moves_used": moves_used,
			"optimal_moves": optimal_moves,
			"resources_used": resources_used,
			"resources_available": resources_available,
			"rank": rank,
			"perfect": perfect,
			"completed": completed,
			"timestamp": timestamp
		}
	
	static func from_dict(data: Dictionary) -> MissionScore:
		var score = MissionScore.new(data.get("mission_id", ""))
		score.total_score = data.get("total_score", 0)
		score.efficiency_score = data.get("efficiency_score", 0)
		score.time_score = data.get("time_score", 0)
		score.moves_score = data.get("moves_score", 0)
		score.resource_score = data.get("resource_score", 0)
		score.mistakes = data.get("mistakes", 0)
		score.completion_time = data.get("completion_time", 0.0)
		score.moves_used = data.get("moves_used", 0)
		score.optimal_moves = data.get("optimal_moves", 0)
		score.resources_used = data.get("resources_used", 0)
		score.resources_available = data.get("resources_available", 0)
		score.rank = data.get("rank", "none")
		score.perfect = data.get("perfect", false)
		score.completed = data.get("completed", false)
		score.timestamp = data.get("timestamp", 0)
		return score

## Umbrales para rangos (porcentaje del score máximo)
const GOLD_THRESHOLD := 0.90
const SILVER_THRESHOLD := 0.75
const BRONZE_THRESHOLD := 0.60

## Pesos para el cálculo de score total
const EFFICIENCY_WEIGHT := 0.35
const TIME_WEIGHT := 0.25
const MOVES_WEIGHT := 0.25
const RESOURCE_WEIGHT := 0.15

## Scores máximos por categoría
const MAX_EFFICIENCY_SCORE := 1000
const MAX_TIME_SCORE := 1000
const MAX_MOVES_SCORE := 1000
const MAX_RESOURCE_SCORE := 1000

## Tiempos objetivo por misión (en segundos)
const MISSION_TIME_TARGETS := {
	"Mission_1": 120.0,
	"Mission_2": 90.0,
	"Mission_3": 150.0,
	"Mission_4": 180.0,
	"Mission_Final": 300.0
}

## Calcular score de una misión completada
static func calculate_score(
	mission_id: String,
	completion_time: float,
	moves_used: int,
	optimal_moves: int,
	mistakes: int,
	resources_used: int,
	resources_available: int
) -> MissionScore:
	var score = MissionScore.new(mission_id)
	score.completion_time = completion_time
	score.moves_used = moves_used
	score.optimal_moves = max(optimal_moves, 1)  # Evitar división por cero
	score.mistakes = mistakes
	score.resources_used = resources_used
	score.resources_available = max(resources_available, 1)
	score.completed = true
	
	# Calcular score de eficiencia (basado en movimientos óptimos)
	score.efficiency_score = _calculate_efficiency_score(moves_used, optimal_moves, mistakes)
	
	# Calcular score de tiempo
	score.time_score = _calculate_time_score(mission_id, completion_time)
	
	# Calcular score de movimientos
	score.moves_score = _calculate_moves_score(moves_used, optimal_moves)
	
	# Calcular score de recursos
	score.resource_score = _calculate_resource_score(resources_used, resources_available)
	
	# Calcular score total ponderado
	var base_score = int(
		score.efficiency_score * EFFICIENCY_WEIGHT +
		score.time_score * TIME_WEIGHT +
		score.moves_score * MOVES_WEIGHT +
		score.resource_score * RESOURCE_WEIGHT
	)
	
	# Penalización DIRECTA por errores al score total (50 puntos por error)
	var mistake_penalty_total = mistakes * 50
	score.total_score = max(0, base_score - mistake_penalty_total)
	
	# Determinar rango
	score.rank = calculate_rank(score.total_score)
	
	# Verificar si es perfecto
	score.perfect = (mistakes == 0 and moves_used <= optimal_moves and score.rank == "gold")
	
	return score

static func _calculate_efficiency_score(moves_used: int, optimal_moves: int, mistakes: int) -> int:
	if optimal_moves <= 0:
		return MAX_EFFICIENCY_SCORE
	
	# Penalización por movimientos extra
	var move_ratio = float(optimal_moves) / float(max(moves_used, 1))
	var move_score = move_ratio * 700  # 70% del score
	
	# Penalización por errores (severa)
	var mistake_penalty = mistakes * 150  # 150 puntos por error
	var mistake_score = max(0, 300 - mistake_penalty)  # 30% del score
	
	return int(clamp(move_score + mistake_score, 0, MAX_EFFICIENCY_SCORE))

static func _calculate_time_score(mission_id: String, completion_time: float) -> int:
	var target_time = MISSION_TIME_TARGETS.get(mission_id, 120.0)
	
	if completion_time <= target_time:
		# Bonus por completar antes del tiempo objetivo
		var time_ratio = 1.0 - (completion_time / target_time)
		return int(MAX_TIME_SCORE * (0.8 + time_ratio * 0.2))
	else:
		# Penalización por exceder el tiempo
		var overtime_ratio = (completion_time - target_time) / target_time
		var penalty = overtime_ratio * 500
		return int(clamp(MAX_TIME_SCORE - penalty, 100, MAX_TIME_SCORE))

static func _calculate_moves_score(moves_used: int, optimal_moves: int) -> int:
	if optimal_moves <= 0:
		return MAX_MOVES_SCORE
	
	var efficiency_ratio = float(optimal_moves) / float(max(moves_used, 1))
	
	if efficiency_ratio >= 1.0:
		# Movimientos óptimos o mejor
		return MAX_MOVES_SCORE
	elif efficiency_ratio >= 0.8:
		# Dentro del 20% de óptimo
		return int(MAX_MOVES_SCORE * efficiency_ratio)
	else:
		# Penalización mayor por exceso de movimientos
		return int(MAX_MOVES_SCORE * efficiency_ratio * 0.7)

static func _calculate_resource_score(resources_used: int, resources_available: int) -> int:
	if resources_available <= 0:
		return MAX_RESOURCE_SCORE
	
	var usage_ratio = float(resources_used) / float(resources_available)
	
	# Bonus por usar pocos recursos
	if usage_ratio <= 0.3:
		return MAX_RESOURCE_SCORE
	elif usage_ratio <= 0.5:
		return int(MAX_RESOURCE_SCORE * 0.9)
	elif usage_ratio <= 0.7:
		return int(MAX_RESOURCE_SCORE * 0.7)
	else:
		# Penalización por usar demasiados recursos
		return int(MAX_RESOURCE_SCORE * (1.0 - usage_ratio) * 0.5)

static func calculate_rank(total_score: int) -> String:
	# El score máximo es 1000, calculamos el porcentaje directamente
	var score_ratio = float(total_score) / 1000.0
	
	if score_ratio >= GOLD_THRESHOLD:
		return "gold"
	elif score_ratio >= SILVER_THRESHOLD:
		return "silver"
	elif score_ratio >= BRONZE_THRESHOLD:
		return "bronze"
	else:
		return "none"

static func get_rank_name(rank: String) -> String:
	match rank:
		"gold":
			return "Oro"
		"silver":
			return "Plata"
		"bronze":
			return "Bronce"
		_:
			return "Sin rango"

static func get_rank_color(rank: String) -> Color:
	match rank:
		"gold":
			return Color(1.0, 0.84, 0.0)  # Dorado
		"silver":
			return Color(0.75, 0.75, 0.75)  # Plateado
		"bronze":
			return Color(0.8, 0.5, 0.2)  # Bronce
		_:
			return Color(0.5, 0.5, 0.5)  # Gris

static func get_rank_icon(rank: String) -> String:
	match rank:
		"gold":
			return "🥇"
		"silver":
			return "🥈"
		"bronze":
			return "🥉"
		_:
			return "○"

## Comparar dos scores para determinar si uno es mejor
static func is_better_score(new_score: MissionScore, old_score: MissionScore) -> bool:
	if not old_score or not old_score.completed:
		return true
	
	# Priorizar por score total
	if new_score.total_score > old_score.total_score:
		return true
	elif new_score.total_score < old_score.total_score:
		return false
	
	# Si el score es igual, desempatar por otros criterios
	if new_score.mistakes < old_score.mistakes:
		return true
	elif new_score.mistakes > old_score.mistakes:
		return false
	
	if new_score.completion_time < old_score.completion_time:
		return true
	
	return false
