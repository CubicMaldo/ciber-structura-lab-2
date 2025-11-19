extends Node
## NotificationTestDemo
## Script de demostración para probar el sistema de notificaciones
## Adjunta este script a un nodo en cualquier escena para probar las notificaciones

@export var auto_start: bool = true
@export var demo_delay: float = 2.0

var demo_notifications := [
	{
		"title": "Analista BFS",
		"description": "Has completado la misión usando el algoritmo BFS",
		"category": "misiones"
	},
	{
		"title": "Ruta Óptima",
		"description": "Trazaste exactamente el camino de menor costo",
		"category": "precisión"
	},
	{
		"title": "Velocista",
		"description": "Completaste la misión en tiempo récord",
		"category": "eficiencia"
	},
	{
		"title": "Guardia de la Red",
		"description": "Has completado todas las misiones principales",
		"category": "progresion"
	},
	{
		"title": "Fase Perfecta",
		"description": "Completaste una fase sin errores",
		"category": "fases"
	},
	{
		"title": "Descubrimiento Oculto",
		"description": "Encontraste un área secreta del juego",
		"category": "secretos"
	}
]

func _ready() -> void:
	if auto_start:
		_start_demo()


func _start_demo() -> void:
	print("=== Iniciando demostración del sistema de notificaciones ===")
	
	# Esperar a que el árbol esté listo
	await get_tree().process_frame
	
	# Mostrar cada notificación con un retraso
	for i in demo_notifications.size():
		var notif: Dictionary = demo_notifications[i]
		print("Mostrando notificación %d/%d: %s" % [i + 1, demo_notifications.size(), notif.title])
		
		NotificationManager.show_custom_notification(
			notif.title,
			notif.description,
			notif.category
		)
		
		# Esperar antes de la siguiente
		if i < demo_notifications.size() - 1:
			await get_tree().create_timer(demo_delay).timeout
	
	print("=== Demostración completada ===")
	print("Historial contiene %d notificaciones" % NotificationManager.get_notification_history().size())


# Función para llamar desde el inspector o consola
func show_random_notification() -> void:
	var notif: Dictionary = demo_notifications[randi() % demo_notifications.size()]
	NotificationManager.show_custom_notification(
		notif.title,
		notif.description,
		notif.category
	)


# Función para probar todas las categorías de una vez
func show_all_categories() -> void:
	for notif in demo_notifications:
		NotificationManager.show_custom_notification(
			notif.title,
			notif.description,
			notif.category
		)


# Función para limpiar el historial
func clear_history() -> void:
	NotificationManager.clear_history()
	print("Historial limpiado")


# Para probar desde Input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				show_random_notification()
				print("F1: Notificación aleatoria mostrada")
			KEY_F2:
				show_all_categories()
				print("F2: Todas las categorías mostradas")
			KEY_F3:
				clear_history()
			KEY_F4:
				var history := NotificationManager.get_notification_history()
				print("F4: Historial (%d items):" % history.size())
				for item in history:
					print("  - %s [%s]" % [item.get("title", "?"), item.get("category", "?")])
