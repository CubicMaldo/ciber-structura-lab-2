extends Button
## ExternalLinkButton - Botón para abrir enlaces externos

var url: String = ""

func setup(link_title: String, link_url: String) -> void:
	text = link_title + " 🔗"
	url = link_url
	flat = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if url != "":
		OS.shell_open(url)
