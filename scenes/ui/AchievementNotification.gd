extends PanelContainer
## AchievementNotification
## UI component para mostrar notificaciones de logros con animaciones

signal dismissed

@export var auto_dismiss_time: float = 5.0
@export var show_close_button: bool = true

var notification_data: Dictionary = {}
var dismiss_timer: Timer = null

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var icon_texture: TextureRect = %IconTexture
@onready var category_label: Label = %CategoryLabel
@onready var close_button: Button = %CloseButton
@onready var shine_effect: ColorRect = %ShineEffect


func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.visible = show_close_button
	
	# Configurar timer de auto-cierre
	if auto_dismiss_time > 0:
		dismiss_timer = Timer.new()
		dismiss_timer.wait_time = auto_dismiss_time
		dismiss_timer.one_shot = true
		dismiss_timer.timeout.connect(_on_dismiss_timeout)
		add_child(dismiss_timer)
		dismiss_timer.start()


func setup(data: Dictionary) -> void:
	notification_data = data
	
	if title_label:
		title_label.text = data.get("title", "Logro Desbloqueado")
	
	if description_label:
		description_label.text = data.get("description", "")
	
	if category_label:
		var category: String = data.get("category", "")
		category_label.text = _format_category(category)
		category_label.modulate = _get_category_color(category)
	
	if icon_texture:
		var icon_path: String = data.get("icon", "")
		if icon_path != "" and FileAccess.file_exists(icon_path):
			icon_texture.texture = load(icon_path)
		else:
			# Usar icono por defecto
			icon_texture.visible = false
	
	# Aplicar colores según categoría
	_apply_category_styling(data.get("category", "default"))
	
	# Animar efecto de brillo
	if shine_effect:
		_animate_shine_effect()


func _format_category(category: String) -> String:
	var formatted := {
		"misiones": "MISIÓN",
		"precisión": "PRECISIÓN",
		"eficiencia": "EFICIENCIA",
		"progresion": "PROGRESIÓN",
		"fases": "FASE",
		"secretos": "** SECRETO **",
		"default": "LOGRO"
	}
	return formatted.get(category, category.to_upper())


func _get_category_color(category: String) -> Color:
	var colors := {
		"misiones": Color(0.2, 0.7, 1.0),      # Azul
		"precisión": Color(1.0, 0.7, 0.2),     # Dorado
		"eficiencia": Color(0.3, 1.0, 0.3),    # Verde
		"progresion": Color(0.8, 0.3, 1.0),    # Púrpura
		"fases": Color(1.0, 0.5, 0.2),         # Naranja
		"secretos": Color(1.0, 0.2, 0.5),      # Rosa
		"default": Color(0.7, 0.7, 0.7)        # Gris
	}
	return colors.get(category, colors["default"])


func _apply_category_styling(category: String) -> void:
	var category_color := _get_category_color(category)
	
	# Aplicar borde de color según categoría
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_width_left = 4
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = category_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	
	add_theme_stylebox_override("panel", style)


func _animate_shine_effect() -> void:
	if not shine_effect:
		return
	
	shine_effect.modulate = Color(1, 1, 1, 0)
	shine_effect.visible = true
	
	var tween := create_tween()
	tween.set_loops(2)
	tween.tween_property(shine_effect, "modulate", Color(1, 1, 1, 0.3), 0.3)
	tween.tween_property(shine_effect, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.finished.connect(func(): shine_effect.visible = false)


func _on_close_pressed() -> void:
	_dismiss()


func _on_dismiss_timeout() -> void:
	_dismiss()


func _dismiss() -> void:
	if dismiss_timer and is_instance_valid(dismiss_timer):
		dismiss_timer.stop()
	dismissed.emit()


func _gui_input(event: InputEvent) -> void:
	# Permitir cerrar con clic
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_dismiss()
