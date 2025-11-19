extends Node
## NotificationManager (autoload "NotificationManager")
## Sistema centralizado para mostrar notificaciones de logros con animaciones,
## sonidos y un historial persistente de logros recientes.

signal notification_shown(notification_data: Dictionary)

const MAX_HISTORY_SIZE := 20
const NOTIFICATION_SCENE_PATH := "res://scenes/ui/AchievementNotification.tscn"

## Historial de notificaciones recientes
var notification_history: Array[Dictionary] = []

## Cola de notificaciones pendientes
var notification_queue: Array[Dictionary] = []

## Notificación actualmente visible
var current_notification: Control = null

## Contenedor de notificaciones en la escena
var notification_container: Control = null

## Configuración de sonidos por categoría
var sound_config := {
	"misiones": "res://audio/sfx/achievement_mission.ogg",
	"precisión": "res://audio/sfx/achievement_precision.ogg",
	"eficiencia": "res://audio/sfx/achievement_efficiency.ogg",
	"progresion": "res://audio/sfx/achievement_progression.ogg",
	"fases": "res://audio/sfx/achievement_stage.ogg",
	"secretos": "res://audio/sfx/achievement_secret.ogg",
	"default": "res://audio/sfx/achievement_default.ogg"
}


func _ready() -> void:
	_load_history()
	# Conectar a señal de logros del AchievementManager
	if AchievementManager and AchievementManager.has_signal("achievement_unlocked"):
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


## Muestra una notificación de logro desbloqueado
func show_achievement_notification(achievement_id: String, achievement_data: Dictionary) -> void:
	var category: String = str(achievement_data.get("category", "default"))
	var title: String = str(achievement_data.get("title", "Logro Desbloqueado"))
	var description: String = str(achievement_data.get("description", ""))
	var requirement: String = str(achievement_data.get("requirement", ""))
	
	# Si hay requisito, agregarlo a la descripción
	var full_description: String = description
	if requirement != "" and requirement != description:
		full_description = "%s\n\n📋 %s" % [description, requirement]
	
	var notification_data := {
		"id": achievement_id,
		"type": "achievement",
		"title": title,
		"description": full_description,
		"category": category,
		"timestamp": Time.get_unix_time_from_system(),
		"icon": _get_category_icon(category),
		"achievement_id": achievement_id
	}
	
	_add_to_history(notification_data)
	_queue_notification(notification_data)


## Añade una notificación personalizada
func show_custom_notification(title: String, description: String, category: String = "default") -> void:
	var notification_data := {
		"id": "custom_%d" % Time.get_ticks_msec(),
		"type": "custom",
		"title": title,
		"description": description,
		"category": category,
		"timestamp": Time.get_unix_time_from_system(),
		"icon": _get_category_icon(category)
	}
	
	_queue_notification(notification_data)


## Obtiene el historial de notificaciones
func get_notification_history() -> Array[Dictionary]:
	return notification_history.duplicate()


## Limpia el historial de notificaciones
func clear_history() -> void:
	notification_history.clear()
	_save_history()


## Registra el contenedor de notificaciones de la escena actual
func register_container(container: Control) -> void:
	notification_container = container


## Desregistra el contenedor actual
func unregister_container() -> void:
	if current_notification and is_instance_valid(current_notification):
		current_notification.queue_free()
		current_notification = null
	notification_container = null


func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	# Obtener la definición completa del logro desde AchievementManager
	var definition: Dictionary = {}
	if AchievementManager and AchievementManager.has_method("get_achievement_definition"):
		definition = AchievementManager.get_achievement_definition(achievement_id)
	
	# Combinar datos de la definición con los datos del unlock
	# Priorizar la definición (que tiene title, description, etc.)
	var combined_data: Dictionary = definition.duplicate()
	for key in achievement_data.keys():
		if not combined_data.has(key) or key == "unlocked" or key == "timestamp" or key == "progress" or key == "meta":
			combined_data[key] = achievement_data[key]
	
	# Debug para verificar los datos
	print("NotificationManager: Mostrando logro '%s'" % achievement_id)
	print("  Título: %s" % combined_data.get("title", "???"))
	print("  Descripción: %s" % combined_data.get("description", "???"))
	print("  Categoría: %s" % combined_data.get("category", "???"))
	
	show_achievement_notification(achievement_id, combined_data)


func _queue_notification(data: Dictionary) -> void:
	notification_queue.append(data)
	
	if current_notification == null:
		_show_next_notification()


func _show_next_notification() -> void:
	if notification_queue.is_empty():
		return
	
	var data: Dictionary = notification_queue.pop_front()
	
	# Intentar usar el contenedor registrado o el árbol de escenas
	var container := notification_container
	if not container or not is_instance_valid(container):
		container = _find_or_create_container()
	
	if not container:
		push_warning("NotificationManager: No se pudo encontrar contenedor para notificaciones")
		return
	
	# Instanciar la escena de notificación
	if ResourceLoader.exists(NOTIFICATION_SCENE_PATH):
		var scene := load(NOTIFICATION_SCENE_PATH) as PackedScene
		if scene:
			current_notification = scene.instantiate()
			container.add_child(current_notification)
			
			# Configurar la notificación
			if current_notification.has_method("setup"):
				current_notification.setup(data)
			
			# Reproducir sonido
			_play_notification_sound(data.get("category", "default"))
			
			# Conectar señal de cierre
			if current_notification.has_signal("dismissed"):
				current_notification.dismissed.connect(_on_notification_dismissed)
			
			# Animar entrada
			_animate_notification_entry(current_notification)
			
			notification_shown.emit(data)
		else:
			push_warning("NotificationManager: No se pudo cargar la escena de notificación")
	else:
		push_warning("NotificationManager: Escena de notificación no encontrada")


