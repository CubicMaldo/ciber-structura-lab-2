extends Control
## GlossaryUI - Interfaz de usuario para el glosario interactivo

@onready var search_input: LineEdit = %SearchInput
@onready var category_filter: OptionButton = %CategoryFilter
@onready var complexity_filter: OptionButton = %ComplexityFilter
@onready var terms_list: VBoxContainer = %TermsList
@onready var term_detail_panel: PanelContainer = %TermDetailPanel
@onready var term_title: Label = %TermTitle
@onready var term_category_label: Label = %TermCategoryLabel
@onready var term_complexity_label: Label = %TermComplexityLabel
@onready var term_description: RichTextLabel = %TermDescription
@onready var related_terms_container: VBoxContainer = %RelatedTermsContainer
@onready var external_links_container: VBoxContainer = %ExternalLinksContainer
@onready var missions_container: VBoxContainer = %MissionsContainer
@onready var visualization_container: Control = %VisualizationContainer
@onready var back_button: Button = %BackButton
@onready var no_results_label: Label = %NoResultsLabel

const TERM_ENTRY := preload("res://scenes/ui/GlossaryTermEntry.tscn")
const LINK_BUTTON := preload("res://scenes/ui/ExternalLinkButton.tscn")
const BFS_VIZ := preload("res://scenes/ui/visualizations/BFSVisualization.tscn")
const DFS_VIZ := preload("res://scenes/ui/visualizations/DFSVisualization.tscn")
const DIJKSTRA_VIZ := preload("res://scenes/ui/visualizations/DijkstraVisualization.tscn")
const MST_VIZ := preload("res://scenes/ui/visualizations/MSTVisualization.tscn")

var current_term: GlossaryManager.GlossaryTerm = null
var all_terms: Array[GlossaryManager.GlossaryTerm] = []

func _ready() -> void:
	_connect_signals()
	_initialize_filters()
	_load_all_terms()
	term_detail_panel.visible = false

func _connect_signals() -> void:
	if search_input:
		search_input.text_changed.connect(_on_search_changed)
	if category_filter:
		category_filter.item_selected.connect(_on_category_selected)
	if complexity_filter:
		complexity_filter.item_selected.connect(_on_complexity_selected)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	EventBus.glossary_term_selected.connect(_on_term_selected)

func _initialize_filters() -> void:
	# Categorías
	if category_filter:
		category_filter.clear()
		category_filter.add_item("Todas las categorías", -1)
		var categories = GlossaryManager.get_categories()
		for i in range(categories.size()):
			category_filter.add_item(categories[i], i)
	
	# Complejidad
	if complexity_filter:
		complexity_filter.clear()
		complexity_filter.add_item("Todas las complejidades", -1)
		complexity_filter.add_item("Básico", 0)
		complexity_filter.add_item("Intermedio", 1)
		complexity_filter.add_item("Avanzado", 2)

func _load_all_terms() -> void:
	all_terms = GlossaryManager.get_all_terms()
	_display_terms(all_terms)

func _display_terms(terms: Array[GlossaryManager.GlossaryTerm]) -> void:
	# Limpiar lista actual
	for child in terms_list.get_children():
		child.queue_free()
	
	if terms.is_empty():
		if no_results_label:
			no_results_label.visible = true
		return
	
	if no_results_label:
		no_results_label.visible = false
	
	# Ordenar por nombre
	terms.sort_custom(func(a, b): return a.name < b.name)
	
	# Crear entradas
	for term in terms:
		var entry = TERM_ENTRY.instantiate()
		terms_list.add_child(entry)
		entry.setup(term)
		entry.pressed.connect(_on_term_entry_clicked.bind(term))

func _on_term_entry_clicked(term: GlossaryManager.GlossaryTerm) -> void:
	_show_term_details(term)

func _show_term_details(term: GlossaryManager.GlossaryTerm) -> void:
	current_term = term
	
	if term_title:
		term_title.text = term.name
	
	if term_category_label:
		term_category_label.text = "Categoría: " + term.category
	
	if term_complexity_label:
		term_complexity_label.text = "Nivel: " + term.complexity
		match term.complexity:
			"Básico":
				term_complexity_label.modulate = Color(0.4, 0.85, 0.5)
			"Intermedio":
				term_complexity_label.modulate = Color(1.0, 0.8, 0.2)
			"Avanzado":
				term_complexity_label.modulate = Color(0.85, 0.3, 0.3)
	
	if term_description:
		term_description.text = term.full_description
	
	_display_related_terms(term)
	_display_external_links(term)
	_display_missions(term)
	_display_visualization(term)
	
	term_detail_panel.visible = true

