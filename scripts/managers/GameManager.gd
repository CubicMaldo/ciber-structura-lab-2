extends Node
## GameManager (autoload "GameManager")
## Responsibilities:
## - Hold global state (current mission, player progress)
## - Central flow: menu -> mission -> result
## NOTE: Register this script as an AutoLoad (singleton) named "GameManager" in Project Settings.

var current_mission: String = ""

func start_mission(mission_id: String) -> void:
    current_mission = mission_id
    # Use SceneManager autoload by fetching it from the root (avoid direct identifier)
    if Engine.has_singleton("SceneManager"):
        var sm = Engine.get_singleton("SceneManager")
        if sm and sm.has_method("change_to_mission"):
            sm.change_to_mission(mission_id)
    # Publish mission started event
    if Engine.has_singleton("EventBus"):
        var eb = Engine.get_singleton("EventBus")
        if eb and eb.has_method("publish"):
            eb.publish("mission_started", {"id": mission_id})

func finish_mission(result: Dictionary) -> void:
    # placeholder: record result, show summary, return to mission select
    print("Mission finished:", result)
    if Engine.has_singleton("SceneManager"):
        var sm = Engine.get_singleton("SceneManager")
        if sm and sm.has_method("change_to"):
            sm.change_to("res://scenes/MissionSelect.tscn")
    # Publish mission finished event
    if Engine.has_singleton("EventBus"):
        var eb2 = Engine.get_singleton("EventBus")
        if eb2 and eb2.has_method("publish"):
            eb2.publish("mission_finished", result)
