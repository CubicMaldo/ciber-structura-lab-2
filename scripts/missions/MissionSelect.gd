extends Node2D
## MissionSelect controller - populates mission list and starts missions

var mission_data = {
	"Mission_1": {
		"title": "Misión 1: Network Tracer",
		"description": "Rastrea el grafo de red para encontrar el nodo raíz infectado",
		"algorithm": "BFS / DFS",
		"icon": "🔍",
		"difficulty": "Principiante"
	},
	"Mission_2": {
		"title": "Misión 2: Shortest Path",
		"description": "Encuentra la ruta más segura para aislar el nodo infectado",
		"algorithm": "Dijkstra",
		"icon": "🛤️",
		"difficulty": "Intermedio"
	},
	"Mission_3": {
		"title": "Misión 3: Network Flow",
		"description": "Optimiza el flujo de datos en la red comprometida",
		"algorithm": "Max Flow",
		"icon": "💧",
		"difficulty": "Intermedio"
	},
	"Mission_4": {
		"title": "Misión 4: Min Cut",
		"description": "Identifica el corte mínimo para segmentar la red infectada",
		"algorithm": "Min Cut",
		"icon": "✂️",
		"difficulty": "Avanzado"
	},
	"Mission_Final": {
		"title": "Misión Final: Red Global",
		"description": "Defiende la infraestructura crítica global del ataque coordinado",
		"algorithm": "Combinado",
		"icon": "🌐",
		"difficulty": "Experto"
	}
}

var missions = ["Mission_1", "Mission_2", "Mission_3", "Mission_4", "Mission_Final"]

func _ready() -> void:
	_populate()
	_connect_navigation_buttons()

func _connect_navigation_buttons() -> void:
	var back_btn = get_node_or_null("%BackButton")
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	var achievements_btn = get_node_or_null("%AchievementsButton")
	if achievements_btn:
		achievements_btn.pressed.connect(_on_achievements_pressed)

func _on_back_pressed() -> void:
	SceneManager.change_to("res://scenes/MainMenu.tscn")

func _on_achievements_pressed() -> void:
	SceneManager.change_to("res://scenes/AchievementsHub.tscn")

func _populate() -> void:
	var list = %MissionList
	var mission_index = 1
	
	for m in missions:
		var card = _create_mission_card(m, mission_index)
		list.add_child(card)
		mission_index += 1

func _create_mission_card(mission_id: String, _index: int) -> PanelContainer:
	var data = mission_data.get(mission_id, {})
	var is_unlocked = _is_mission_unlocked(mission_id)
	
	# Main card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	
	# Main horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)
	
	# Icon section
	var icon_panel = PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(80, 80)
	hbox.add_child(icon_panel)
	
	var icon_center = CenterContainer.new()
	icon_panel.add_child(icon_center)
	
	var icon_label = Label.new()
	icon_label.text = data.get("icon", "❓")
	icon_label.add_theme_font_size_override("font_size", 40)
	if not is_unlocked:
		icon_label.modulate = Color(0.4, 0.4, 0.4, 1.0)
	icon_center.add_child(icon_label)
	
	# Content section
	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	hbox.add_child(content)
	
	# Title
	var title = Label.new()
	title.text = data.get("title", mission_id)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0) if is_unlocked else Color(0.5, 0.5, 0.5, 1.0))
	content.add_child(title)
	
	# Description
	var desc = Label.new()
	desc.text = data.get("description", "")
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9, 1.0) if is_unlocked else Color(0.4, 0.4, 0.4, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(desc)
	
	# Tags row
	var tags = HBoxContainer.new()
	tags.add_theme_constant_override("separation", 10)
	content.add_child(tags)
	
	var algo_tag = Label.new()
	algo_tag.text = "📊 " + data.get("algorithm", "")
	algo_tag.add_theme_font_size_override("font_size", 12)
	algo_tag.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1.0) if is_unlocked else Color(0.3, 0.3, 0.3, 1.0))
	tags.add_child(algo_tag)
	
	var diff_tag = Label.new()
	diff_tag.text = "⭐ " + data.get("difficulty", "")
	diff_tag.add_theme_font_size_override("font_size", 12)
	diff_tag.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4, 1.0) if is_unlocked else Color(0.3, 0.3, 0.3, 1.0))
	tags.add_child(diff_tag)
	
	# Button section
	var btn_container = CenterContainer.new()
	hbox.add_child(btn_container)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 46)
	btn.disabled = not is_unlocked
	
	if is_unlocked:
		btn.text = "Iniciar ▶"
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(func(): _on_mission_selected(mission_id))
	else:
		btn.text = "🔒 Bloqueada"
		btn.add_theme_font_size_override("font_size", 14)
	
	btn_container.add_child(btn)
	
	# Status indicator
	if _is_mission_completed(mission_id):
		var completed_label = Label.new()
		completed_label.text = "✓ Completada"
		completed_label.add_theme_font_size_override("font_size", 11)
		completed_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6, 1.0))
		content.add_child(completed_label)
	
	return card

func _is_mission_unlocked(mission_id: String) -> bool:
	if not Engine.has_singleton("GameManager"):
		return mission_id == "Mission_1"
	var gm = Engine.get_singleton("GameManager")
	if gm and gm.has_method("is_mission_unlocked"):
		return gm.is_mission_unlocked(mission_id)
	return mission_id == "Mission_1"

func _is_mission_completed(mission_id: String) -> bool:
	if not Engine.has_singleton("GameManager"):
		return false
	var gm = Engine.get_singleton("GameManager")
	if gm and gm.has_method("is_mission_completed"):
		return gm.is_mission_completed(mission_id)
	return false

func _on_mission_selected(mission_id: String) -> void:
	# Emit mission selected signal with typed parameter
	EventBus.mission_selected.emit(mission_id)
	GameManager.start_mission(mission_id)
