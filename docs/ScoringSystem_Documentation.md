# Sistema de Puntuación Robusto - Documentación

## Descripción General

Se ha implementado un sistema completo de puntuación para las misiones del juego, que permite evaluar el desempeño del jugador en múltiples dimensiones y asignar rankings (Oro, Plata, Bronce).

## Componentes del Sistema

### 1. ScoringSystem (`scripts/systems/ScoringSystem.gd`)

Sistema principal para calcular puntuaciones basado en:

#### Métricas de Evaluación

- **Eficiencia (35%)**: Movimientos óptimos vs usados, penalización por errores
- **Tiempo (25%)**: Comparación contra tiempo objetivo de la misión
- **Movimientos (25%)**: Ratio de movimientos óptimos
- **Recursos (15%)**: Uso eficiente de recursos disponibles

#### Rankings

- **🥇 Oro**: ≥90% del score máximo
- **🥈 Plata**: ≥75% del score máximo  
- **🥉 Bronce**: ≥60% del score máximo
- **○ Sin rango**: <60% del score máximo

#### Puntuación Perfecta

Se otorga cuando:
- Sin errores (mistakes = 0)
- Movimientos ≤ óptimos
- Rango Oro alcanzado

### 2. MissionScoreManager (`scripts/managers/MissionScoreManager.gd`)

Gestor de almacenamiento y persistencia de scores:

#### Funcionalidades

- Guarda scores en `user://mission_scores.save`
- Mantiene historial de top 10 intentos por misión
- Rastrea mejor score de cada misión
- Genera estadísticas globales del jugador

#### Estadísticas Disponibles

```gdscript
{
    "total_missions_completed": int,
    "perfect_completions": int,
    "gold_ranks": int,
    "silver_ranks": int,
    "bronze_ranks": int,
    "total_score": int,
    "average_score": float,
    "total_time": float,
    "best_mission": String,
    "best_mission_score": int
}
```

### 3. MissionController (actualizado)

El controlador base ahora rastrea métricas en tiempo real:

#### Métricas Registradas

```gdscript
var mission_start_time: float = 0.0
var moves_count: int = 0
var optimal_moves: int = 0
var mistakes_count: int = 0
var resources_used: int = 0
var resources_available: int = 0
```

#### Nuevos Métodos

- `add_move()`: Incrementa contador de movimientos
- `add_mistake()`: Incrementa contador de errores
- `set_optimal_moves(count)`: Define movimientos óptimos
- `set_resources(used, available)`: Configura recursos

### 4. MissionScorePanel (`scenes/ui/MissionScorePanel.tscn`)

Panel visual que muestra resultados al completar una misión:

#### Información Mostrada

- Icono y nombre del rango obtenido
- Score total
- Desglose por categoría (Eficiencia, Tiempo, Movimientos, Recursos)
- Estadísticas detalladas (tiempo usado, movimientos, errores)
- Indicadores especiales:
  - **🏆 ¡NUEVO MEJOR SCORE!** - Cuando se supera el récord anterior
  - **✨ ¡PUNTUACIÓN PERFECTA!** - Cuando se logra score perfecto

#### Controles

- **🔄 Reintentar**: Reinicia la misión para mejorar score
- **➡️ Continuar**: Vuelve al menú de misiones

### 5. MissionRankingsPanel (`scenes/ui/MissionRankingsPanel.tscn`)

Panel de rankings global accesible desde MissionSelect:

#### Características

- Pestañas para cada misión
- Estadísticas globales (misiones completadas, rankings obtenidos)
- Top 10 de cada misión con:
  - Posición en ranking
  - Icono de rango
  - Score total
  - Tiempo de completado
  - Movimientos usados/óptimos
  - Cantidad de errores
  - Badge de puntuación perfecta ✨

### 6. EventBus (actualizado)

Nuevas señales para el sistema de puntuación:

```gdscript
signal mission_score_saved(mission_id: String, total_score: int, rank: String, is_new_best: bool)
signal gold_rank_achieved(mission_id: String)
signal perfect_score_achieved(mission_id: String)
```

## Integración en Misiones

### Mission1 (ejemplo implementado)

#### Inicialización

```gdscript
func _on_start_pressed() -> void:
    # Establecer movimientos óptimos
    if graph:
        var node_count = graph.get_nodes().size()
        optimal_moves = node_count  # Un clic por nodo = óptimo
    
    # Configurar recursos
    if threat_manager:
        resources_available = threat_manager.get_max_resources()
        resources_used = 0
    
    start()
```

#### Rastreo de Movimientos

```gdscript
func _process_player_selection(node_key, _is_auto := false) -> void:
    # Contar movimiento (excepto automáticos)
    if not _is_auto:
        add_move()
    
    # Si es error, registrarlo
    if node_key != expected_key:
        add_mistake()
    # ...
```

#### Rastreo de Recursos

```gdscript
func _on_scan_pressed() -> void:
    if threat_manager.spend_resource("scans", 1):
        resources_used += 1
    # ...

func _on_firewall_pressed() -> void:
    if threat_manager.spend_resource("firewalls", 1):
        resources_used += 1
    # ...
```

