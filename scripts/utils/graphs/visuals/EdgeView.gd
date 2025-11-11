extends Node2D
## EdgeView: visual representation of a graph edge
## Draws lines between nodes and updates when nodes move
## Supports weight-based thickness and directional arrows

var source_id = null
var target_id = null
var weight: float = 1.0
var source_node: Node2D = null
var target_node: Node2D = null

const BASE_WIDTH := 3.0
const MAX_WIDTH := 10.0


func setup(data) -> void:
	if typeof(data) == TYPE_DICTIONARY:
		source_id = data.get("source", data.get("from", data.get("from_id", null)))
		target_id = data.get("target", data.get("to", data.get("to_id", null)))
		weight = float(data.get("weight", 1.0))
	elif typeof(data) == TYPE_ARRAY and data.size() >= 2:
		source_id = data[0]
		target_id = data[1]
		weight = float(data[2]) if data.size() > 2 else 1.0
	
	# Adjust line width based on weight
	if has_node("Line2D"):
		var line: Line2D = $Line2D
		line.width = BASE_WIDTH + min(weight * 0.5, MAX_WIDTH - BASE_WIDTH)


func set_node_references(source: Node2D, target: Node2D) -> void:
	source_node = source
	target_node = target
	update_line()


func update_line() -> void:
	if not source_node or not target_node:
		return
	
	if not has_node("Line2D"):
		return
	
	var line: Line2D = $Line2D
	var start_pos = source_node.global_position
	var end_pos = target_node.global_position
	
	# Convert to local coordinates
	var local_start = to_local(start_pos)
	var local_end = to_local(end_pos)
	
	line.points = PackedVector2Array([local_start, local_end])


func set_state(new_state: String) -> void:
	if not has_node("Line2D"):
		return
	
	var line: Line2D = $Line2D
	match new_state:
		"visited":
			line.default_color = Color(0.4, 0.8, 0.4, 0.9)
		"active":
			line.default_color = Color(1.0, 0.8, 0.0, 1.0)
		"highlighted":
			line.default_color = Color(1.0, 0.5, 0.0, 1.0)
		_:
			line.default_color = Color(0.5, 0.5, 0.5, 0.8)


func _process(_delta: float) -> void:
	# Update line position each frame if nodes exist
	if source_node and target_node:
		update_line()
