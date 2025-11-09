extends Node2D
## Simple visual edge for GraphDisplay
## Expects a `setup(data)` method where `data` is a Dictionary with `from`, `to`, and optional `meta`.

var from_id = null
var to_id = null

func setup(data) -> void:
    if typeof(data) == TYPE_DICTIONARY:
        from_id = data.get("from", data.get("from_id", null))
        to_id = data.get("to", data.get("to_id", null))
    else:
        # fallback: assume tuple-like array [from, to]
        if typeof(data) == TYPE_ARRAY and data.size() >= 2:
            from_id = data[0]
            to_id = data[1]
