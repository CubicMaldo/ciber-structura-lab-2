extends Control
## NotificationHistoryPanel
## Panel para mostrar el historial de notificaciones recientes

signal history_cleared

@onready var history_container: VBoxContainer = %HistoryContainer
@onready var clear_button: Button = %ClearButton
@onready var empty_label: Label = %EmptyLabel
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	refresh_history()


func refresh_history() -> void:
	if not history_container:
		return
	
	# Limpiar contenedor
	for child in history_container.get_children():
		child.queue_free()
	
	# Obtener historial
	var history := NotificationManager.get_notification_history()
	
	if history.is_empty():
		if empty_label:
			empty_label.visible = true
		if clear_button:
			clear_button.disabled = true
		return
	
	if empty_label:
		empty_label.visible = false
	if clear_button:
		clear_button.disabled = false
	
	# Crear entradas para cada notificación
	for notification_data in history:
		var entry := _create_history_entry(notification_data)
		history_container.add_child(entry)


func _create_history_entry(data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	
	# Estilo del panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style.border_width_left = 2
	style.border_color = _get_category_color(data.get("category", "default"))
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	panel.add_child(hbox)
	
	# Icono
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_path: String = data.get("icon", "")
	if icon_path != "" and FileAccess.file_exists(icon_path):
		icon.texture = load(icon_path)
	hbox.add_child(icon)
	
	# Contenido de texto
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)
	
	# Título y categoría en la misma línea
	var header_hbox := HBoxContainer.new()
	vbox.add_child(header_hbox)
	
	var title := Label.new()
	title.text = data.get("title", "Sin título")
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title)
	
	var category := Label.new()
	category.text = _format_category(data.get("category", "default"))
	category.add_theme_font_size_override("font_size", 10)
	category.modulate = _get_category_color(data.get("category", "default"))
	header_hbox.add_child(category)
	
	# Descripción
	var desc := Label.new()
	desc.text = data.get("description", "")
	desc.add_theme_font_size_override("font_size", 11)
	desc.modulate = Color(0.8, 0.8, 0.8)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	# Timestamp
	var timestamp := Label.new()
	timestamp.text = _format_timestamp(data.get("timestamp", 0))
	timestamp.add_theme_font_size_override("font_size", 10)
	timestamp.modulate = Color(0.6, 0.6, 0.6)
	vbox.add_child(timestamp)
	
	return panel


func _format_category(category: String) -> String:
	var formatted := {
		"misiones": "MISIÓN",
		"precisión": "PRECISIÓN",
		"eficiencia": "EFICIENCIA",
		"progresion": "PROGRESIÓN",
		"fases": "FASE",
		"secretos": "SECRETO",
		"default": "LOGRO"
	}
	return formatted.get(category, category.to_upper())


func _get_category_color(category: String) -> Color:
	var colors := {
		"misiones": Color(0.2, 0.7, 1.0),
		"precisión": Color(1.0, 0.7, 0.2),
		"eficiencia": Color(0.3, 1.0, 0.3),
		"progresion": Color(0.8, 0.3, 1.0),
		"fases": Color(1.0, 0.5, 0.2),
		"secretos": Color(1.0, 0.2, 0.5),
		"default": Color(0.7, 0.7, 0.7)
	}
	return colors.get(category, colors["default"])


func _format_timestamp(unix_time: float) -> String:
	if unix_time == 0:
		return "Fecha desconocida"
	
	var current_time := Time.get_unix_time_from_system()
	var diff := int(current_time - unix_time)
	
	if diff < 60:
		return "Hace un momento"
	elif diff < 3600:
		var minutes := diff / 60
		return "Hace %d minuto%s" % [minutes, "s" if minutes > 1 else ""]
	elif diff < 86400:
		var hours := diff / 3600
		return "Hace %d hora%s" % [hours, "s" if hours > 1 else ""]
	else:
		var days := diff / 86400
		return "Hace %d día%s" % [days, "s" if days > 1 else ""]


func _on_clear_pressed() -> void:
	# Confirmación antes de limpiar
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "¿Estás seguro de que quieres borrar el historial de notificaciones?"
	dialog.ok_button_text = "Borrar"
	dialog.cancel_button_text = "Cancelar"
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		NotificationManager.clear_history()
		refresh_history()
		history_cleared.emit()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.popup_centered()


func _on_close_pressed() -> void:
	queue_free()
