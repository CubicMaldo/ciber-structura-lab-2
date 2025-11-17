extends VBoxContainer
## UI helper: displays mission-specific achievement requirements and progress.

@export var mission_id: String = ""
@export var heading_text: String = "LOGROS ASOCIADOS"
@export var empty_text: String = "No hay logros registrados para esta misión."
@export var max_entries: int = 3
@export var view_all_button_text: String = "Ver todos los logros"

var _achievement_manager: Node = null
var _list_container: VBoxContainer = null
var _empty_label: Label = null
var _heading_label: Label = null
var _footer_container: HBoxContainer = null
var _view_all_button: Button = null
var _dialog_popup: PopupPanel = null
var _dialog_list: VBoxContainer = null

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_build_static_nodes()
	_achievement_manager = get_node_or_null("/root/AchievementManager")
	if _achievement_manager and _achievement_manager.has_signal("achievement_unlocked"):
		_achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	_refresh()


func _build_static_nodes() -> void:
	if not _heading_label:
		_heading_label = Label.new()
		_heading_label.name = "Heading"
		_heading_label.add_theme_font_size_override("font_size", 14)
		_heading_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5, 1))
		add_child(_heading_label)
	_heading_label.text = heading_text

	if not _list_container:
		_list_container = VBoxContainer.new()
		_list_container.name = "Entries"
		_list_container.add_theme_constant_override("separation", 4)
		add_child(_list_container)

	if not _empty_label:
		_empty_label = Label.new()
		_empty_label.name = "EmptyLabel"
		_empty_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.8, 1))
		_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_child(_empty_label)
	_empty_label.text = empty_text

	if not _footer_container:
		_footer_container = HBoxContainer.new()
		_footer_container.name = "Footer"
		_footer_container.add_theme_constant_override("separation", 6)
		add_child(_footer_container)

	if not _view_all_button:
		_view_all_button = Button.new()
		_view_all_button.name = "ViewAllButton"
		_view_all_button.text = view_all_button_text
		_view_all_button.custom_minimum_size = Vector2(0, 28)
		_view_all_button.size_flags_horizontal = Control.SIZE_FILL
		_view_all_button.pressed.connect(_on_view_all_pressed)
		_footer_container.add_child(_view_all_button)


func _refresh() -> void:
	if not is_inside_tree():
		return
	for child in _list_container.get_children():
		child.queue_free()
	if mission_id == "":
		_show_empty("Configura mission_id para mostrar logros.")
		return
	if _achievement_manager == null:
		_show_empty("AchievementManager no disponible.")
		return
	if not _achievement_manager.has_method("get_achievements_for_mission"):
		_show_empty("No se puede consultar el progreso.")
		return
	var items: Array = _achievement_manager.get_achievements_for_mission(mission_id)
	if items.is_empty():
		_show_empty(empty_text)
		return
	_empty_label.visible = false
	var count: int = min(max_entries, items.size())
	for i in range(count):
		_list_container.add_child(_build_entry(items[i]))


func _build_entry(data: Dictionary) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 8)

	var status_icon := ColorRect.new()
	status_icon.custom_minimum_size = Vector2(12, 12)
	status_icon.color = Color(0.35, 0.9, 0.6, 1) if data.get("unlocked", false) else Color(0.45, 0.5, 0.65, 1)
	entry.add_child(status_icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	entry.add_child(text_box)

	var title := Label.new()
	title.text = str(data.get("title", data.get("id", "")))
	title.add_theme_font_size_override("font_size", 13)
	text_box.add_child(title)

	var requirement := Label.new()
	requirement.text = "Requisito: %s" % str(data.get("requirement", data.get("description", "")))
	requirement.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95, 1))
	requirement.add_theme_font_size_override("font_size", 11)
	requirement.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_box.add_child(requirement)

	var progress_label := Label.new()
	var progress := int(data.get("progress", 0))
	var goal: int = max(1, int(data.get("goal", 1)))
	progress_label.text = "Progreso: %d / %d" % [progress, goal]
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.7, 1) if data.get("unlocked", false) else Color(0.65, 0.7, 0.85, 1))
	text_box.add_child(progress_label)

	return entry


