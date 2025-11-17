extends Control
## Controller para la escena del hub de logros/desafíos.

@onready var list_container: VBoxContainer = %AchievementList
@onready var empty_label: Label = %EmptyLabel
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton

var achievement_manager: Node = null

func _ready() -> void:
	achievement_manager = get_node_or_null("/root/AchievementManager")
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	if achievement_manager and achievement_manager.has_signal("achievement_unlocked"):
		achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
	_refresh_list()


func _refresh_list() -> void:
	if list_container == null:
		return
	for child in list_container.get_children():
		child.queue_free()
	var items: Array = achievement_manager.get_achievement_list() if achievement_manager else []
	items.sort_custom(Callable(self, "_sort_achievements"))
	empty_label.visible = items.is_empty()
	for data in items:
		list_container.add_child(_build_entry(data))


func _build_entry(data: Dictionary) -> Control:
	var entry := HBoxContainer.new()
	entry.add_theme_constant_override("separation", 12)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var status_icon := ColorRect.new()
	status_icon.custom_minimum_size = Vector2(18, 18)
	status_icon.color = Color(0.3, 0.85, 0.5, 1.0) if data.get("unlocked", false) else Color(0.4, 0.45, 0.55, 0.8)
	entry.add_child(status_icon)

	var text_block := VBoxContainer.new()
	text_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_block.add_theme_constant_override("separation", 2)
	entry.add_child(text_block)

	var title_label := Label.new()
	title_label.text = str(data.get("title", data.get("id", "")))
	title_label.add_theme_font_size_override("font_size", 18)
	text_block.add_child(title_label)

	var desc_label := Label.new()
	desc_label.text = str(data.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 1))
	desc_label.add_theme_font_size_override("font_size", 13)
	text_block.add_child(desc_label)

	var status_line := Label.new()
	var unlocked: bool = bool(data.get("unlocked", false))
	var timestamp: int = int(data.get("timestamp", 0))
	if unlocked and timestamp > 0:
		var formatted := Time.get_datetime_string_from_unix_time(timestamp, true)
		status_line.text = "Completado • %s" % formatted
	else:
		var mission_id: String = str(data.get("mission_id", ""))
		status_line.text = "Pendiente" if mission_id == "" else "Pendiente • %s" % mission_id
	status_line.add_theme_font_size_override("font_size", 12)
	status_line.add_theme_color_override("font_color", Color(0.45, 0.9, 0.6, 1) if unlocked else Color(0.55, 0.6, 0.75, 1))
	text_block.add_child(status_line)

	return entry


func _sort_achievements(a: Dictionary, b: Dictionary) -> bool:
	var unlocked_a: bool = bool(a.get("unlocked", false))
	var unlocked_b: bool = bool(b.get("unlocked", false))
	if unlocked_a == unlocked_b:
		return str(a.get("title", "")) < str(b.get("title", ""))
	return not unlocked_a and unlocked_b


func _on_back_pressed() -> void:
	SceneManager.change_to("res://scenes/MainMenu.tscn")


func _on_reset_pressed() -> void:
	if achievement_manager and achievement_manager.has_method("reset_progress"):
		achievement_manager.reset_progress()
	_refresh_list()


func _on_achievement_unlocked(_id: String, _data: Dictionary) -> void:
	_refresh_list()
