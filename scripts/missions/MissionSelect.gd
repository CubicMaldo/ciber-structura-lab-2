extends Node2D
## MissionSelect controller - populates mission list and starts missions

var missions = ["Mission_1", "Mission_2", "Mission_3", "Mission_4", "Mission_Final"]

func _ready() -> void:
	_populate()

func _populate() -> void:
	if not has_node("UI/MissionList"):
		return
	var list = $"UI/MissionList"
	for m in missions:
		var btn = Button.new()
		btn.text = m
		btn.pressed.connect(func(m_id=m): _on_mission_selected(m_id))
		list.add_child(btn)

func _on_mission_selected(mission_id: String) -> void:
	# Emit mission selected signal with typed parameter
	EventBus.mission_selected.emit(mission_id)
	GameManager.start_mission(mission_id)
