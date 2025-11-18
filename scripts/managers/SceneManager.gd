extends Node
## SceneManager (autoload "SceneManager")
## Auxiliar ligero para cambiar escenas; separado de la lógica de juego/UI.

func change_to(path: String) -> void:
	if path == "":
		return
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to %s (err=%s)" % [path, str(err)])
	# Notificar cambio de escena via EventBus (razón: sincronizar UI/telemetría)
	EventBus.scene_changed.emit(path)

func change_to_mission(mission_id: String) -> void:
	# Convención: convertir mission_id a ruta de escena en scenes/missions
	var path = "res://scenes/missions/%s.tscn" % mission_id
	change_to(path)
	EventBus.mission_change_requested.emit(mission_id, path)

func change_to_packed(packed_scene: PackedScene) -> void:
	# Permite cambiar usando un PackedScene (útil cuando ya se tiene la resource)
	if packed_scene == null:
		return
	var err = get_tree().change_scene_to(packed_scene)
	if err != OK:
		var rpath = "(unknown)"
		if packed_scene is Resource and packed_scene.resource_path != "":
			rpath = packed_scene.resource_path
		push_error("Failed to change scene to PackedScene %s (err=%s)" % [rpath, str(err)])
	var emit_path = ""
	if packed_scene is Resource and packed_scene.resource_path != "":
		emit_path = packed_scene.resource_path
	EventBus.scene_changed.emit(emit_path)
