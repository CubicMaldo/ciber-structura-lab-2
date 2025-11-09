extends Node
## EventBus (autoload "EventBus")
## Lightweight publish/subscribe event bus.
## Usage:
##   - Engine.get_singleton("EventBus").publish("mission_started", {"id": "Mission_1"})
##   - Engine.get_singleton("EventBus").subscribe("mission_started", Callable(self, "_on_mission_started"))

var _subscribers := {}

func subscribe(event: String, fn: Callable) -> void:
    if not _subscribers.has(event):
        _subscribers[event] = []
    _subscribers[event].append(fn)

func unsubscribe(event: String, fn: Callable) -> void:
    if not _subscribers.has(event):
        return
    _subscribers[event].erase(fn)
    if _subscribers[event].empty():
        _subscribers.erase(event)

func publish(event: String, payload = null) -> void:
    if not _subscribers.has(event):
        return
    for fn in _subscribers[event]:
        # safe call: Callable.callv accepts an Array of args
        if fn is Callable:
            fn.callv([payload])

func clear() -> void:
    _subscribers.clear()
