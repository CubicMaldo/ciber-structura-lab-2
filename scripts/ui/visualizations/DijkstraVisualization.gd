extends Control
## DijkstraVisualization - Visualización animada del algoritmo de Dijkstra

@onready var canvas: Control = $Canvas
@onready var play_button: Button = $Controls/PlayButton
@onready var reset_button: Button = $Controls/ResetButton
@onready var speed_slider: HSlider = $Controls/SpeedSlider

const NODE_RADIUS := 25.0

var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var is_animating := false
var animation_timer := 0.0
var distances: Dictionary = {}
var visited: Array = []
var current_node := -1

func _ready() -> void:
	_setup_weighted_graph()
	_connect_signals()
	queue_redraw()

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	canvas.draw.connect(_on_canvas_draw)

func _setup_weighted_graph() -> void:
	nodes = [
		{"id": 0, "pos": Vector2(100, 150), "state": "unvisited"},
		{"id": 1, "pos": Vector2(200, 100), "state": "unvisited"},
		{"id": 2, "pos": Vector2(200, 200), "state": "unvisited"},
		{"id": 3, "pos": Vector2(300, 150), "state": "unvisited"}
	]
	
	edges = [
		{"from": 0, "to": 1, "weight": 4},
		{"from": 0, "to": 2, "weight": 2},
		{"from": 1, "to": 3, "weight": 3},
		{"from": 2, "to": 1, "weight": 1},
		{"from": 2, "to": 3, "weight": 5}
	]
	
	for i in nodes.size():
		distances[i] = INF if i > 0 else 0.0
	
	current_node = 0
	visited = []

func _process(delta: float) -> void:
	if is_animating:
		animation_timer += delta
		var speed = speed_slider.value if speed_slider else 1.0
		if animation_timer >= (1.0 / speed):
			animation_timer = 0.0
			_advance_dijkstra_step()
			canvas.queue_redraw()

func _advance_dijkstra_step() -> void:
	if current_node == -1:
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
		return
	
	visited.append(current_node)
	nodes[current_node].state = "visited"
	
	# Actualizar distancias de vecinos
	for edge in edges:
		if edge.from == current_node:
			var neighbor = edge.to
			if neighbor not in visited:
				var new_dist = distances[current_node] + edge.weight
				if new_dist < distances[neighbor]:
					distances[neighbor] = new_dist
	
	# Encontrar siguiente nodo no visitado con menor distancia
	var min_dist = INF
	current_node = -1
	for i in nodes.size():
		if i not in visited and distances[i] < min_dist:
			min_dist = distances[i]
			current_node = i
	
	if current_node != -1:
		nodes[current_node].state = "current"

func _on_canvas_draw() -> void:
	for edge in edges:
		var from_pos = nodes[edge.from].pos
		var to_pos = nodes[edge.to].pos
		canvas.draw_line(from_pos, to_pos, Color(0.3, 0.3, 0.4), 2.0)
		
		# Dibujar peso de la arista
		var mid_pos = (from_pos + to_pos) / 2
		var font = ThemeDB.fallback_font
		var weight_text = str(edge.weight)
		canvas.draw_string(font, mid_pos, weight_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.YELLOW)
	
	for node in nodes:
		var color := Color.WHITE
		match node.state:
			"unvisited":
				color = Color(0.3, 0.3, 0.4)
			"current":
				color = Color(0.8, 0.6, 0.2)
			"visited":
				color = Color(0.3, 0.7, 0.3)
		
		canvas.draw_circle(node.pos, NODE_RADIUS, color)
		canvas.draw_circle(node.pos, NODE_RADIUS, Color.WHITE, false, 2.0)
		
		var font = ThemeDB.fallback_font
		var text = str(node.id)
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		canvas.draw_string(font, node.pos - text_size / 2, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.BLACK)
		
		# Mostrar distancia
		var dist_text = str(distances[node.id]) if distances[node.id] < INF else "∞"
		canvas.draw_string(font, node.pos + Vector2(-10, 40), dist_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.CYAN)

func _on_play_pressed() -> void:
	if is_animating:
		is_animating = false
		if play_button:
			play_button.text = "▶ Reproducir"
	else:
		if current_node == -1 and visited.size() == nodes.size():
			_on_reset_pressed()
		is_animating = true
		if play_button:
			play_button.text = "⏸ Pausar"

func _on_reset_pressed() -> void:
	is_animating = false
	animation_timer = 0.0
	visited = []
	current_node = 0
	
	for i in nodes.size():
		nodes[i].state = "unvisited"
		distances[i] = INF if i > 0 else 0.0
	
	nodes[0].state = "current"
	
	if play_button:
		play_button.text = "▶ Reproducir"
	
	canvas.queue_redraw()