func _display_related_terms(term: GlossaryManager.GlossaryTerm) -> void:
	# Limpiar
	for child in related_terms_container.get_children():
		if child.name != "RelatedTermsTitle":
			child.queue_free()
	
	var related = GlossaryManager.get_related_terms(term.id)
	if related.is_empty():
		var label = Label.new()
		label.text = "No hay términos relacionados"
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		related_terms_container.add_child(label)
		return
	
	for related_term in related:
		var button = Button.new()
		button.text = related_term.name
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_show_term_details.bind(related_term))
		related_terms_container.add_child(button)

func _display_external_links(term: GlossaryManager.GlossaryTerm) -> void:
	# Limpiar
	for child in external_links_container.get_children():
		if child.name != "LinksTitle":
			child.queue_free()
	
	if term.external_links.is_empty():
		var label = Label.new()
		label.text = "No hay enlaces externos"
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		external_links_container.add_child(label)
		return
	
	for link_data in term.external_links:
		var link_btn = LINK_BUTTON.instantiate() if LINK_BUTTON else Button.new()
		external_links_container.add_child(link_btn)
		if link_btn.has_method("setup"):
			link_btn.setup(link_data.title, link_data.url)
		else:
			link_btn.text = link_data.title + " 🔗"
			link_btn.pressed.connect(func(): OS.shell_open(link_data.url))

func _display_missions(term: GlossaryManager.GlossaryTerm) -> void:
	# Limpiar
	for child in missions_container.get_children():
		if child.name != "MissionsTitle":
			child.queue_free()
	
	if term.used_in_missions.is_empty():
		var label = Label.new()
		label.text = "No se usa en misiones específicas"
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		missions_container.add_child(label)
		return
	
	for mission_id in term.used_in_missions:
		var label = Label.new()
		var mission_name = mission_id.replace("Mission_", "Misión ")
		label.text = "• " + mission_name
		missions_container.add_child(label)

func _display_visualization(term: GlossaryManager.GlossaryTerm) -> void:
	# Limpiar visualización anterior
	for child in visualization_container.get_children():
		child.queue_free()
	
	match term.visualization_type:
		"animation":
			_create_animation_visualization(term)
		"graph":
			_create_graph_visualization(term)
		"diagram":
			_create_diagram_visualization(term)
		_:
			var label = Label.new()
			label.text = "Sin visualización disponible"
			label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			visualization_container.add_child(label)

func _create_animation_visualization(term: GlossaryManager.GlossaryTerm) -> void:
	var viz_scene: PackedScene = null
	
	# Seleccionar la visualización apropiada según el término
	match term.id:
		"bfs":
			viz_scene = BFS_VIZ
		"dfs":
			viz_scene = DFS_VIZ
		"dijkstra":
			viz_scene = DIJKSTRA_VIZ
		"kruskal", "prim", "mst":
			viz_scene = MST_VIZ
		"ford_fulkerson", "edmonds_karp":
			viz_scene = MST_VIZ  # Placeholder, usar MST por ahora
	
	if viz_scene:
		var viz_instance = viz_scene.instantiate()
		viz_instance.custom_minimum_size = Vector2(400, 350)
		visualization_container.add_child(viz_instance)
	else:
		var label = Label.new()
		label.text = "Visualización de " + term.name + " próximamente"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		visualization_container.add_child(label)

func _create_graph_visualization(term: GlossaryManager.GlossaryTerm) -> void:
	var viz_scene: PackedScene = null
	
	# Usar visualizaciones para términos relacionados con grafos
	match term.id:
		"mst", "kruskal", "prim":
			viz_scene = MST_VIZ
		"dijkstra", "shortest_path":
			viz_scene = DIJKSTRA_VIZ
		"max_flow", "ford_fulkerson", "edmonds_karp":
			viz_scene = MST_VIZ  # Placeholder
		_:
			# Visualización genérica de grafo
			viz_scene = BFS_VIZ
	
	if viz_scene:
		var viz_instance = viz_scene.instantiate()
		viz_instance.custom_minimum_size = Vector2(400, 350)
		visualization_container.add_child(viz_instance)
	else:
		var label = Label.new()
		label.text = "Visualización de grafo: " + term.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		visualization_container.add_child(label)

