extends Node2D
## Controlador del menú principal; enlaza los botones con GameManager/SceneManager.


func _on_start_pressed() -> void:
	SceneManager.change_to("res://scenes/MissionSelect.tscn")


func _on_achievements_pressed() -> void:
	SceneManager.change_to("res://scenes/AchievementsHub.tscn")
