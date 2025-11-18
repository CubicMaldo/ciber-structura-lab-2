extends Node
## Controlador base de misión — las escenas de misión deben instanciar y extender este controlador.

signal mission_completed(result)

var graph = null
var ui = null
var mission_id: String = "Mission_Unknown"  ## Override this in derived classes

const MISSION_ACHIEVEMENT_PANEL := preload("res://scripts/ui/MissionAchievementPanel.gd")
const DEFAULT_PANEL_PATH := NodePath("HUD/SidePanel/PanelMargin/ScrollContainer/VBoxContainer")

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
	# Implementado por misiones derivadas para iniciar la lógica
	pass

func step() -> void:
	# Avanza la ejecución un paso; override en misiones que lo requieran
	pass

func complete(result := {}) -> void:
	emit_signal("mission_completed", result)
	# Enviar mission_id para que GameManager registre correctamente la finalización
	GameManager.finish_mission(result)

	var success = result.get("status", "") == "done"
	EventBus.mission_completed.emit(mission_id, success, result)
