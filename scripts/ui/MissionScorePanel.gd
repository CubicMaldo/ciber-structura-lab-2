extends PanelContainer
## MissionScorePanel - Panel visual para mostrar los resultados y score de una misión

@onready var rank_icon: Label = %RankIcon
@onready var rank_label: Label = %RankLabel
@onready var score_label: Label = %ScoreLabel
@onready var efficiency_score: Label = %EfficiencyScore
@onready var time_score: Label = %TimeScore
@onready var moves_score: Label = %MovesScore
@onready var resource_score: Label = %ResourceScore
@onready var time_used: Label = %TimeUsed
@onready var moves_used: Label = %MovesUsed
@onready var mistakes_count: Label = %MistakesCount
@onready var new_best_label: Label = %NewBestLabel
@onready var perfect_label: Label = %PerfectLabel
@onready var retry_button: Button = %RetryButton
@onready var continue_button: Button = %ContinueButton

signal retry_requested()
signal continue_requested()

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	continue_button.pressed.connect(_on_continue_pressed)

## Mostrar el score de una misión
func display_score(score: Dictionary, is_new_best: bool = false) -> void:
	# Actualizar rango
	var rank = score.get("rank", "none")
	rank_icon.text = _get_rank_icon(rank)
	rank_label.text = _get_rank_name(rank).to_upper()
	rank_label.add_theme_color_override("font_color", _get_rank_color(rank))
	
	# Actualizar score total
	score_label.text = "SCORE: %d" % score.get("total_score", 0)
	
	# Actualizar scores individuales
	efficiency_score.text = str(score.get("efficiency_score", 0))
	time_score.text = str(score.get("time_score", 0))
	moves_score.text = str(score.get("moves_score", 0))
	resource_score.text = str(score.get("resource_score", 0))
	
	# Actualizar estadísticas
	var time = score.get("completion_time", 0.0)
	var mission_id = score.get("mission_id", "")
	var target_time = _get_target_time(mission_id)
	time_used.text = "⏱️ Tiempo: %.1fs / %.0fs" % [time, target_time]
	
	var moves = score.get("moves_used", 0)
	var optimal = score.get("optimal_moves", 0)
	moves_used.text = "🎯 Movimientos: %d / %d (óptimo)" % [moves, optimal]
	
	var mistakes = score.get("mistakes", 0)
	mistakes_count.text = "❌ Errores: %d" % mistakes
	
	# Mostrar etiquetas especiales
	new_best_label.visible = is_new_best
	perfect_label.visible = score.get("perfect", false)
	
	# Animar entrada
	_animate_entry()

func _get_rank_icon(rank: String) -> String:
	match rank:
		"gold":
			return "🥇"
		"silver":
			return "🥈"
		"bronze":
			return "🥉"
		_:
			return "○"

func _get_rank_name(rank: String) -> String:
	match rank:
		"gold":
			return "Oro"
		"silver":
			return "Plata"
		"bronze":
			return "Bronce"
		_:
			return "Sin rango"

func _get_rank_color(rank: String) -> Color:
	match rank:
		"gold":
			return Color(1.0, 0.84, 0.0)
		"silver":
			return Color(0.75, 0.75, 0.75)
		"bronze":
			return Color(0.8, 0.5, 0.2)
		_:
			return Color(0.5, 0.5, 0.5)

func _get_target_time(mission_id: String) -> float:
	const TARGETS = {
		"Mission_1": 120.0,
		"Mission_2": 90.0,
		"Mission_3": 150.0,
		"Mission_4": 180.0,
		"Mission_Final": 300.0
	}
	return TARGETS.get(mission_id, 120.0)

func _animate_entry() -> void:
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_retry_pressed() -> void:
	retry_requested.emit()

func _on_continue_pressed() -> void:
	continue_requested.emit()
