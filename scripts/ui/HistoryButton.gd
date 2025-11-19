extends Node
## Botón para abrir el panel de historial de notificaciones
## Coloca este script en un botón en tu HUD o menú principal

@export var history_panel_scene: PackedScene = preload("res://scenes/ui/NotificationHistoryPanel.tscn")

var current_panel: Control = null


func _ready() -> void:
	var button := get_parent() if get_parent() is Button else null
	if button:
		button.pressed.connect(_on_button_pressed)
	elif self.get_parent() and self.get_parent().has_signal("pressed"):
		self.get_parent().pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	# Si ya hay un panel abierto, cerrarlo
	if current_panel and is_instance_valid(current_panel):
		current_panel.queue_free()
		current_panel = null
		return
	
	# Crear nuevo panel
	if not history_panel_scene:
		push_warning("HistoryButton: No se ha asignado la escena del panel de historial")
		return
	
	current_panel = history_panel_scene.instantiate()
	
	# Añadir al CanvasLayer o a la escena raíz
	var root := get_tree().root
	if root:
		var current_scene := root.get_child(root.get_child_count() - 1)
		
		# Buscar o crear CanvasLayer
		var canvas_layer: CanvasLayer = null
		for child in current_scene.get_children():
			if child is CanvasLayer and child.name == "UILayer":
				canvas_layer = child
				break
		
		if not canvas_layer:
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "UILayer"
			canvas_layer.layer = 50
			current_scene.add_child(canvas_layer)
		
		canvas_layer.add_child(current_panel)


func _exit_tree() -> void:
	if current_panel and is_instance_valid(current_panel):
		current_panel.queue_free()
