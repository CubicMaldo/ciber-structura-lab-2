extends PanelContainer
## MissionRankingsPanel - Panel para mostrar rankings y mejores scores de todas las misiones

@onready var close_button: Button = %CloseButton
@onready var missions_label: Label = %MissionsLabel
@onready var gold_label: Label = %GoldLabel
@onready var silver_label: Label = %SilverLabel
@onready var bronze_label: Label = %BronzeLabel
@onready var perfect_label: Label = %PerfectLabel
@onready var mission1_button: Button = %Mission1Button
@onready var mission2_button: Button = %Mission2Button
@onready var mission3_button: Button = %Mission3Button
@onready var mission4_button: Button = %Mission4Button
@onready var mission_final_button: Button = %MissionFinalButton
@onready var scores_container: VBoxContainer = %ScoresContainer

var current_mission: String = "Mission_1"

signal closed()

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if mission1_button:
		mission1_button.pressed.connect(func(): _show_mission_scores("Mission_1"))
	if mission2_button:
		mission2_button.pressed.connect(func(): _show_mission_scores("Mission_2"))
	if mission3_button:
		mission3_button.pressed.connect(func(): _show_mission_scores("Mission_3"))
	if mission4_button:
		mission4_button.pressed.connect(func(): _show_mission_scores("Mission_4"))
	if mission_final_button:
		mission_final_button.pressed.connect(func(): _show_mission_scores("Mission_Final"))
	
	# Conectar a la señal de score guardado para actualizar stats
	if MissionScoreManager:
		MissionScoreManager.score_saved.connect(_on_score_saved)
	
	refresh_all()

func refresh_all() -> void:
	# Recargar completamente las estadísticas y scores
	_update_stats()
	_show_mission_scores(current_mission)

func _on_score_saved(_mission_id: String, _score_dict: Dictionary, _is_new_best: bool) -> void:
	# Actualizar estadísticas cuando se guarda un nuevo score
	_update_stats()
	# Actualizar la lista de scores si es la misión actual
	if _mission_id == current_mission:
		_show_mission_scores(current_mission)

func _update_stats() -> void:
	var stats = MissionScoreManager.get_player_stats()
	
	if missions_label:
		missions_label.text = "🎯 Misiones: %d" % stats.total_missions_completed
	if gold_label:
		gold_label.text = "🥇 Oro: %d" % stats.gold_ranks
	if silver_label:
		silver_label.text = "🥈 Plata: %d" % stats.silver_ranks
	if bronze_label:
		bronze_label.text = "🥉 Bronce: %d" % stats.bronze_ranks
	if perfect_label:
		perfect_label.text = "✨ Perfectas: %d" % stats.perfect_completions

func _show_mission_scores(mission_id: String) -> void:
	current_mission = mission_id
	
	# Actualizar botones (con validación)
	if mission1_button:
		mission1_button.button_pressed = (mission_id == "Mission_1")
	if mission2_button:
		mission2_button.button_pressed = (mission_id == "Mission_2")
	if mission3_button:
		mission3_button.button_pressed = (mission_id == "Mission_3")
	if mission4_button:
		mission4_button.button_pressed = (mission_id == "Mission_4")
	if mission_final_button:
		mission_final_button.button_pressed = (mission_id == "Mission_Final")
	
	# Limpiar contenedor
	if not scores_container:
		return
		
	for child in scores_container.get_children():
		child.queue_free()
	
	# Obtener scores de la misión
	var scores = MissionScoreManager.get_top_scores(mission_id, 10)
	
	if scores.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No hay scores registrados para esta misión."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_container.add_child(empty_label)
		return
	
	# Mostrar cada score
	for i in range(scores.size()):
		var score = scores[i]
		var entry = _create_score_entry(score, i + 1)
		scores_container.add_child(entry)

func _create_score_entry(score, rank: int) -> PanelContainer:
	var panel = PanelContainer.new()
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)
	
	# Ranking
	var rank_label = Label.new()
	rank_label.text = "#%d" % rank
	rank_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(rank_label)
	
	# Icono de rango
	var rank_icon = Label.new()
	rank_icon.text = _get_rank_icon(score.rank)
	rank_icon.add_theme_font_size_override("font_size", 24)
	hbox.add_child(rank_icon)
	
	# Score total
	var score_label = Label.new()
	score_label.text = "Score: %d" % score.total_score
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(score_label)
	
	# Tiempo
	var time_label = Label.new()
	time_label.text = "⏱️ %.1fs" % score.completion_time
	hbox.add_child(time_label)
	
	# Movimientos
	var moves_label = Label.new()
	moves_label.text = "🎯 %d/%d" % [score.moves_used, score.optimal_moves]
	hbox.add_child(moves_label)
	
	# Errores
	var mistakes_label = Label.new()
	mistakes_label.text = "❌ %d" % score.mistakes
	hbox.add_child(mistakes_label)
	
	# Badge perfecto
	if score.perfect:
		var perfect_icon = Label.new()
		perfect_icon.text = "✨"
		perfect_icon.add_theme_font_size_override("font_size", 20)
		hbox.add_child(perfect_icon)
	
	# Colorear según rango
	var color = _get_rank_color(score.rank)
	panel.add_theme_stylebox_override("panel", _create_colored_stylebox(color))
	
	return panel

func _create_colored_stylebox(color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.3)
	stylebox.border_color = color
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	return stylebox

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

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
