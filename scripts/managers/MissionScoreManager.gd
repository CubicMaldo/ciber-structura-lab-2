extends Node
## MissionScoreManager - Gestiona el almacenamiento y recuperación de scores de misiones

const SAVE_FILE := "user://mission_scores.save"
const ScoringSys := preload("res://scripts/systems/ScoringSystem.gd")

var mission_scores: Dictionary = {}  # mission_id -> Array
var best_scores: Dictionary = {}  # mission_id -> Dictionary

signal score_saved(mission_id: String, score_dict: Dictionary, is_new_best: bool)
signal scores_loaded()

func _ready() -> void:
	load_scores()

## Guardar un nuevo score de misión
func save_mission_score(score) -> void:
	if not mission_scores.has(score.mission_id):
		mission_scores[score.mission_id] = []
	
	# Agregar el nuevo score
	mission_scores[score.mission_id].append(score)
	
	# Ordenar por score total (descendente)
	mission_scores[score.mission_id].sort_custom(func(a, b): return a.total_score > b.total_score)
	
	# Mantener solo los mejores 10 intentos
	if mission_scores[score.mission_id].size() > 10:
		mission_scores[score.mission_id].resize(10)
	
	# Actualizar mejor score si es necesario
	var is_new_best = false
	if not best_scores.has(score.mission_id):
		best_scores[score.mission_id] = score
		is_new_best = true
	else:
		var old_best = best_scores[score.mission_id]
		if ScoringSys.is_better_score(score, old_best):
			best_scores[score.mission_id] = score
			is_new_best = true
	
	# Guardar en disco
	_save_to_disk()
	
	# Emitir señal
	score_saved.emit(score.mission_id, score.to_dict(), is_new_best)

## Obtener el mejor score de una misión
func get_best_score(mission_id: String):
	return best_scores.get(mission_id, null)

## Obtener todos los scores de una misión
func get_mission_scores(mission_id: String) -> Array:
	return mission_scores.get(mission_id, [])

## Obtener el top N de scores de una misión
func get_top_scores(mission_id: String, count: int = 5) -> Array:
	var scores = get_mission_scores(mission_id)
	return scores.slice(0, min(count, scores.size()))

## Verificar si el jugador tiene algún score en una misión
func has_completed_mission(mission_id: String) -> bool:
	return best_scores.has(mission_id)

## Obtener estadísticas generales del jugador
func get_player_stats() -> Dictionary:
	var stats = {
		"total_missions_completed": best_scores.size(),
		"perfect_completions": 0,
		"gold_ranks": 0,
		"silver_ranks": 0,
		"bronze_ranks": 0,
		"total_score": 0,
		"average_score": 0,
		"total_time": 0.0,
		"best_mission": "",
		"best_mission_score": 0
	}
	
	# Contar todos los rangos de TODOS los scores, no solo los mejores
	for mission_id in mission_scores.keys():
		for score in mission_scores[mission_id]:
			if score.perfect:
				stats.perfect_completions += 1
			
			match score.rank:
				"gold":
					stats.gold_ranks += 1
				"silver":
					stats.silver_ranks += 1
				"bronze":
					stats.bronze_ranks += 1
	
	# Usar best_scores para otras estadísticas
	for mission_id in best_scores.keys():
		var score = best_scores[mission_id]
		
		stats.total_score += score.total_score
		stats.total_time += score.completion_time
		
		if score.total_score > stats.best_mission_score:
			stats.best_mission_score = score.total_score
			stats.best_mission = mission_id
	
	if best_scores.size() > 0:
		stats.average_score = stats.total_score / best_scores.size()
	
	return stats

## Obtener ranking de todas las misiones
func get_all_rankings() -> Dictionary:
	var rankings = {}
	for mission_id in best_scores.keys():
		var score = best_scores[mission_id]
		rankings[mission_id] = {
			"rank": score.rank,
			"score": score.total_score,
			"perfect": score.perfect
		}
	return rankings

## Limpiar todos los scores (para debug)
func clear_all_scores() -> void:
	mission_scores.clear()
	best_scores.clear()
	_save_to_disk()
	# Emitir señal para notificar cambios
	scores_loaded.emit()

## Guardar scores en disco
func _save_to_disk() -> void:
	var save_data = {
		"version": 1,
		"mission_scores": {},
		"best_scores": {}
	}
	
	# Convertir mission_scores
	for mission_id in mission_scores.keys():
		var scores_array = []
		for score in mission_scores[mission_id]:
			scores_array.append(score.to_dict())
		save_data.mission_scores[mission_id] = scores_array
	
	# Convertir best_scores
	for mission_id in best_scores.keys():
		save_data.best_scores[mission_id] = best_scores[mission_id].to_dict()
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

## Cargar scores desde disco
func load_scores() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		return
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return
	
	var save_data = file.get_var()
	file.close()
	
	if typeof(save_data) != TYPE_DICTIONARY:
		return
	
	# Cargar mission_scores
	if save_data.has("mission_scores"):
		for mission_id in save_data.mission_scores.keys():
			mission_scores[mission_id] = []
			for score_dict in save_data.mission_scores[mission_id]:
				var score = ScoringSys.MissionScore.from_dict(score_dict)
				# RECALCULAR RANK con el sistema actual
				score.rank = ScoringSys.calculate_rank(score.total_score)
				mission_scores[mission_id].append(score)
	
	# Cargar best_scores
	if save_data.has("best_scores"):
		for mission_id in save_data.best_scores.keys():
			var score = ScoringSys.MissionScore.from_dict(save_data.best_scores[mission_id])
			# RECALCULAR RANK con el sistema actual
			score.rank = ScoringSys.calculate_rank(score.total_score)
			best_scores[mission_id] = score
	
	scores_loaded.emit()
