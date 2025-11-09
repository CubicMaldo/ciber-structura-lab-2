extends Node2D
## MainMenu controller script - attaches to `scenes/MainMenu.tscn`
## Responsibilities: wire UI buttons to GameManager/SceneManager

func _ready() -> void:
	if has_node("UI/StartButton"):
		$"UI/StartButton".pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	# go to mission selection
	if Engine.has_singleton("SceneManager"):
		var sm = Engine.get_singleton("SceneManager")
		if sm and sm.has_method("change_to"):
			sm.change_to("res://scenes/MissionSelect.tscn")
