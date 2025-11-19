extends Node
## Controlador base de misión — las escenas de misión deben instanciar y extender este controlador.

signal mission_completed(result)

var graph = null
var ui = null
var mission_id: String = "Mission_Unknown"  ## Override this in derived classes

## Métricas para el sistema de puntuación
var mission_start_time: float = 0.0
var moves_count: int = 0
var optimal_moves: int = 0
var mistakes_count: int = 0
var resources_used: int = 0
var resources_available: int = 0

const MISSION_ACHIEVEMENT_PANEL := preload("res://scripts/ui/MissionAchievementPanel.gd")
const DEFAULT_PANEL_PATH := NodePath("HUD/SidePanel/PanelMargin/ScrollContainer/VBoxContainer")
const SCORE_PANEL_SCENE := preload("res://scenes/ui/MissionScorePanel.tscn")
const ScoringSys := preload("res://scripts/systems/ScoringSystem.gd")

func setup(graph_model, display_node) -> void:
	graph = graph_model
	ui = display_node



func init_mission_common(mid: String, status: String) -> void:
	# Inicializacion comun para escenas de misiones: asigna id, carga grafo,
	# enlaza display y delega inicializacion especifica a implementaciones hijas.
	mission_id = mid
	ensure_mission_achievement_panel()

	var graph_builder = get_node_or_null("GraphBuilder") as GraphBuilder
	if graph_builder:
		graph = graph_builder.get_graph()
		if has_method("_mutate_graph_structure"):
			_mutate_graph_structure()
	else:
		push_warning("%s: No se encontro nodo %s." % [mission_id, "GraphBuilder"])
		graph = Graph.new()

	var disp = get_node_or_null("GraphDisplay")
	if disp:
		setup(graph, disp)
		if disp.has_method("display_graph"):
			disp.display_graph(graph)
		if disp.has_signal("node_selected"):
			disp.node_selected.connect(_on_graph_node_selected)
	else:
		push_warning("%s: No se encontro %s para visualizacion." % [mission_id, "GraphDisplay"])

	# Delegar inicializacion de sistemas y reseteo a la implementacion especifica
	if has_method("_initialize_dynamic_systems"):
		_initialize_dynamic_systems()
	if has_method("_reset_mission"):
		_reset_mission()
	_update_status(status)


# Default stubs so static analysis and child calls resolve cleanly.
func _mutate_graph_structure() -> void:
	pass

func _on_graph_node_selected(_node_key) -> void:
	pass

func _initialize_dynamic_systems() -> void:
	pass

func _reset_mission() -> void:
	pass

func _update_status(_message: String) -> void:
	pass

func ensure_mission_achievement_panel(container_path: NodePath = DEFAULT_PANEL_PATH) -> void:
	if MISSION_ACHIEVEMENT_PANEL == null:
		return
	if not is_inside_tree():
		return
	var container := get_node_or_null(container_path)
	if container == null:
		return
	var continue_button := container.get_node_or_null("ContinueButton")
	var divider := container.get_node_or_null("AchievementsDivider")
	if divider == null:
		divider = HSeparator.new()
		divider.name = "AchievementsDivider"
		container.add_child(divider)
	var panel := container.get_node_or_null("MissionAchievements")
	if panel == null:
		panel = MISSION_ACHIEVEMENT_PANEL.new()
		panel.name = "MissionAchievements"
		container.add_child(panel)
	panel.mission_id = mission_id
	panel.heading_text = "LOGROS DE LA MISIÓN"
	panel.empty_text = "Cumple los objetivos para desbloquear logros."
	if panel.has_method("refresh_panel"):
		panel.refresh_panel()
	if continue_button and continue_button.get_parent() == container:
		var continue_index: int = continue_button.get_index()
		if divider and divider.get_parent() == container:
			container.move_child(divider, continue_index)
			continue_index = continue_button.get_index()
		if panel.get_parent() == container:
			container.move_child(panel, continue_index)


func start() -> void:
	# Iniciar el temporizador de la misión
	mission_start_time = Time.get_ticks_msec() / 1000.0
	moves_count = 0
	mistakes_count = 0
	
	# Implementado por misiones derivadas para iniciar la lógica
	pass

func step() -> void:
	# Avanza la ejecución un paso; override en misiones que lo requieran
	pass

## Incrementar contador de movimientos
func add_move() -> void:
	moves_count += 1

## Incrementar contador de errores
func add_mistake() -> void:
	mistakes_count += 1

## Establecer movimientos óptimos para la misión
func set_optimal_moves(count: int) -> void:
	optimal_moves = count

## Establecer recursos disponibles y usados
func set_resources(used: int, available: int) -> void:
	resources_used = used
	resources_available = available

func complete(result := {}) -> void:
	# Calcular tiempo de completado
	var completion_time = (Time.get_ticks_msec() / 1000.0) - mission_start_time
	
	# Calcular score
	var score = ScoringSys.calculate_score(
		mission_id,
		completion_time,
		moves_count,
		optimal_moves,
		mistakes_count,
		resources_used,
		resources_available
	)
	
	# Guardar score
	var old_best = MissionScoreManager.get_best_score(mission_id)
	MissionScoreManager.save_mission_score(score)
	var is_new_best = ScoringSys.is_better_score(score, old_best)
	
	# Emitir eventos
	EventBus.mission_score_saved.emit(mission_id, score.total_score, score.rank, is_new_best)
	
	if score.rank == "gold":
		EventBus.gold_rank_achieved.emit(mission_id)
	
	if score.perfect:
		EventBus.perfect_score_achieved.emit(mission_id)
	
	# Mostrar panel de score
	_show_score_panel(score.to_dict(), is_new_best)
	
	emit_signal("mission_completed", result)
	# Enviar mission_id para que GameManager registre correctamente la finalización
	GameManager.finish_mission(result)

	var success = result.get("status", "") == "done"
	EventBus.mission_completed.emit(mission_id, success, result)

func _show_score_panel(score_dict: Dictionary, is_new_best: bool) -> void:
	if not SCORE_PANEL_SCENE:
		return
	
	var score_panel = SCORE_PANEL_SCENE.instantiate()
	
	# Agregar el panel al árbol
	add_child(score_panel)
	
	# Centrar el panel
	score_panel.position = get_viewport().get_visible_rect().size / 2 - score_panel.size / 2
	
	# Mostrar el score
	score_panel.display_score(score_dict, is_new_best)
	
	# Conectar señales
	score_panel.retry_requested.connect(_on_retry_requested)
	score_panel.continue_requested.connect(_on_continue_requested)

func _on_retry_requested() -> void:
	# Reiniciar la misión
	if has_method("_reset_mission"):
		_reset_mission()
	start()

func _on_continue_requested() -> void:
	# Volver al menú de misiones
	SceneManager.change_to("res://scenes/MissionSelect.tscn")
