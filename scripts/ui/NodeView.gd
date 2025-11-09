extends Node2D
## Simple visual node for GraphDisplay
## Expects a `setup(data)` method where `data` is a Dictionary with at least `id` and optional `meta`.

var node_id = null

func setup(data) -> void:
    # data may be a Dictionary {"id":..., "meta":...} or a simple value
    if typeof(data) == TYPE_DICTIONARY and data.has("id"):
        node_id = data.id
    else:
        node_id = data
    # visual placeholder: add a Label or tweak modulate in the scene editor
    if has_node("Label"):
        $Label.text = str(node_id)
