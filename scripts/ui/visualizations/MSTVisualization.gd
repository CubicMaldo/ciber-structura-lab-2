extends Control
## MSTVisualization - Visualización animada de MST (Kruskal)

@onready var canvas: Control = $Canvas
@onready var play_button: Button = $Controls/PlayButton
@onready var reset_button: Button = $Controls/ResetButton
@onready var speed_slider: HSlider = $Controls/SpeedSlider

const NODE_RADIUS := 25.0

var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var mst_edges: Array = []
var is_animating := false
var animation_timer := 0.0
var current_edge_index := 0
var parent: Dictionary = {}

func _ready() -> void:
	_setup_graph()
	_connect_signals()
	queue_redraw()

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	canvas.draw.connect(_on_canvas_draw)

func _setup_graph() -> void:
	nodes = [
		{"id": 0, "pos": Vector2(100, 100)},
		{"id": 1, "pos": Vector2(250, 100)},
		{"id": 2, "pos": Vector2(100, 250)},
		{"id": 3, "pos": Vector2(250, 250)}
	]
	
	edges = [
		{"from": 0, "to": 1, "weight": 4, "state": "default"},
		{"from": 0, "to": 2, "weight": 2, "state": "default"},
		{"from": 1, "to": 3, "weight": 5, "state": "default"},
		{"from": 2, "to": 3, "weight": 3, "state": "default"},
		{"from": 0, "to": 3, "weight": 7, "state": "default"},
		{"from": 1, "to": 2, "weight": 1, "state": "default"}
	]
	
	# Ordenar aristas por peso
	edges.sort_custom(func(a, b): return a.weight < b.weight)
	
	for node in nodes:
		parent[node.id] = node.id

func _process(delta: float) -> void:
	if is_animating:
		animation_timer += delta
		var speed = speed_slider.value if speed_slider else 1.0
		if animation_timer >= (1.0 / speed):
			animation_timer = 0.0
			_advance_kruskal_step()
			canvas.queue_redraw()

func _find(x: int) -> int:
	if parent[x] != x:
		parent[x] = _find(parent[x])
	return parent[x]

func _union(x: int, y: int) -> void:
	var px = _find(x)
	var py = _find(y)
	parent[px] = py

func _advance_kruskal_step() -> void:
	if current_edge_index >= edges.size():
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
		return
	
	var edge = edges[current_edge_index]
	var from_parent = _find(edge.from)
	var to_parent = _find(edge.to)
	
	if from_parent != to_parent:
		_union(edge.from, edge.to)
		edge.state = "selected"
		mst_edges.append(edge)
	else:
		edge.state = "rejected"
	
	current_edge_index += 1

func _on_canvas_draw() -> void:
	# Dibujar todas las aristas
	for edge in edges:
		var from_pos = nodes[edge.from].pos
		var to_pos = nodes[edge.to].pos
		
		var color := Color(0.3, 0.3, 0.4)
		var width := 2.0
		
		match edge.state:
			"selected":
				color = Color(0.3, 0.8, 0.3)
				width = 4.0
			"rejected":
				color = Color(0.6, 0.2, 0.2)
		
		canvas.draw_line(from_pos, to_pos, color, width)
		
		# Dibujar peso
		var mid_pos = (from_pos + to_pos) / 2
		var font = ThemeDB.fallback_font
		canvas.draw_string(font, mid_pos, str(edge.weight), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)
	
	# Dibujar nodos
	for node in nodes:
		canvas.draw_circle(node.pos, NODE_RADIUS, Color(0.4, 0.4, 0.5))
		canvas.draw_circle(node.pos, NODE_RADIUS, Color.WHITE, false, 2.0)
		
		var font = ThemeDB.fallback_font
		var text = str(node.id)
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		canvas.draw_string(font, node.pos - text_size / 2, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

func _on_play_pressed() -> void:
	if is_animating:
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
	else:
		if current_edge_index >= edges.size():
			_on_reset_pressed()
		is_animating = true
		if play_button:
			play_button.text = "⏸ Pausar"

func _on_reset_pressed() -> void:
	is_animating = false
	animation_timer = 0.0
	current_edge_index = 0
	mst_edges.clear()
	
	for edge in edges:
		edge.state = "default"
	
	for node in nodes:
		parent[node.id] = node.id
	
	if play_button:
		play_button.text = "▶ Reproducir"
	
	canvas.queue_redraw()
