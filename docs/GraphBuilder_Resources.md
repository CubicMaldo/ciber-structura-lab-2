# GraphBuilder: Sistema Basado en Resources Existentes

## 🎯 Filosofía de Diseño

El sistema **GraphBuilder** ahora está completamente **desacoplado del juego** y se enfoca exclusivamente en modelar grafos de manera genérica usando los Resources existentes (`VertexMeta` y `EdgeMeta`).

---

## 🏗️ Arquitectura Simplificada

```
GraphBuilder (Node)
    │
    ├─ nodes: Array[GraphNodeData]
    │       │
    │       └─ GraphNodeData (Resource)
    │               ├─ node_key: String
    │               └─ vertex_meta: VertexMeta ← Usa Resource existente
    │                       │
    │                       ├─ VertexMeta (base)
    │                       ├─ NetworkNodeMeta (extends VertexMeta)
    │                       ├─ DeliveryNodeMeta (extends VertexMeta)
    │                       └─ ... cualquier subclase futura
    │
    └─ connections: Array[GraphConnectionData]
            │
            └─ GraphConnectionData (Resource)
                    ├─ from_node: String
                    ├─ to_node: String
                    ├─ weight: float
                    └─ edge_meta: EdgeMeta ← Usa Resource existente (opcional)
```

---

## ✅ Ventajas del Enfoque Basado en Resources

### 1. **Cero Duplicación de Propiedades**

❌ **ANTES** (propiedades duplicadas):
```gdscript
# GraphNodeData.gd tenía propiedades duplicadas
@export var display_name: String = ""
@export var hidden_message: String = ""
@export var is_root: bool = false
# ... duplicando lo que ya existe en NetworkNodeMeta
```

✅ **AHORA** (usa Resources existentes):
```gdscript
# GraphNodeData.gd es solo un wrapper
@export var node_key: String = ""
@export var vertex_meta: VertexMeta = null  # Usa cualquier VertexMeta
```

### 2. **Extensibilidad Automática**

Cuando creas una nueva subclase de `VertexMeta`:

```gdscript
# SpaceStationMeta.gd
class_name SpaceStationMeta
extends VertexMeta

@export var oxygen_level: float = 100.0
@export var crew_count: int = 5
@export var is_docking_port: bool = false
```

**¡Godot automáticamente lo detecta!** El Inspector mostrará "New SpaceStationMeta" como opción sin tocar una sola línea de `GraphBuilder` o `GraphNodeData`.

### 3. **Reutilización de Resources**

Puedes guardar un `NetworkNodeMeta` configurado como archivo `.tres` y cargarlo en múltiples nodos:

```
res://data/presets/
    ├─ firewall_node.tres (NetworkNodeMeta guardado)
    ├─ database_node.tres
    └─ router_node.tres
```

En el Inspector:
- Selecciona `vertex_meta` → **"Load"**
- Elige `firewall_node.tres`
- ¡Instantáneamente tienes todas las propiedades configuradas!

### 4. **Inspector Nativo de Godot**

Todas las propiedades de `VertexMeta` y sus subclases son editables directamente en el Inspector con:
- ✅ Validación de tipos
- ✅ Rangos (`@export_range`)
- ✅ Enums (`@export_enum`)
- ✅ Color pickers
- ✅ File pickers
- ✅ Tooltips (@export annotations)

### 5. **Sistema Genérico para Grafos**

El GraphBuilder **no sabe nada del juego**. Solo conoce:
- `Graph.gd` (estructura de datos)
- `VertexMeta.gd` (metadata de nodos)
- `EdgeMeta.gd` (metadata de aristas)

Esto significa que puedes usarlo para:
- 🎮 Juegos de estrategia (mapas como grafos)
- 🗺️ Sistemas de navegación
- 🌐 Redes sociales simuladas
- 📊 Visualización de datos
- 🧠 Árboles de diálogo
- ⚡ Circuitos eléctricos
- ... cualquier cosa que se modele como grafo!

---

## 🔄 Flujo de Datos Actualizado

```
[Designer en Inspector]
        ↓
    Crea "New NetworkNodeMeta"
        ↓
    Configura propiedades del Resource
    (hidden_message, is_root, etc.)
        ↓
    Asigna a GraphNodeData.vertex_meta
        ↓
    GraphBuilder.build_graph()
        ↓
    node_data.get_metadata() → VertexMeta
        ↓
    graph.add_node(key, metadata)
        ↓
    Mission lee el grafo completo
        ↓
    [Runtime: algoritmo usa metadata]
```

---

## 📊 Comparación: Antes vs Ahora

