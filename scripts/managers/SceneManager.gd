extends Node
## SceneManager (autoload "SceneManager")
## Lightweight scene switching helper used by GameManager and UI controllers.

func change_to(path: String) -> void:
	if path == "":
		return
	var err = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to %s (err=%s)" % [path, str(err)])
	# Emit scene changed signal with typed parameter
	EventBus.scene_changed.emit(path)

func change_to_mission(mission_id: String) -> void:
	# map mission id to a scene path (convention: scenes/missions/Mission_<n>.tscn)
	var path = "res://scenes/missions/%s.tscn" % mission_id
	change_to(path)
	# Emit mission change request signal with typed parameters
	EventBus.mission_change_requested.emit(mission_id, path)

func change_to_packed(packed_scene: PackedScene) -> void:
	# Change to a scene given a PackedScene resource.
	# Mirrors the behavior of `change_to(path)` but accepts a PackedScene.
	# Emits `EventBus.scene_changed` with the resource path if available.
	if packed_scene == null:
		return
	var err = get_tree().change_scene_to(packed_scene)
	if err != OK:
		var rpath = "(unknown)"
		if packed_scene is Resource and packed_scene.resource_path != "":
			rpath = packed_scene.resource_path
		push_error("Failed to change scene to PackedScene %s (err=%s)" % [rpath, str(err)])
	# Emit scene changed signal with typed parameter (use resource_path when available)
	var emit_path = ""
	if packed_scene is Resource and packed_scene.resource_path != "":
			emit_path = packed_scene.resource_path
	EventBus.scene_changed.emit(emit_path)
