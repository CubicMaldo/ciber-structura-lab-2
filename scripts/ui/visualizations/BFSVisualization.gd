extends Control
## BFSVisualization - Visualización animada del algoritmo BFS

@onready var canvas: Control = $Canvas
@onready var play_button: Button = $Controls/PlayButton
@onready var reset_button: Button = $Controls/ResetButton
@onready var speed_slider: HSlider = $Controls/SpeedSlider

const NODE_RADIUS := 25.0
const ANIMATION_SPEED := 1.0

var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var current_step := 0
var is_animating := false
var animation_timer := 0.0
var queue: Array = []
var visited: Array = []

func _ready() -> void:
	_setup_simple_graph()
	_connect_signals()
	queue_redraw()

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	canvas.draw.connect(_on_canvas_draw)

func _setup_simple_graph() -> void:
	# Crear un grafo simple para demostración
	nodes = [
		{"id": 0, "pos": Vector2(150, 100), "state": "unvisited"},
		{"id": 1, "pos": Vector2(100, 200), "state": "unvisited"},
		{"id": 2, "pos": Vector2(200, 200), "state": "unvisited"},
		{"id": 3, "pos": Vector2(50, 300), "state": "unvisited"},
		{"id": 4, "pos": Vector2(150, 300), "state": "unvisited"},
		{"id": 5, "pos": Vector2(250, 300), "state": "unvisited"}
	]
	
	edges = [
		{"from": 0, "to": 1},
		{"from": 0, "to": 2},
		{"from": 1, "to": 3},
		{"from": 1, "to": 4},
		{"from": 2, "to": 4},
		{"from": 2, "to": 5}
	]
	
	queue = [0]
	visited = []

func _process(delta: float) -> void:
	if is_animating:
		animation_timer += delta
		var speed = speed_slider.value if speed_slider else ANIMATION_SPEED
		if animation_timer >= (1.0 / speed):
			animation_timer = 0.0
			_advance_bfs_step()
			canvas.queue_redraw()

func _advance_bfs_step() -> void:
	if queue.is_empty():
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
		return
	
	var current = queue.pop_front()
	
	if current in visited:
		return
	
	visited.append(current)
	nodes[current].state = "visited"
	
	# Agregar vecinos a la cola
	for edge in edges:
		if edge.from == current and edge.to not in visited and edge.to not in queue:
			queue.append(edge.to)
			nodes[edge.to].state = "queued"

func _on_canvas_draw() -> void:
	# Dibujar aristas
	for edge in edges:
		var from_pos = nodes[edge.from].pos
		var to_pos = nodes[edge.to].pos
		canvas.draw_line(from_pos, to_pos, Color(0.3, 0.3, 0.4), 2.0)
	
	# Dibujar nodos
	for node in nodes:
		var color := Color.WHITE
		match node.state:
			"unvisited":
				color = Color(0.3, 0.3, 0.4)
			"queued":
				color = Color(0.8, 0.6, 0.2)
			"visited":
				color = Color(0.3, 0.7, 0.3)
		
		canvas.draw_circle(node.pos, NODE_RADIUS, color)
		canvas.draw_circle(node.pos, NODE_RADIUS, Color.WHITE, false, 2.0)
		
		# Dibujar ID del nodo
		var font = ThemeDB.fallback_font
		var font_size = 16
		var text = str(node.id)
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		canvas.draw_string(font, node.pos - text_size / 2, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.BLACK)

func _on_play_pressed() -> void:
	if is_animating:
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
	else:
		if queue.is_empty() and visited.size() == nodes.size():
			_on_reset_pressed()
		is_animating = true
		if play_button:
			play_button.text = "⏸ Pausar"

func _on_reset_pressed() -> void:
	is_animating = false
	current_step = 0
	animation_timer = 0.0
	queue = [0]
	visited = []
	
	for node in nodes:
		node.state = "unvisited"
	
	if play_button:
		play_button.text = "▶ Reproducir"
	
	canvas.queue_redraw()
