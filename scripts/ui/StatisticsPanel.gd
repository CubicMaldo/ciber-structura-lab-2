extends PanelContainer
## StatisticsPanel - Panel para mostrar estadísticas globales del jugador

@onready var close_button: Button = %CloseButton
@onready var play_time_value: Label = %PlayTimeValue
@onready var session_time_value: Label = %SessionTimeValue
@onready var missions_started_value: Label = %MissionsStartedValue
@onready var missions_completed_value: Label = %MissionsCompletedValue
@onready var success_rate_value: Label = %SuccessRateValue
@onready var nodes_visited_value: Label = %NodesVisitedValue
@onready var edges_traversed_value: Label = %EdgesTraversedValue
@onready var efficiency_value: Label = %EfficiencyValue
@onready var mistakes_value: Label = %MistakesValue
@onready var resources_value: Label = %ResourcesValue
@onready var streak_value: Label = %StreakValue
@onready var algorithms_grid: GridContainer = %AlgorithmsGrid
@onready var most_used_value: Label = %MostUsedValue

signal closed()

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_update_statistics()
	
	# Actualizar cada segundo
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_statistics)
	timer.autostart = true
	add_child(timer)

func _update_statistics() -> void:
	var stats = StatisticsManager.get_statistics()
	
	# Tiempo de juego
	play_time_value.text = _format_time(stats.total_play_time)
	session_time_value.text = _format_time(stats.session_play_time)
	
	# Misiones
	missions_started_value.text = str(stats.total_missions_started)
	missions_completed_value.text = str(stats.total_missions_completed)
	
	var success_rate = StatisticsManager.get_success_rate()
	success_rate_value.text = "%.1f%%" % success_rate
	
	# Color según tasa de éxito
	if success_rate >= 80:
		success_rate_value.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	elif success_rate >= 50:
		success_rate_value.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	else:
		success_rate_value.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	
	# Exploración
	nodes_visited_value.text = str(stats.total_nodes_visited)
	edges_traversed_value.text = str(stats.total_edges_traversed)
	
	# Rendimiento
	var efficiency = StatisticsManager.get_average_efficiency()
	efficiency_value.text = "%.1f%%" % efficiency
	
	# Color según eficiencia
	if efficiency >= 90:
		efficiency_value.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	elif efficiency >= 70:
		efficiency_value.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	else:
		efficiency_value.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	
	mistakes_value.text = str(stats.total_mistakes)
	resources_value.text = str(stats.total_resources_used)
	streak_value.text = str(stats.perfect_streak)
	
	# Algoritmos
	_update_algorithms_display(stats.algorithm_usage)
	
	var most_used = StatisticsManager.get_most_used_algorithm()
	most_used_value.text = most_used

func _update_algorithms_display(algorithm_usage: Dictionary) -> void:
	# Limpiar grid
	for child in algorithms_grid.get_children():
		child.queue_free()
	
	# Agregar cada algoritmo
	for algo in algorithm_usage.keys():
		var name_label = Label.new()
		name_label.text = "• " + algo + ":"
		algorithms_grid.add_child(name_label)
		
		var count_label = Label.new()
		count_label.text = str(algorithm_usage[algo])
		count_label.add_theme_font_size_override("font_size", 16)
		
		# Color según uso
		var count = algorithm_usage[algo]
		if count == 0:
			count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		elif count >= 10:
			count_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		else:
			count_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
		
		algorithms_grid.add_child(count_label)

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var secs = total_seconds % 60
	
	if hours > 0:
		return "%dh %dm %ds" % [hours, minutes, secs]
	elif minutes > 0:
		return "%dm %ds" % [minutes, secs]
	else:
		return "%ds" % secs

func _on_close_pressed() -> void:
	closed.emit()
	queue_free()
