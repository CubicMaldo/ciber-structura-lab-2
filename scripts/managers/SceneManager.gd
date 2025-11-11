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
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        eb.scene_changed.emit(path)

func change_to_mission(mission_id: String) -> void:
    # map mission id to a scene path (convention: scenes/missions/Mission_<n>.tscn)
    var path = "res://scenes/missions/%s.tscn" % mission_id
    change_to(path)
    # Emit mission change request signal with typed parameters
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        eb.mission_change_requested.emit(mission_id, path)