func _create_diagram_visualization(term: GlossaryManager.GlossaryTerm) -> void:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 300)
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Diagrama: " + term.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(margin)
	
	var diagram_canvas = Control.new()
	diagram_canvas.custom_minimum_size = Vector2(360, 220)
	margin.add_child(diagram_canvas)
	
	# Crear diagrama conceptual según el término
	match term.id:
		"queue":
			_draw_queue_diagram(diagram_canvas)
		"stack":
			_draw_stack_diagram(diagram_canvas)
		"priority_queue":
			_draw_priority_queue_diagram(diagram_canvas)
		"union_find":
			_draw_union_find_diagram(diagram_canvas)
		"greedy":
			_draw_greedy_diagram(diagram_canvas)
		"complexity":
			_draw_complexity_diagram(diagram_canvas)
		"graph":
			var viz_instance = BFS_VIZ.instantiate()
			viz_instance.custom_minimum_size = Vector2(400, 350)
			visualization_container.add_child(viz_instance)
			panel.queue_free()
			return
		_:
			var label = Label.new()
			label.text = "Diagrama conceptual de " + term.name
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			diagram_canvas.add_child(label)
	
	visualization_container.add_child(panel)

func _draw_queue_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var y = 110
		var x_start = 30
		var box_width = 60
		var box_height = 40
		
		# Dibujar cajas de la cola
		for i in range(5):
			var x = x_start + i * (box_width + 10)
			canvas.draw_rect(Rect2(x, y, box_width, box_height), Color(0.3, 0.5, 0.7), false, 2.0)
			
			if i < 3:
				var font = ThemeDB.fallback_font
				var text = str(10 + i * 5)
				canvas.draw_string(font, Vector2(x + 20, y + 25), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
		
		# Flechas FIFO
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x_start - 20, y - 20), "IN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x_start + 5 * (box_width + 10), y + 25), "OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
	)
	canvas.queue_redraw()

func _draw_stack_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var x = 150
		var y_start = 180
		var box_width = 80
		var box_height = 35
		
		# Dibujar cajas de la pila
		for i in range(4):
			var y = y_start - i * (box_height + 5)
			canvas.draw_rect(Rect2(x, y, box_width, box_height), Color(0.5, 0.3, 0.6), false, 2.0)
			
			if i < 3:
				var font = ThemeDB.fallback_font
				var text = ["A", "B", "C"][i]
				canvas.draw_string(font, Vector2(x + 35, y + 22), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
		
		# Indicador TOP
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x + box_width + 10, y_start - 2 * (box_height + 5) + 20), "← TOP", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.YELLOW)
	)
	canvas.queue_redraw()

func _draw_priority_queue_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var positions = [
			Vector2(180, 50),
			Vector2(120, 120), Vector2(240, 120),
			Vector2(80, 180), Vector2(160, 180)
		]
		var values = [1, 3, 5, 7, 9]
		
		# Dibujar árbol binario (min-heap)
		for i in range(positions.size() - 1):
			if i * 2 + 1 < positions.size():
				canvas.draw_line(positions[i], positions[i * 2 + 1], Color(0.4, 0.4, 0.5), 2.0)
			if i * 2 + 2 < positions.size():
				canvas.draw_line(positions[i], positions[i * 2 + 2], Color(0.4, 0.4, 0.5), 2.0)
		
		for i in range(positions.size()):
			canvas.draw_circle(positions[i], 20, Color(0.6, 0.4, 0.2))
			canvas.draw_circle(positions[i], 20, Color.WHITE, false, 2.0)
			var font = ThemeDB.fallback_font
			var text = str(values[i])
			canvas.draw_string(font, positions[i] - Vector2(5, -5), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)
	)
	canvas.queue_redraw()

func _draw_union_find_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var sets = [[Vector2(60, 100), Vector2(60, 160)], [Vector2(180, 100), Vector2(180, 160), Vector2(240, 160)], [Vector2(320, 130)]]
		
		for set_group in sets:
			for i in range(set_group.size()):
				var pos = set_group[i]
				canvas.draw_circle(pos, 18, Color(0.3, 0.6, 0.5))
				canvas.draw_circle(pos, 18, Color.WHITE, false, 2.0)
				
				if i > 0:
					canvas.draw_line(set_group[0], pos, Color.YELLOW, 2.0)
		
		canvas.draw_string(ThemeDB.fallback_font, Vector2(10, 30), "Conjuntos Disjuntos", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	)
	canvas.queue_redraw()

