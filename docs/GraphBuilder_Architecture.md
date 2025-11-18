# GraphBuilder System: Arquitectura de Desacoplamiento

## 🎯 Objetivo

Separar la **lógica de la misión** de la **definición del grafo**, permitiendo que diseñadores creen y modifiquen grafos sin tocar código.

---

## 📐 Arquitectura Anterior vs Nueva
### 🔁 Grafos dirigidos por defecto
Todos los grafos construidos mediante `GraphBuilder` son tratados como dirigidos. Cada `GraphConnectionData` exporta un flag `directed` (ahora default `true`) y el sistema emite advertencias si se intenta construir una conexión sin dirección explícita. Esta decisión mantiene la coherencia con las flechas renderizadas en `GraphDisplay` y con los algoritmos (BFS/DFS) que, a nivel global, respetan la dirección. Si en el futuro se requieren grafos no dirigidos, se podrían reutilizar las APIs (`get_neighbors` vs `get_outgoing_neighbor_weights` y `respect_direction=false`) para mapearlos a este modelo dirigido.

### ❌ **ANTES**: Acoplamiento fuerte

```
Mission1.gd
	├─ _ready()
	│   ├─ var firewall = NetworkNodeMeta.new(...)
	│   ├─ graph.add_node("Firewall Central", firewall)
	│   ├─ var database = NetworkNodeMeta.new(...)
	│   ├─ graph.add_node("Base de Datos", database)
	│   ├─ ... (50+ líneas de construcción manual)
	│   └─ graph.connect_vertices(...)
	│
	└─ start() / step() / complete()
		└─ Lógica del algoritmo BFS/DFS
```

**Problemas:**
- 🔴 Diseñadores deben editar código GDScript
- 🔴 Alta probabilidad de errores de sintaxis
- 🔴 Cambios en el grafo requieren recompilación
- 🔴 Difícil iterar rápidamente en diseño
- 🔴 Lógica de misión mezclada con datos

---

### ✅ **AHORA**: Desacoplamiento con GraphBuilder

```
Mission_1.tscn (Scene)
	├─ Mission1 (Node2D) [Mission1.gd]
	│   ├─ _ready()
	│   │   └─ graph = get_node("GraphBuilder").get_graph()  ← Lee grafo
	│   │
	│   └─ start() / step() / complete()
	│       └─ Lógica del algoritmo BFS/DFS (SOLO LÓGICA)
	│
	├─ GraphBuilder (Node) [GraphBuilder.gd]  ← DATOS DEL GRAFO
	│   ├─ nodes: Array[GraphNodeData]
	│   │   ├─ [0] { node_key: "Firewall Central", ... }
	│   │   ├─ [1] { node_key: "Base de Datos", ... }
	│   │   └─ [2] { node_key: "Router Core", is_root: true, ... }
	│   │
	│   └─ connections: Array[GraphConnectionData]
	│       ├─ [0] { from_node: "Firewall Central", to_node: "Proxy", weight: 1.0 }
	│       └─ [1] { from_node: "Proxy", to_node: "Router Core", weight: 1.0 }
	│
	├─ GraphDisplay (Node2D)
	└─ HUD (CanvasLayer)
```

**Beneficios:**
- ✅ Diseñadores editan el grafo desde el Inspector (GUI)
- ✅ Cambios inmediatos, sin recompilar
- ✅ Validación automática de errores
- ✅ Lógica de misión limpia y enfocada
- ✅ Reutilizable para todas las misiones

---

## 🔄 Flujo de Datos

```
[Designer configura en Inspector]
			↓
	GraphBuilder.nodes[]
	GraphBuilder.connections[]
			↓
	build_graph() en _ready()
			↓
		Graph.gd (modelo)
			↓
	Mission1.get_graph()
			↓
	GraphDisplay.display_graph()
			↓
	[Renderizado visual]
```

---

## 🧩 Componentes del Sistema

### 1. **GraphBuilder.gd** (@tool class)
- **Responsabilidad**: Construir instancias de `Graph` desde datos configurables
- **Exporta**: `nodes`, `connections` editables en Inspector
- **Métodos**:
  - `build_graph() -> Graph`: Construye el grafo
  - `validate() -> Dictionary`: Valida configuración
  - `debug_print()`: Muestra resumen en consola

### 2. **GraphNodeData.gd** (Resource)
- **Responsabilidad**: Almacenar configuración de un nodo
- **Propiedades**:
  - `node_key: String` - Identificador único
  - `vertex_meta: VertexMeta` - Resource de metadata (VertexMeta o cualquier subclase)
- **Método**: `get_metadata() -> VertexMeta` - Obtiene metadata (crea por defecto si es null)

### 3. **GraphConnectionData.gd** (Resource)
- **Responsabilidad**: Almacenar configuración de una arista
- **Propiedades**:
  - `from_node: String` - Nodo origen
  - `to_node: String` - Nodo destino
  - `weight: float` - Peso de la conexión
  - `edge_meta: EdgeMeta` - Resource de metadata (opcional)
- **Método**: `get_edge_metadata() -> EdgeMeta` - Obtiene metadata (crea por defecto si es null)

