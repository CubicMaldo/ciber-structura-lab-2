extends Node
@warning_ignore_start("unused_signal")
## EventBus (autoload "EventBus")
## Central event bus using Godot's native signal system.
## 
## Signals are strongly typed for robustness and editor visibility.
## Connect/disconnect using standard Godot signal syntax:
##   EventBus.node_visited.connect(_on_node_visited)
##   EventBus.node_visited.emit(vertex_object)
##   EventBus.node_visited.disconnect(_on_node_visited)

# ============================================================================
# SEÑALES DEL SISTEMA DE MISIONES
# ============================================================================

## Emitida cuando se inicia una misión.
## @param mission_id: Identificador único de la misión (ej: "Mission_1")
signal mission_started(mission_id: String)

## Emitida cuando se completa una misión.
## @param mission_id: Identificador de la misión completada
## @param result: Diccionario con resultados (score, tiempo, etc)
signal mission_finished(mission_id: String, result: Dictionary)

## Emitida cuando el usuario selecciona una misión en el menú.
## @param mission_id: Identificador de la misión seleccionada
signal mission_selected(mission_id: String)

## Emitida cuando se completa la lógica de una misión (algoritmo terminado).
## @param mission_id: Identificador de la misión
## @param success: True si se completó exitosamente
## @param data: Datos adicionales del resultado
signal mission_completed(mission_id: String, success: bool, data: Dictionary)

## Emitida cuando inicia la lógica de ejecución de una misión.
## @param mission_id: Identificador de la misión que comienza
signal mission_logic_started(mission_id: String)

# ============================================================================
# SEÑALES DEL SISTEMA DE NAVEGACIÓN
# ============================================================================

## Emitida cuando se solicita cambio a una misión específica.
## @param mission_id: Identificador de la misión destino
## @param scene_path: Ruta res:// de la escena
signal mission_change_requested(mission_id: String, scene_path: String)

## Emitida cuando se completa un cambio de escena.
## @param scene_path: Ruta res:// de la nueva escena cargada
signal scene_changed(scene_path: String)

# ============================================================================
# SEÑALES DEL SISTEMA DE GRAFOS (TIPADAS CON OBJETOS)
# ============================================================================

## Emitida cuando se muestra un grafo en pantalla.
## @param graph: Instancia del objeto Graph
signal graph_displayed(graph: Graph)

## Emitida cuando un algoritmo visita un vértice.
## @param vertex: Objeto Vertex visitado
signal node_visited(vertex: Vertex)

## Emitida cuando un algoritmo visita una arista.
## @param edge: Objeto Edge visitado
signal edge_visited(edge: Edge)

## Emitida cuando un vértice cambia de estado visual.
## @param vertex: Objeto Vertex que cambió
## @param state: Nuevo estado visual (ej: "default", "visited", "current", "path")
signal node_state_changed(vertex: Vertex, state: String)

## Emitida cuando una arista cambia de estado visual.
## @param edge: Objeto Edge que cambió
## @param state: Nuevo estado visual
signal edge_state_changed(edge: Edge, state: String)

## Emitida cuando se añade un nodo al grafo.
## @param vertex: Objeto Vertex añadido
signal node_added(vertex: Vertex)

## Emitida cuando se elimina un nodo del grafo.
## @param vertex_key: Clave del vértice eliminado
signal node_removed(vertex_key: Variant)

## Emitida cuando se añade una arista al grafo.
## @param edge: Objeto Edge añadido
signal edge_added(edge: Edge)

## Emitida cuando se elimina una arista del grafo.
## @param from_key: Clave del vértice origen
## @param to_key: Clave del vértice destino
signal edge_removed(from_key: Variant, to_key: Variant)

# ============================================================================
# SEÑALES DEL GLOSARIO INTERACTIVO
# ============================================================================

## Emitida cuando el usuario selecciona un término del glosario para ver detalles.
## @param term_id: Identificador del término seleccionado
signal glossary_term_selected(term_id: String)

## Emitida cuando el usuario busca términos en el glosario.
## @param query: Texto de búsqueda
signal glossary_search_performed(query: String)