| Aspecto | Antes (Propiedades Duplicadas) | Ahora (Resource-Based) |
|---------|-------------------------------|------------------------|
| **Propiedades en GraphNodeData** | 10+ propiedades específicas | 2 propiedades (key + meta) |
| **Extensibilidad** | Editar GraphNodeData.gd | Crear subclase de VertexMeta |
| **Duplicación** | Alta (propiedades repetidas) | Cero (usa Resources existentes) |
| **Inspector autocomplete** | Manual (agregar al enum) | Automático (Godot detecta clases) |
| **Reutilización** | Copiar valores manualmente | Load .tres files |
| **Acoplamiento al juego** | Alto (conoce NetworkNodeMeta) | Cero (solo conoce VertexMeta) |
| **Líneas de código** | ~60 líneas | ~20 líneas |

---

## 💡 Ejemplo Práctico: Crear Mission_2 con Nuevo Tipo

### Paso 1: Crear metadata específica

```gdscript
# RouteNodeMeta.gd
class_name RouteNodeMeta
extends VertexMeta

@export var distance_from_start: float = 0.0
@export var is_checkpoint: bool = false
@export var max_capacity: int = 10
@export_enum("Highway", "Street", "Path") var road_type: String = "Street"
```

### Paso 2: Usar en GraphBuilder (¡sin tocar código!)

1. Abre `Mission_2.tscn`
2. Agrega nodo hijo `GraphBuilder`
3. En `nodes` array, agrega `GraphNodeData`:
   - `node_key`: "Checkpoint_A"
   - `vertex_meta`: **"New RouteNodeMeta"** ← ¡Aparece automáticamente!
   - Configura propiedades directamente en Inspector

### Paso 3: Leer en la misión

```gdscript
# Mission2.gd
func _ready() -> void:
    var graph_builder = get_node("GraphBuilder")
    graph = graph_builder.get_graph()
    
    # Acceder a metadata específica
    for key in graph.get_nodes().keys():
        var vertex = graph.get_vertex(key)
        var route_meta = vertex.meta as RouteNodeMeta
        if route_meta and route_meta.is_checkpoint:
            print("Checkpoint: ", route_meta.display_name)
```

---

## 🎨 Workflow del Diseñador (Actualizado)

### Opción A: Crear Resource inline

1. `GraphBuilder` → `nodes` → `+`
2. `node_key`: "Node_A"
3. `vertex_meta` → **"New NetworkNodeMeta"**
4. Expandir flecha → configurar propiedades inline

### Opción B: Crear Resource file reutilizable

1. FileSystem → clic derecho → **"New Resource"**
2. Selecciona `NetworkNodeMeta`
3. Configura propiedades
4. Guarda como `my_node.tres`
5. En GraphBuilder: `vertex_meta` → **"Load"** → selecciona `my_node.tres`

### Opción C: Duplicar Resource existente

1. En Inspector, clic derecho en `vertex_meta` con Resource asignado
2. **"Duplicate"**
3. Modifica propiedades específicas
4. Usa en otro nodo

---

## 🔍 Validación de Diseño

El sistema ahora cumple con los principios SOLID:

- ✅ **Single Responsibility**: GraphBuilder solo construye grafos, no conoce el dominio del juego
- ✅ **Open/Closed**: Abierto a extensión (nuevos VertexMeta) sin modificar código existente
- ✅ **Liskov Substitution**: Cualquier VertexMeta funciona donde se espera VertexMeta
- ✅ **Interface Segregation**: GraphNodeData tiene interfaz mínima (key + meta)
- ✅ **Dependency Inversion**: Depende de abstracciones (VertexMeta) no de implementaciones concretas

---

## 📚 Archivos Relevantes

### Core del sistema (genéricos)
- `scripts/utils/graphs/GraphBuilder.gd` - Constructor de grafos
- `scripts/utils/graphs/GraphNodeData.gd` - Wrapper para nodos
- `scripts/utils/graphs/GraphConnectionData.gd` - Wrapper para aristas
- `scripts/utils/graphs/VertexMeta.gd` - Base metadata para nodos
- `scripts/utils/graphs/EdgeMeta.gd` - Base metadata para aristas

### Implementación específica del juego
- `scripts/missions/mission_1/NetworkNodeMeta.gd` - Metadata para Mission_1
- (Futuro) `scripts/missions/mission_2/RouteNodeMeta.gd` - Metadata para Mission_2

---

## 🚀 Próximos Pasos

1. ✅ Sistema refactorizado para usar Resources existentes
2. ⏳ Configurar GraphBuilder en Mission_1.tscn con NetworkNodeMeta resources
3. ⏳ Crear ejemplos de `.tres` files reutilizables
4. ⏳ Documentar patrones de uso de EdgeMeta (actualmente opcional)
5. ⏳ Crear herramienta de editor custom (opcional) para UI mejorada de GraphBuilder

---

## 🎉 Conclusión

El sistema GraphBuilder ahora es:
- 🎯 **Genérico**: No acoplado al dominio del juego
- 🔌 **Extensible**: Nuevos tipos de metadata automáticamente soportados
- 🔄 **Reutilizable**: Resources guardables y compartibles
- 📦 **Modular**: Usa sistema de Resources nativo de Godot
- 🛠️ **Mantenible**: Menos código, menos duplicación
