extends Node
## ThreatManager (autoload "ThreatManager")
## Centralized risk/turn/resource system shared by all missions.

signal threat_level_changed(level: int, state: String)
signal resources_changed(resources: Dictionary)
signal turns_changed(remaining_turns: int)

const MIN_THREAT := 0
const MAX_THREAT := 100
const WARNING_THRESHOLD := 60
const CRITICAL_THRESHOLD := 85

const DEFAULT_TURN_LIMIT := 15
const DEFAULT_RESOURCES := {
	"scans": 2,
	"firewalls": 1
}

var threat_level: int = 35
var turns_remaining: int = DEFAULT_TURN_LIMIT
var active_mission_id: String = ""
var resources: Dictionary = DEFAULT_RESOURCES.duplicate(true)
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	var bus = _get_event_bus()
	if bus:
		bus.mission_started.connect(_on_mission_started)
		bus.mission_completed.connect(_on_mission_completed)


func begin_mission_session(mission_id: String, requested_turns: int = DEFAULT_TURN_LIMIT) -> void:
	active_mission_id = mission_id
	turns_remaining = clamp(requested_turns, 5, 40)
	# Slight tension bump when entering a new mission
	threat_level = clamp(threat_level + 2, MIN_THREAT, MAX_THREAT)
	# Ensure the player has at least one scan per mission start
	if resources.get("scans", 0) == 0:
		resources["scans"] = 1
	_emit_all()


func consume_turn(count: int = 1) -> int:
	if count <= 0:
		return turns_remaining
	turns_remaining = max(0, turns_remaining - count)
	if turns_remaining == 0:
		apply_penalty(8)
	turns_changed.emit(turns_remaining)
	return turns_remaining


func reset_turns(limit: int = DEFAULT_TURN_LIMIT) -> void:
	turns_remaining = clamp(limit, 5, 40)
	turns_changed.emit(turns_remaining)


func get_turns_remaining() -> int:
	return turns_remaining


func apply_penalty(amount: int) -> void:
	if amount <= 0:
		return
	threat_level = clamp(threat_level + amount, MIN_THREAT, MAX_THREAT)
	threat_level_changed.emit(threat_level, get_threat_state())


func apply_relief(amount: int) -> void:
	if amount <= 0:
		return
	threat_level = clamp(threat_level - amount, MIN_THREAT, MAX_THREAT)
	threat_level_changed.emit(threat_level, get_threat_state())


func get_threat_state() -> String:
	if threat_level >= CRITICAL_THRESHOLD:
		return "critical"
	if threat_level >= WARNING_THRESHOLD:
		return "warning"
	return "stable"


func spend_resource(resource_name: String, amount: int = 1) -> bool:
	var current: int = resources.get(resource_name, 0)
	if amount <= 0:
		return true
	if current < amount:
		return false
	resources[resource_name] = current - amount
	resources_changed.emit(get_resources())
	return true


func add_resource(resource_name: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var current: int = resources.get(resource_name, 0)
	resources[resource_name] = current + amount
	resources_changed.emit(get_resources())


func get_resources() -> Dictionary:
	return resources.duplicate(true)


func get_max_resources() -> Dictionary:
	return DEFAULT_RESOURCES.duplicate(true)


func get_status() -> Dictionary:
	return {
		"mission": active_mission_id,
		"threat_level": threat_level,
		"threat_state": get_threat_state(),
		"turns_remaining": turns_remaining,
		"resources": get_resources()
	}


func get_threat_level_value() -> int:
	return threat_level


func _emit_all() -> void:
	threat_level_changed.emit(threat_level, get_threat_state())
	turns_changed.emit(turns_remaining)
	resources_changed.emit(get_resources())


func _on_mission_started(mission_id: String) -> void:
	# Missions call begin_mission_session manually to set their own turn limits, but we
	# still keep track of the last mission triggered via EventBus for telemetry.
	active_mission_id = mission_id


func _on_mission_completed(mission_id: String, success: bool, _data: Dictionary) -> void:
	if mission_id != active_mission_id:
		return
	if success:
		apply_relief(12)
		add_resource("firewalls", 1)
	else:
		apply_penalty(10)
		# Provide a consolation scan so the player can recover next attempt
		add_resource("scans", 1)


func _get_event_bus():
	return Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