func _draw_greedy_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var y = 100
		for i in range(4):
			var x = 40 + i * 90
			var height = 40 + i * 20
			var color = Color(0.3 + i * 0.15, 0.7 - i * 0.1, 0.3)
			canvas.draw_rect(Rect2(x, y + (80 - height), 60, height), color, true)
			canvas.draw_rect(Rect2(x, y + (80 - height), 60, height), Color.WHITE, false, 2.0)
			
			if i == 0:
				canvas.draw_string(ThemeDB.fallback_font, Vector2(x + 15, y - 10), "↓", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.GREEN)
		
		canvas.draw_string(ThemeDB.fallback_font, Vector2(20, 200), "Siempre elige la mejor opción local", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)
	)
	canvas.queue_redraw()

func _draw_complexity_diagram(canvas: Control) -> void:
	canvas.draw.connect(func():
		var origin = Vector2(30, 200)
		var width = 320
		var height = 150
		
		# Ejes
		canvas.draw_line(origin, origin + Vector2(width, 0), Color.WHITE, 2.0)
		canvas.draw_line(origin, origin - Vector2(0, height), Color.WHITE, 2.0)
		
		# Curvas de complejidad
		var colors = [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED]
		var labels = ["O(1)", "O(log n)", "O(n)", "O(n²)"]
		
		for curve_idx in range(4):
			var points: PackedVector2Array = []
			for x in range(0, width, 5):
				var n = x / float(width)
				var y = 0.0
				match curve_idx:
					0: y = 10
					1: y = log(max(n, 0.01)) * 30 + 50
					2: y = n * 100
					3: y = n * n * 150
				points.append(origin + Vector2(x, -min(y, height)))
			
			if points.size() > 1:
				canvas.draw_polyline(points, colors[curve_idx], 2.0)
				if points.size() > 10:
					canvas.draw_string(ThemeDB.fallback_font, points[points.size() - 1] + Vector2(5, 0), labels[curve_idx], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, colors[curve_idx])
		
		canvas.draw_string(ThemeDB.fallback_font, Vector2(origin.x + width / 2.0, origin.y + 20), "n", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		canvas.draw_string(ThemeDB.fallback_font, Vector2(origin.x - 25, origin.y - height / 2.0), "t", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	)
	canvas.queue_redraw()

func _on_search_changed(_new_text: String) -> void:
	_apply_filters()

func _on_category_selected(_index: int) -> void:
	_apply_filters()

func _on_complexity_selected(_index: int) -> void:
	_apply_filters()

func _apply_filters() -> void:
	var filtered_terms: Array[GlossaryManager.GlossaryTerm] = []
	
	# Obtener texto de búsqueda
	var search_text = search_input.text.strip_edges().to_lower() if search_input else ""
	
	# Obtener filtros
	var selected_category = ""
	if category_filter and category_filter.selected > 0:
		selected_category = category_filter.get_item_text(category_filter.selected)
	
	var selected_complexity = ""
	if complexity_filter and complexity_filter.selected > 0:
		selected_complexity = complexity_filter.get_item_text(complexity_filter.selected)
	
	# Aplicar filtros
	for term in all_terms:
		var matches = true
		
		# Filtro de búsqueda
		if search_text != "":
			if not (term.name.to_lower().contains(search_text) or
					term.short_description.to_lower().contains(search_text) or
					term.full_description.to_lower().contains(search_text)):
				matches = false
		
		# Filtro de categoría
		if selected_category != "" and term.category != selected_category:
			matches = false
		
		# Filtro de complejidad
		if selected_complexity != "" and term.complexity != selected_complexity:
			matches = false
		
		if matches:
			filtered_terms.append(term)
	
	_display_terms(filtered_terms)

func _on_back_pressed() -> void:
	if term_detail_panel.visible:
		term_detail_panel.visible = false
		current_term = null
	else:
		SceneManager.change_to("res://scenes/MainMenu.tscn")


func _on_term_selected(term_id: String) -> void:
	var term = GlossaryManager.get_term(term_id)
	if term:
		_show_term_details(term)
