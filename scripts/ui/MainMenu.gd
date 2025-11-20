extends Node2D
## Controlador del menú principal; enlaza los botones con GameManager/SceneManager.


func _ready() -> void:
	# Verificar si es la primera vez que se abre el juego
	if SessionManager.is_first_launch():
		_show_intro_cutscene()


func _show_intro_cutscene() -> void:
	var cutscene = preload("res://scenes/ui/Cutscene.tscn").instantiate()
	add_child(cutscene)
	cutscene.show_story("intro")
	cutscene.cutscene_finished.connect(func():
		SessionManager.mark_intro_seen()
	)

func _on_start_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_achievements_pressed() -> void:
	SceneManager.change_to("res://scenes/AchievementsHub.tscn")


func _on_glossary_pressed() -> void:
	SceneManager.change_to("res://scenes/Glossary.tscn")


func _on_statistics_pressed() -> void:
	var stats_scene = preload("res://scenes/ui/StatisticsPanel.tscn")
	var stats_panel = stats_scene.instantiate()
	
	# Crear un CanvasLayer para que aparezca encima de todo
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	# Agregar el panel al CanvasLayer
	canvas_layer.add_child(stats_panel)
	
	# Centrar el panel después de que se agregue al árbol
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	stats_panel.position = (viewport_size - stats_panel.size) / 2
	
	# Cuando se cierra, eliminar tanto el panel como el canvas layer
	stats_panel.closed.connect(func():
		canvas_layer.queue_free()
	)
