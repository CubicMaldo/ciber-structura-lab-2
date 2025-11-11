## NetworkNodeMeta: Metadata especializada para nodos de la Misión 1 (Network Tracer)
## Extiende VertexMeta con propiedades específicas del dominio de seguridad de redes
class_name NetworkNodeMeta
extends VertexMeta

## Mensaje oculto/pista que se revela al visitar este nodo
@export var hidden_message: String = ""

## Indica si este nodo es el nodo raíz infectado (objetivo de la misión)
@export var is_root: bool = false

## Nivel de amenaza del nodo (0-3: ninguno, bajo, medio, alto)
@export_range(0, 3) var threat_level: int = 0

## Tipo de dispositivo de red
@export_enum("Server", "Router", "Firewall", "Database", "Proxy", "Workstation") var device_type: String = "Server"


func _init(
	_display_name: String = "",
	_hidden_message: String = "",
	_is_root: bool = false,
	_threat_level: int = 0,
	_device_type: String = "Server"
) -> void:
	super._init(-1, _display_name, "NetworkNode")
	hidden_message = _hidden_message
	is_root = _is_root
	threat_level = _threat_level
	device_type = _device_type


## Verifica si el nodo tiene una pista/mensaje oculto
func has_clue() -> bool:
	return hidden_message != ""


## Devuelve un resumen del estado del nodo para debugging
func get_summary() -> String:
	var parts: Array[String] = []
	parts.append("Node: %s" % display_name)
	parts.append("Type: %s" % device_type)
	if is_root:
		parts.append("ROOT NODE")
	if has_clue():
		parts.append("Has clue: '%s'" % hidden_message)
	parts.append("Threat: %d" % threat_level)
	return " | ".join(parts)
