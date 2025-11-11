# ✅ Mission1 Ahora Usa GraphBuilder Completamente

La Mission1 ha sido refactorizada para **depender exclusivamente del GraphBuilder**. Ya no construye el grafo manualmente en código.

---

## 🔄 Cambios Realizados

### **Mission1.gd - Código Simplificado**

#### ❌ ANTES (construcción manual):
```gdscript
func _ready() -> void:
    # ... setup UI ...
    graph = Graph.new()
    
    # 60+ líneas de construcción manual
    var firewall = NetworkNodeMeta.new(...)
    graph.add_node("Firewall Central", firewall)
    # ... más nodos ...
    graph.connect_vertices(...)
    # ... más conexiones ...
```

#### ✅ AHORA (lee desde GraphBuilder):
```gdscript
func _ready() -> void:
    # ... setup UI ...
    
    # Lee el grafo desde el GraphBuilder hijo
    var graph_builder = get_node_or_null("GraphBuilder")
    if graph_builder:
        graph = graph_builder.get_graph()
        print("Grafo cargado con %d nodos" % graph.get_nodes().size())
    else:
        push_error("No se encontró GraphBuilder")
        graph = Graph.new()
        return
    
    # Visualiza el grafo
    var display = get_node_or_null("GraphDisplay")
    if display:
        setup(graph, display)
        display.display_graph(graph)
```

### **Código Eliminado**
- ✅ Eliminada función `_create_default_graph()` (~60 líneas)
- ✅ Eliminado preload innecesario de `NetworkNodeMeta`
- ✅ Eliminada construcción manual de nodos y conexiones

### **Resultado**
- **Antes**: ~320 líneas
- **Ahora**: ~260 líneas
- **Reducción**: **~60 líneas (-19%)**
- **Acoplamiento**: De ALTO a CERO (misión no conoce estructura del grafo)

---

## 🎯 Configuración Requerida en Godot Editor

### **Estado Actual de Mission_1.tscn**

Según la escena actual, el GraphBuilder está mal ubicado:

```
Mission_1 (Node2D)
├─ GraphDisplay (Node2D)
│  └─ Node (GraphBuilder) ← ❌ MAL: dentro de GraphDisplay
├─ HUD (CanvasLayer)
```

### **Estado Requerido**

```
Mission_1 (Node2D)
├─ GraphBuilder (Node) ← ✅ CORRECTO: hijo directo con nombre exacto
├─ GraphDisplay (Node2D)
├─ HUD (CanvasLayer)
```

---

## 📋 Pasos para Corregir la Escena

### **1. Abrir Mission_1.tscn en Godot Editor**

1. Abre Godot Editor
2. Navega a `scenes/missions/Mission_1.tscn`
3. Haz doble clic para abrir la escena

### **2. Mover/Renombrar el GraphBuilder**

**Opción A: Mover el nodo existente**
1. En el árbol de escena, selecciona el nodo `Node` (que es el GraphBuilder)
2. Arrastra y suéltalo como hijo directo de `Mission_1` (al mismo nivel que `GraphDisplay`)
3. Haz clic derecho en el nodo → **"Rename"**
4. Cámbialo a exactamente: `GraphBuilder`

**Opción B: Crear uno nuevo** (si lo anterior no funciona)
1. Selecciona el nodo `Mission_1` en el árbol de escena
2. Clic derecho → **"Add Child Node"**
3. Busca: `Node`
4. Haz clic en **"Create"**
5. Renómbralo a `GraphBuilder`
6. En el Inspector, asigna el script: `res://scripts/utils/graphs/GraphBuilder.gd`
7. Elimina el nodo antiguo dentro de GraphDisplay

### **3. Configurar los Nodos del Grafo**

Con el nodo `GraphBuilder` seleccionado, en el Inspector:

#### **Nodes Array** (5 nodos)

**Nodo 1: Firewall Central**
- Haz clic en `nodes` → `+`
- `node_key`: `Firewall Central`
- `vertex_meta`: **"New NetworkNodeMeta"** → Expandir:
  - `display_name`: `Firewall Central`
  - `hidden_message`: `Registros sospechosos en horario nocturno.`
  - `is_root`: `false`
  - `threat_level`: `1`
  - `device_type`: `Firewall`

