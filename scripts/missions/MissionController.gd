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
	GameManager.finish_mission(result, mission_id)

	var success = result.get("status", "") == "done"
	EventBus.mission_completed.emit(mission_id, success, result)