func _on_notification_dismissed() -> void:
	if current_notification and is_instance_valid(current_notification):
		_animate_notification_exit(current_notification)
		await get_tree().create_timer(0.3).timeout
		current_notification.queue_free()
		current_notification = null
	
	# Mostrar siguiente notificación en cola
	if not notification_queue.is_empty():
		await get_tree().create_timer(0.2).timeout
		_show_next_notification()


func _animate_notification_entry(notif: Control) -> void:
	if not notif or not is_instance_valid(notif):
		return
	
	# Configuración inicial
	notif.modulate = Color(1, 1, 1, 0)
	notif.scale = Vector2(0.5, 0.5)
	notif.rotation = -0.1
	
	# Animación de entrada con rebote
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(notif, "modulate", Color(1, 1, 1, 1), 0.4)
	tween.tween_property(notif, "scale", Vector2(1, 1), 0.5)
	tween.tween_property(notif, "rotation", 0.0, 0.5)
	
	# Efecto de brillo
	tween.chain().tween_property(notif, "modulate", Color(1.2, 1.2, 1.2, 1), 0.2)
	tween.chain().tween_property(notif, "modulate", Color(1, 1, 1, 1), 0.2)


func _animate_notification_exit(notif: Control) -> void:
	if not notif or not is_instance_valid(notif):
		return
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(notif, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_property(notif, "scale", Vector2(0.7, 0.7), 0.3)
	tween.tween_property(notif, "position:y", notif.position.y - 50, 0.3)


func _play_notification_sound(category: String) -> void:
	var sound_path: String = sound_config.get(category, sound_config["default"])
	
	# Verificar si el archivo existe
	if not FileAccess.file_exists(sound_path):
		return
	
	var audio_stream := load(sound_path) as AudioStream
	if not audio_stream:
		return
	
	# Crear reproductor de audio temporal
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = audio_stream
	player.volume_db = -5.0
	player.play()
	
	# Eliminar cuando termine
	player.finished.connect(func(): player.queue_free())


func _get_category_icon(category: String) -> String:
	# Mapeo de categorías a iconos
	var icon_map := {
		"misiones": "res://sprites/icons/achievement_mission.png",
		"precisión": "res://sprites/icons/achievement_precision.png",
		"eficiencia": "res://sprites/icons/achievement_efficiency.png",
		"progresion": "res://sprites/icons/achievement_progression.png",
		"fases": "res://sprites/icons/achievement_stage.png",
		"secretos": "res://sprites/icons/achievement_secret.png",
		"default": "res://sprites/icons/achievement_default.png"
	}
	
	return icon_map.get(category, icon_map["default"])


func _add_to_history(data: Dictionary) -> void:
	notification_history.insert(0, data)
	
	# Limitar tamaño del historial
	while notification_history.size() > MAX_HISTORY_SIZE:
		notification_history.pop_back()
	
	_save_history()


func _find_or_create_container() -> Control:
	# Buscar en el árbol de escenas
	var root := get_tree().root
	if not root:
		return null
	
	var current_scene := root.get_child(root.get_child_count() - 1)
	if not current_scene:
		return null
	
	# Buscar un CanvasLayer existente
	var canvas_layer: CanvasLayer = null
	for child in current_scene.get_children():
		if child is CanvasLayer:
			canvas_layer = child
			break
	
	# Si no existe, crear uno
	if not canvas_layer:
		canvas_layer = CanvasLayer.new()
		canvas_layer.name = "NotificationLayer"
		canvas_layer.layer = 100
		current_scene.add_child(canvas_layer)
	
	# Buscar o crear contenedor
	var container := canvas_layer.get_node_or_null("NotificationContainer")
	if not container:
		container = Control.new()
		container.name = "NotificationContainer"
		container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		container.offset_left = -400
		container.offset_top = 20
		container.offset_right = -20
		canvas_layer.add_child(container)
	
	return container


func _save_history() -> void:
	var save_data := {
		"history": notification_history,
		"version": 1
	}
	
	var file := FileAccess.open("user://notification_history.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()


func _load_history() -> void:
	if not FileAccess.file_exists("user://notification_history.json"):
		return
	
	var file := FileAccess.open("user://notification_history.json", FileAccess.READ)
	if not file:
		return
	
	var content := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	
	var history = parsed.get("history", [])
	if typeof(history) == TYPE_ARRAY:
		notification_history = []
		for item in history:
			if typeof(item) == TYPE_DICTIONARY:
				notification_history.append(item)