**Nodo 2: Base de Datos**
- `+` → `node_key`: `Base de Datos`
- `vertex_meta`: **"New NetworkNodeMeta"**
  - `display_name`: `Base de Datos`
  - `hidden_message`: `Acceso inusual desde una IP interna.`
  - `is_root`: `false`
  - `threat_level`: `2`
  - `device_type`: `Database`

**Nodo 3: Servidor de Correo**
- `+` → `node_key`: `Servidor de Correo`
- `vertex_meta`: **"New NetworkNodeMeta"**
  - `display_name`: `Servidor de Correo`
  - `hidden_message`: `Correo con adjunto malicioso detectado.`
  - `is_root`: `false`
  - `threat_level`: `2`
  - `device_type`: `Server`

**Nodo 4: Proxy**
- `+` → `node_key`: `Proxy`
- `vertex_meta`: **"New NetworkNodeMeta"**
  - `display_name`: `Proxy`
  - `hidden_message`: `Saltos extraños en la ruta.`
  - `is_root`: `false`
  - `threat_level`: `1`
  - `device_type`: `Proxy`

**Nodo 5: Router Core** ⭐
- `+` → `node_key`: `Router Core`
- `vertex_meta`: **"New NetworkNodeMeta"**
  - `display_name`: `Router Core`
  - `hidden_message`: `Este nodo contiene el proceso raíz del virus.`
  - `is_root`: `true` ✅
  - `threat_level`: `3`
  - `device_type`: `Router`

#### **Connections Array** (4 conexiones)

**Conexión 1**
- `connections` → `+`
- `from_node`: `Firewall Central`
- `to_node`: `Proxy`
- `weight`: `1.0`

**Conexión 2**
- `+`
- `from_node`: `Proxy`
- `to_node`: `Router Core`
- `weight`: `1.0`

**Conexión 3**
- `+`
- `from_node`: `Proxy`
- `to_node`: `Servidor de Correo`
- `weight`: `1.0`

**Conexión 4**
- `+`
- `from_node`: `Servidor de Correo`
- `to_node`: `Base de Datos`
- `weight`: `1.0`

### **4. Guardar y Probar**

1. **Ctrl+S** para guardar la escena
2. **F5** o **"Play Scene"** para ejecutar
3. Verifica en la consola: `"Mission_1: Grafo cargado desde GraphBuilder con 5 nodos"`

---

## 🔍 Validación

### **Consola debe mostrar:**
```
Mission_1: Grafo cargado desde GraphBuilder con 5 nodos
```

### **Si ves error:**
```
Mission_1: No se encontró nodo GraphBuilder
```

**Solución:** Verifica que:
- ✅ El nodo se llama exactamente `GraphBuilder` (case-sensitive)
- ✅ Es hijo directo de `Mission_1` (no de GraphDisplay)
- ✅ Tiene el script `GraphBuilder.gd` asignado

---

## 🎮 Resultado Esperado

Al ejecutar la misión:
1. Los 5 nodos aparecen en layout circular
2. Al seleccionar BFS/DFS y hacer clic en "Iniciar" → "Paso":
   - Los nodos cambian de color (azul → amarillo → verde)
   - Las pistas se muestran en cada nodo
   - Al llegar al Router Core, se muestra en rojo y la misión se completa

---

## 📚 Documentación Relacionada

- **Guía del diseñador**: `docs/GraphBuilder_Guide.md`
- **Setup detallado**: `docs/GraphBuilder_Setup.md`
- **Arquitectura**: `docs/GraphBuilder_Architecture.md`
- **Sistema de Resources**: `docs/GraphBuilder_Resources.md`

---

## ✨ Beneficios Logrados

| Aspecto | Antes | Ahora |
|---------|-------|-------|
| **Líneas de código** | ~320 | ~260 |
| **Construcción del grafo** | Hardcoded en script | Configurable en Inspector |
| **Acoplamiento** | Alto (misión conoce estructura) | Cero (misión solo lee) |
| **Modificabilidad** | Requiere editar código | Solo editar en Inspector |
| **Reutilización** | Copiar código | GraphBuilder reutilizable |
| **Hot-reload** | No | Sí (cambios inmediatos) |

🎉 **¡La Mission1 ahora está completamente desacoplada del grafo y usa GraphBuilder!**