func _show_empty(message: String) -> void:
	_empty_label.visible = true
	_empty_label.text = message


func _on_achievement_unlocked(_id: String, _data: Dictionary) -> void:
	_refresh()
	_refresh_dialog_entries()


func refresh_panel() -> void:
	_refresh()
	_refresh_dialog_entries()


func _on_view_all_pressed() -> void:
	_ensure_dialog()
	_refresh_dialog_entries()
	if _dialog_popup:
		_dialog_popup.popup_centered(Vector2(540, 560))


func _ensure_dialog() -> void:
	if _dialog_popup and is_instance_valid(_dialog_popup):
		return
	_dialog_popup = PopupPanel.new()
	_dialog_popup.name = "AchievementListPopup"
	_dialog_popup.close_requested.connect(_dialog_popup.hide)
	_dialog_popup.title = "Logros y desafíos"
	_dialog_popup.size = Vector2(540, 600)
	var margin := MarginContainer.new()
	margin.theme = get_theme()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_dialog_popup.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title_label := Label.new()
	title_label.text = "Lista completa de logros"
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_dialog_list = VBoxContainer.new()
	_dialog_list.add_theme_constant_override("separation", 8)
	_dialog_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialog_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_dialog_list)
	var close_button := Button.new()
	close_button.text = "Cerrar"
	close_button.custom_minimum_size = Vector2(0, 32)
	close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_button.pressed.connect(_dialog_popup.hide)
	column.add_child(close_button)
	var tree := get_tree()
	if tree and tree.root:
		tree.root.add_child(_dialog_popup)
		_dialog_popup.hide()


func _refresh_dialog_entries() -> void:
	if not _dialog_popup or not is_instance_valid(_dialog_popup):
		return
	if _dialog_list == null:
		return
	for child in _dialog_list.get_children():
		child.queue_free()
	var items: Array = _achievement_manager.get_achievement_list() if _achievement_manager else []
	items.sort_custom(Callable(self, "_sort_dialog_entries"))
	for data in items:
		_dialog_list.add_child(_build_dialog_entry(data))


func _build_dialog_entry(data: Dictionary) -> Control:
	var entry := VBoxContainer.new()
	entry.add_theme_constant_override("separation", 2)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = str(data.get("title", data.get("id", "")))
	title.add_theme_font_size_override("font_size", 16)
	entry.add_child(title)
	var requirement := Label.new()
	requirement.text = str(data.get("requirement", data.get("description", "")))
	requirement.autowrap_mode = TextServer.AUTOWRAP_WORD
	requirement.add_theme_color_override("font_color", Color(0.75, 0.8, 0.95, 1))
	requirement.add_theme_font_size_override("font_size", 12)
	entry.add_child(requirement)
	var progress := Label.new()
	var progress_value := int(data.get("progress", 0))
	var goal: int = max(1, int(data.get("goal", 1)))
	var unlocked: bool = bool(data.get("unlocked", false))
	var mission := str(data.get("mission_id", "Campaña"))
	progress.text = "Progreso: %d / %d • %s" % [progress_value, goal, mission]
	progress.add_theme_font_size_override("font_size", 11)
	progress.add_theme_color_override("font_color", Color(0.45, 0.85, 0.6, 1) if unlocked else Color(0.65, 0.7, 0.85, 1))
	entry.add_child(progress)
	var divider := HSeparator.new()
	entry.add_child(divider)
	return entry


func _sort_dialog_entries(a: Dictionary, b: Dictionary) -> bool:
	var unlocked_a: bool = bool(a.get("unlocked", false))
	var unlocked_b: bool = bool(b.get("unlocked", false))
	if unlocked_a == unlocked_b:
		return str(a.get("title", "")) < str(b.get("title", ""))
	return not unlocked_a and unlocked_b