## Tiempos Objetivo por Misión

```gdscript
const MISSION_TIME_TARGETS := {
    "Mission_1": 120.0,    # 2 minutos
    "Mission_2": 90.0,     # 1.5 minutos
    "Mission_3": 150.0,    # 2.5 minutos
    "Mission_4": 180.0,    # 3 minutos
    "Mission_Final": 300.0 # 5 minutos
}
```

## Flujo de Uso

### 1. Durante la Misión

El jugador realiza acciones que se rastrean automáticamente:
- Clics en nodos → `moves_count++`
- Errores de selección → `mistakes_count++`
- Uso de herramientas → `resources_used++`

### 2. Al Completar

```gdscript
func complete(result := {}) -> void:
    # Calcular tiempo
    var completion_time = (Time.get_ticks_msec() / 1000.0) - mission_start_time
    
    # Calcular score
    var score = ScoringSystem.calculate_score(
        mission_id, completion_time, moves_count, 
        optimal_moves, mistakes_count, 
        resources_used, resources_available
    )
    
    # Guardar y comparar
    var old_best = MissionScoreManager.get_best_score(mission_id)
    MissionScoreManager.save_mission_score(score)
    var is_new_best = ScoringSystem.is_better_score(score, old_best)
    
    # Mostrar panel de resultados
    _show_score_panel(score.to_dict(), is_new_best)
    
    # Emitir eventos
    EventBus.mission_score_saved.emit(...)
    if score.rank == "gold":
        EventBus.gold_rank_achieved.emit(mission_id)
    if score.perfect:
        EventBus.perfect_score_achieved.emit(mission_id)
```

### 3. Ver Rankings

Desde MissionSelect:
1. Clic en botón "📊 Rankings"
2. Seleccionar misión en pestañas
3. Ver top 10 con estadísticas completas

### 4. Reintentar Misión

Desde el panel de resultados:
1. Clic en "🔄 Reintentar"
2. La misión se reinicia con métricas en cero
3. Intentar mejorar el score anterior

## Beneficios del Sistema

### Para el Jugador

✅ **Rejugabilidad**: Motivación para mejorar scores y obtener rankings superiores  
✅ **Feedback Claro**: Métricas detalladas muestran áreas de mejora  
✅ **Competencia Personal**: Comparación con intentos anteriores  
✅ **Logros Tangibles**: Rangos visuales (Oro/Plata/Bronce)  

### Para el Juego

✅ **Engagement**: Incrementa tiempo de juego  
✅ **Skill Progression**: Motiva dominio de algoritmos  
✅ **Analítica**: Datos sobre desempeño del jugador  
✅ **Balance**: Métricas ayudan a ajustar dificultad  

## Extensibilidad

El sistema está diseñado para extenderse fácilmente:

### Agregar Nuevas Métricas

```gdscript
// En MissionController
var combo_count: int = 0

// En ScoringSystem
static func calculate_score(..., combo_count: int) -> MissionScore:
    score.combo_score = _calculate_combo_score(combo_count)
    # ...
```

### Agregar Nuevos Rankings

```gdscript
const PLATINUM_THRESHOLD := 0.95  // 95%

static func _calculate_rank(total_score: int) -> String:
    if score_ratio >= PLATINUM_THRESHOLD:
        return "platinum"
    # ...
```

### Integrar con Leaderboards

El sistema está listo para conectarse con APIs de leaderboards:

```gdscript
func save_mission_score(score) -> void:
    # ... guardar localmente
    
    # Subir a leaderboard online
    if online_service:
        online_service.submit_score(score.to_dict())
```

## Archivos Creados/Modificados

### Archivos Nuevos

- `scripts/systems/ScoringSystem.gd`
- `scripts/managers/MissionScoreManager.gd`
- `scripts/ui/MissionScorePanel.gd`
- `scripts/ui/MissionRankingsPanel.gd`
- `scenes/ui/MissionScorePanel.tscn`
- `scenes/ui/MissionRankingsPanel.tscn`

### Archivos Modificados

- `scripts/missions/MissionController.gd`
- `scripts/missions/mission_1/Mission1.gd`
- `scripts/missions/MissionSelect.gd`
- `scripts/managers/EventBus.gd`
- `scenes/MissionSelect.tscn`
- `project.godot` (autoload MissionScoreManager)

## Próximos Pasos Sugeridos

1. **Implementar en Misión 2, 3, 4 y Final**: Aplicar el tracking de métricas similar a Mission1
2. **Ajustar Tiempos Objetivo**: Balancear según dificultad real de cada misión
3. **Refinar Pesos de Score**: Ajustar EFFICIENCY_WEIGHT, TIME_WEIGHT, etc.
4. **Agregar Achievements**: "Obtén oro en todas las misiones", "10 puntuaciones perfectas"
5. **Leaderboard Global**: Conectar con servicio online para rankings mundiales
6. **Estadísticas Avanzadas**: Gráficos de progreso, comparación temporal
7. **Replay System**: Guardar y reproducir mejores intentos
