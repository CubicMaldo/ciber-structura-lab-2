extends Node2D
## MainMenu controller script - attaches to `scenes/MainMenu.tscn`
## Responsibilities: wire UI buttons to GameManager/SceneManager


func _on_start_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")
