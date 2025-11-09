extends Node
## SceneManager (autoload "SceneManager")
## Lightweight scene switching helper used by GameManager and UI controllers.

func change_to(path: String) -> void:
    if path == "":
        return
    var err = get_tree().change_scene_to_file(path)
    if err != OK:
        push_error("Failed to change scene to %s (err=%s)" % [path, str(err)])
    # publish scene_changed
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        if eb and eb.has_method("publish"):
            eb.publish("scene_changed", {"path": path})

func change_to_mission(mission_id: String) -> void:
    # map mission id to a scene path (convention: scenes/missions/Mission_<n>.tscn)
    var path = "res://scenes/missions/%s.tscn" % mission_id
    change_to(path)
    # publish mission_change request as well
    if Engine.has_singleton("EventBus"):
        var eb2 = Engine.get_singleton("EventBus")
        if eb2 and eb2.has_method("publish"):
            eb2.publish("mission_change_requested", {"id": mission_id, "path": path})