### 4. **NetworkNodeMeta.gd** (extends VertexMeta)
- **Responsabilidad**: Metadata específica de Mission_1
- **Propiedades tipadas**:
  - `hidden_message: String` - Pista oculta
  - `is_root: bool` - Nodo objetivo
  - `threat_level: int` - Nivel de amenaza (0-3)
  - `device_type: String` - Tipo de dispositivo

---

## 🎨 Flujo de Trabajo del Diseñador

1. **Abre la escena** `Mission_1.tscn`
2. **Selecciona el nodo** `GraphBuilder` en el árbol de escena
3. **En el Inspector**:
   - Expande `nodes`
   - Clic en `+` para agregar nodos
   - Configura cada nodo (key, display_name, tipo, propiedades)
   - Expande `connections`
   - Clic en `+` para agregar conexiones
   - Configura cada conexión (from, to, weight)
4. **Guarda la escena** (Ctrl+S)
5. **Ejecuta la misión** (F5) → Cambios aplicados inmediatamente

---

## 💻 Flujo de Trabajo del Programador

### Crear una nueva misión con GraphBuilder

```gdscript
# Mission2.gd
extends MissionController

func _ready() -> void:
	mission_id = "Mission_2"
	
	# Leer grafo desde GraphBuilder (desacoplado)
	var graph_builder = get_node_or_null("GraphBuilder")
	if graph_builder:
		graph = graph_builder.get_graph()
	else:
		push_warning("No GraphBuilder found")
		graph = _create_fallback_graph()
	
	# Configurar visualización
	var display = get_node_or_null("GraphDisplay")
	if display:
		setup(graph, display)
		display.display_graph(graph)

func start() -> void:
	# SOLO lógica del algoritmo, sin construcción del grafo
	var result = GraphAlgorithms.shortest_path(graph, start_node, target_node)
	# ... resto de la lógica
```

### Crear metadata personalizada para una nueva misión

```gdscript
# DeliveryNodeMeta.gd
class_name DeliveryNodeMeta
extends VertexMeta

@export var package_count: int = 0
@export var is_warehouse: bool = false
@export var delivery_time: float = 0.0

func _init(
	_display_name: String = "",
	_package_count: int = 0,
	_is_warehouse: bool = false,
	_delivery_time: float = 0.0
) -> void:
	super._init(-1, _display_name, "DeliveryNode")
	package_count = _package_count
	is_warehouse = _is_warehouse
	delivery_time = _delivery_time
```

**¡No necesitas modificar GraphNodeData!** El sistema usa `VertexMeta` como tipo base, por lo que cualquier subclase (NetworkNodeMeta, DeliveryNodeMeta, etc.) funcionará automáticamente.

En el Inspector de Godot:
1. Cuando configures `Vertex Meta`, el dropdown mostrará automáticamente **"New DeliveryNodeMeta"** como opción
2. Godot detecta todas las clases que heredan de `VertexMeta`
3. Simplemente selecciona tu nueva clase y configura sus propiedades

**Esto es el poder del sistema basado en Resources**: ¡Extensibilidad sin tocar el código del GraphBuilder!

---

## 🔍 Validación y Debugging

### Validar el grafo en el editor

```gdscript
# En el editor, selecciona GraphBuilder y ejecuta:
var validation = get_node("GraphBuilder").validate()
if not validation.valid:
	for error in validation.errors:
		print("❌ ", error)
```

### Debug del grafo en runtime

```gdscript
# En Mission1.gd _ready():
var graph_builder = get_node("GraphBuilder")
graph_builder.debug_print()  # Imprime resumen completo
```

---

## 📊 Comparación de Líneas de Código

| Aspecto | Antes | Ahora |
|---------|-------|-------|
| **Mission1.gd líneas de setup** | ~60 líneas | ~10 líneas |
| **Acoplamiento** | Alto (misión conoce estructura) | Bajo (misión solo lee) |
| **Editabilidad por diseñador** | No (requiere código) | Sí (GUI del Inspector) |
| **Validación** | Manual | Automática |
| **Hot-reload** | No | Sí |
| **Reutilización** | Duplicar código | Reusar GraphBuilder |

---

## 🚀 Próximos Pasos

1. ✅ **GraphBuilder implementado** para Mission_1
2. ⏳ **Configurar GraphBuilder en Mission_1.tscn** desde el Inspector
3. ⏳ **Eliminar código legacy** de construcción manual en `_create_default_graph()`
4. ⏳ **Aplicar patrón a Mission_2, Mission_3, etc.**
5. ⏳ **Crear herramienta de editor custom** (opcional) para UI mejorada

---

## 📚 Referencias

- **Guía del diseñador**: `docs/GraphBuilder_Guide.md`
- **Código fuente**:
  - `scripts/utils/graphs/GraphBuilder.gd`
  - `scripts/utils/graphs/GraphNodeData.gd`
  - `scripts/utils/graphs/GraphConnectionData.gd`
  - `scripts/missions/mission_1/NetworkNodeMeta.gd`
- **Ejemplo de uso**: `scripts/missions/mission_1/Mission1.gd` (método `_ready()`)
