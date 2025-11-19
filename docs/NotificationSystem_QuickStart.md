## Guía de Integración Rápida: Sistema de Notificaciones

### Paso 1: Verificar Autoload
El `NotificationManager` ya está registrado en `project.godot`. No requiere configuración adicional.

### Paso 2: Agregar Botón de Historial al MainMenu

Abre `scenes/MainMenu.tscn` y añade:

1. Un nuevo botón en el HUD/UI
2. Asigna el script `res://scripts/ui/HistoryButton.gd` al botón
3. Configura el texto del botón (ej: "Historial de Logros" o icono)

### Paso 3: Probar el Sistema

Para probar las notificaciones sin completar logros:

```gdscript
# En cualquier script de prueba o en _ready() del MainMenu:
func _test_notifications():
    # Esperar a que el autoload esté listo
    await get_tree().process_frame
    
    # Notificación de misión
    NotificationManager.show_custom_notification(
        "Primera Misión",
        "Has completado tu primera misión exitosamente",
        "misiones"
    )
    
    # Notificación de precisión (después de 2 segundos)
    await get_tree().create_timer(2.0).timeout
    NotificationManager.show_custom_notification(
        "Precisión Perfecta",
        "Completaste sin errores",
        "precisión"
    )
    
    # Notificación secreta (después de otros 2 segundos)
    await get_tree().create_timer(2.0).timeout
    NotificationManager.show_custom_notification(
        "Logro Secreto",
        "Descubriste algo oculto",
        "secretos"
    )
```

### Paso 4: Añadir Archivos de Audio (Opcional)

Coloca archivos .ogg en `res://audio/sfx/`:
- `achievement_mission.ogg`
- `achievement_precision.ogg`
- `achievement_efficiency.ogg`
- `achievement_progression.ogg`
- `achievement_stage.ogg`
- `achievement_secret.ogg`
- `achievement_default.ogg`

Si no existen, el sistema funcionará sin sonido.

### Paso 5: Personalizar (Opcional)

Edita `NotificationManager.gd` para ajustar:
```gdscript
# Cambiar tiempo de auto-cierre
auto_dismiss_time: float = 5.0  # En AchievementNotification

# Cambiar tamaño máximo del historial
const MAX_HISTORY_SIZE := 20  # En NotificationManager

# Cambiar colores de categorías
func _get_category_color(category: String) -> Color:
    # Edita los colores aquí
```

### ¡Listo!

El sistema está completamente funcional. Los logros del `AchievementManager` 
se mostrarán automáticamente con las nuevas notificaciones animadas.
