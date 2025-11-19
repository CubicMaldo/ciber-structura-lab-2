## Documento de Referencia: Sistema de Notificaciones Mejoradas

Este documento describe el sistema de notificaciones de logros implementado en el proyecto.

## Componentes Principales

### 1. NotificationManager (Autoload)
**Ubicación:** `res://scripts/managers/NotificationManager.gd`

Singleton que gestiona:
- Cola de notificaciones pendientes
- Historial de notificaciones recientes (máx. 20)
- Reproducción de sonidos por categoría
- Animaciones de entrada/salida
- Persistencia del historial

**Señales:**
- `notification_shown(notification_data: Dictionary)` - Emitida cuando se muestra una notificación
- `notification_dismissed(notification_id: String)` - Emitida cuando se cierra una notificación

**Métodos públicos:**
```gdscript
show_achievement_notification(achievement_id: String, achievement_data: Dictionary)
show_custom_notification(title: String, description: String, category: String)
get_notification_history() -> Array[Dictionary]
clear_history()
register_container(container: Control)
unregister_container()
```

### 2. AchievementNotification (Escena UI)
**Ubicación:** `res://scenes/ui/AchievementNotification.tscn`
**Script:** `res://scenes/ui/AchievementNotification.gd`

Componente visual de una notificación individual con:
- Título y descripción del logro
- Icono según categoría
- Etiqueta de categoría con color
- Botón de cierre
- Efecto de brillo animado
- Auto-cierre después de 5 segundos (configurable)

### 3. NotificationHistoryPanel (Escena UI)
**Ubicación:** `res://scenes/ui/NotificationHistoryPanel.tscn`
**Script:** `res://scripts/ui/NotificationHistoryPanel.gd`

Panel que muestra:
- Lista de todas las notificaciones recientes
- Información de cada logro (título, descripción, categoría, timestamp)
- Botón para limpiar historial
- Formato de tiempo relativo ("Hace 5 minutos")

### 4. HistoryButton
**Ubicación:** `res://scripts/ui/HistoryButton.gd`

Script auxiliar para añadir a cualquier botón que deba abrir el historial.

## Categorías de Logros

Cada categoría tiene su propio color y sonido distintivo:

| Categoría | Color | Archivo de Sonido |
|-----------|-------|-------------------|
| misiones | Azul (#33B3FF) | achievement_mission.ogg |
| precisión | Dorado (#FFB333) | achievement_precision.ogg |
| eficiencia | Verde (#4DFF4D) | achievement_efficiency.ogg |
| progresion | Púrpura (#CC4DFF) | achievement_progression.ogg |
| fases | Naranja (#FF8033) | achievement_stage.ogg |
| secretos | Rosa (#FF3380) | achievement_secret.ogg |
| default | Gris (#B3B3B3) | achievement_default.ogg |

## Animaciones

### Entrada (0.5s total)
1. Fade-in desde transparente (0.4s)
2. Escala desde 0.5x a 1.0x con efecto de rebote (0.5s)
3. Rotación desde -0.1 rad a 0 (0.5s)
4. Brillo adicional: 1.0 → 1.2 → 1.0 (0.4s)

### Salida (0.3s)
1. Fade-out a transparente
2. Escala a 0.7x
3. Desplazamiento hacia arriba (-50px)

### Efecto de Brillo
Loop 2 veces: transparente → 30% opacidad → transparente (0.6s total)

## Integración

### Uso Automático
El sistema se conecta automáticamente a `AchievementManager.achievement_unlocked`.
No se requiere código adicional para logros existentes.

### Uso Manual
```gdscript
# Notificación de logro personalizada
NotificationManager.show_custom_notification(
    "Misión Especial",
    "Has descubierto un área secreta",
    "secretos"
)

# Obtener historial
var history = NotificationManager.get_notification_history()
for notif in history:
    print(notif.title, " - ", notif.timestamp)

# Limpiar historial
NotificationManager.clear_history()
```

### Añadir Botón de Historial
1. Crear un botón en tu escena
2. Asignarle el script `HistoryButton.gd`
3. El botón abrirá/cerrará el panel de historial al hacer clic

## Archivos de Audio

Los archivos de audio deben colocarse en `res://audio/sfx/` con los nombres especificados.

**Recomendaciones:**
- Duración: 0.5-1.5 segundos
- Formato: OGG Vorbis (mejor compresión)
- Volumen normalizado
- Sonidos distintivos por categoría
- Logros secretos deben tener un sonido especial memorable

**Fuentes sugeridas:**
- freesound.org
- OpenGameArt.org
- Kenney.nl
- sfxr/bfxr para sonidos sintetizados

## Persistencia

El historial se guarda automáticamente en:
`user://notification_history.json`

Formato:
```json
{
    "version": 1,
    "history": [
        {
            "id": "achievement_id",
            "type": "achievement",
            "title": "Título del Logro",
            "description": "Descripción...",
            "category": "misiones",
            "timestamp": 1700000000,
            "icon": "res://sprites/icons/..."
        }
    ]
}
```

## Configuración

Variables configurables en `NotificationManager`:
- `MAX_HISTORY_SIZE`: Número máximo de notificaciones en historial (default: 20)
- `NOTIFICATION_SCENE_PATH`: Ruta a la escena de notificación

Variables configurables en `AchievementNotification`:
- `auto_dismiss_time`: Segundos antes de auto-cerrar (default: 5.0)
- `show_close_button`: Mostrar botón de cierre (default: true)

## Solución de Problemas

**Las notificaciones no aparecen:**
- Verificar que NotificationManager esté registrado como autoload
- Verificar que AchievementNotification.tscn exista

**Sin sonido:**
- Verificar que los archivos .ogg existan en `res://audio/sfx/`
- Revisar configuración de audio en Project Settings
- Comprobar que AudioServer no esté muteado

**El historial no se guarda:**
- Verificar permisos de escritura en directorio user://
- Revisar logs de Godot para errores de FileAccess

## Próximas Mejoras Potenciales

- [ ] Agrupación de notificaciones múltiples
- [ ] Prioridad de notificaciones
- [ ] Notificaciones persistentes (no auto-cerrar)
- [ ] Animaciones personalizadas por categoría
- [ ] Efectos de partículas
- [ ] Integración con sistema de achievements de Steam/consolas
- [ ] Notificaciones en segundo plano (cuando el juego está minimizado)
