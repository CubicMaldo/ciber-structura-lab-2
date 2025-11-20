extends CanvasLayer
## Cutscene - Sistema de visualización de historia con múltiples páginas

signal cutscene_finished()

@onready var background: ColorRect = $Background
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var story_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/StoryLabel
@onready var page_indicator: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/PageIndicator
@onready var next_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonContainer/NextButton
@onready var skip_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonContainer/SkipButton

var current_story: Dictionary = {}
var current_page: int = 0
var is_typing: bool = false
var typing_speed: float = 0.02 # Segundos por carácter

func _ready() -> void:
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	
	# Animación de entrada
	background.modulate.a = 0
	panel.modulate.a = 0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 0.85, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.5)

func show_story(story_id: String) -> void:
	current_story = SessionManager.get_story_text(story_id)
	current_page = 0
	
	if current_story.is_empty():
		_finish_cutscene()
		return
	
	title_label.text = current_story.get("title", "")
	_show_current_page()

func _show_current_page() -> void:
	var pages = current_story.get("pages", [])
	
	if current_page >= pages.size():
		_finish_cutscene()
		return
	
	# Actualizar indicador de página
	if pages.size() > 1:
		page_indicator.text = "Página %d / %d" % [current_page + 1, pages.size()]
		page_indicator.visible = true
	else:
		page_indicator.visible = false
	
	# Actualizar botón
	if current_page == pages.size() - 1:
		next_button.text = "Continuar ▶"
	else:
		next_button.text = "Siguiente ▶"
	
	# Mostrar texto con efecto de escritura
	_type_text(pages[current_page])

func _type_text(text: String) -> void:
	is_typing = true
	next_button.disabled = true
	story_label.text = ""
	
	var char_count = text.length()
	var tween = create_tween()
	
	for i in range(char_count + 1):
		var partial_text = text.substr(0, i)
		tween.tween_callback(func(): story_label.text = partial_text)
		tween.tween_interval(typing_speed)
	
	tween.finished.connect(func():
		is_typing = false
		next_button.disabled = false
	)

func _on_next_pressed() -> void:
	if is_typing:
		# Saltar animación de escritura
		var pages = current_story.get("pages", [])
		if current_page < pages.size():
			story_label.text = pages[current_page]
			is_typing = false
			next_button.disabled = false
		return
	
	current_page += 1
	_show_current_page()

func _on_skip_pressed() -> void:
	_finish_cutscene()

func _finish_cutscene() -> void:
	# Animación de salida
	var tween = create_tween().set_parallel(true)
	tween.tween_property(background, "modulate:a", 0.0, 0.3)
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	cutscene_finished.emit()
	queue_free()
