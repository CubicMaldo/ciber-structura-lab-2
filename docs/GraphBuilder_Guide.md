# Guía para Diseñadores: Creación de Grafos con GraphBuilder

## 📋 Resumen

El sistema **GraphBuilder** permite crear grafos visualmente desde el Inspector de Godot sin escribir código. Esto separa el diseño del grafo de la lógica de la misión.

---

## 🎯 Flujo de Trabajo

### 1. Agregar GraphBuilder a la escena de la misión

1. Abre la escena de tu misión (ej. `scenes/missions/Mission_1.tscn`)
2. Haz clic derecho en el nodo raíz de la misión → **Add Child Node**
3. Busca y selecciona **GraphBuilder**
4. Asegúrate de que el nodo se llame exactamente `GraphBuilder` (la misión lo busca por este nombre)

### 2. Crear nodos del grafo

1. Selecciona el nodo `GraphBuilder` en el árbol de escena
2. En el Inspector, localiza la propiedad **Nodes**
3. Haz clic en el botón **"+"** para agregar un nuevo elemento
4. Expande el elemento creado y configura:

   **Propiedades básicas:**
   - **Node Key**: Identificador único del nodo (ej. `"Router Core"`)
   - **Vertex Meta**: Haz clic en el dropdown y selecciona el tipo de Resource:
     - **"New VertexMeta"** - Nodo genérico con propiedades básicas
     - **"New NetworkNodeMeta"** - Nodo para misiones de red (hereda de VertexMeta)
     - **"Load"** - Cargar un Resource existente guardado en disco

   **Para VertexMeta básico:**
   - **Display Name**: Nombre visible del nodo
   - **Vertex Id**: ID numérico (opcional)
   - **Vertex Type**: Tipo de vértice como string

   **Para NetworkNodeMeta (incluye todo lo de VertexMeta más):**
   - **Hidden Message**: Pista oculta que se revela al visitar el nodo
   - **Is Root**: Marca si es el nodo objetivo/raíz
   - **Threat Level**: Nivel de amenaza (0-3)
   - **Device Type**: Tipo de dispositivo (Server, Router, Firewall, etc.)

5. Repite para cada nodo del grafo

> **💡 Tip**: Puedes crear un NetworkNodeMeta en un archivo `.tres`, configurarlo, y luego usar "Load" para reutilizarlo en múltiples nodos

### 3. Crear conexiones entre nodos

1. En el Inspector del `GraphBuilder`, localiza la propiedad **Connections**
2. Haz clic en el botón **"+"** para agregar una conexión
3. Configura cada conexión:
   - **From Node**: Key del nodo origen (debe coincidir con un `node_key` existente)
   - **To Node**: Key del nodo destino
   - **Weight**: Peso de la conexión (por defecto `1.0`)
   - **Edge Meta**: (Opcional) Metadata de la arista
     - **"New EdgeMeta"** - Crea metadata básica para la arista
     - **"Load"** - Carga EdgeMeta existente
     - Dejar vacío - Se creará EdgeMeta por defecto automáticamente
   - **Directed**: Debe dejarse activado (`true`). El sistema asume grafos dirigidos y te alertará si lo desactivas.

4. Repite para cada conexión del grafo

> **💡 Tip**: Las conexiones son **bidireccionales** por defecto. El sistema Graph subyacente maneja automáticamente las aristas en ambas direcciones.

### 4. Verificar la configuración

1. Selecciona el nodo `GraphBuilder`
2. En la pestaña de script, puedes llamar `debug_print()` para ver un resumen del grafo en consola
3. La validación automática detectará:
   - ✅ Nodos duplicados
   - ✅ Conexiones a nodos inexistentes
   - ✅ Keys vacíos

---

## 📝 Ejemplo Completo: Mission_1

### Estructura de nodos

| Node Key | Display Name | Hidden Message | Is Root | Threat Level | Device Type |
|----------|--------------|----------------|---------|--------------|-------------|
| `Firewall Central` | Firewall Central | "Registros sospechosos..." | false | 1 | Firewall |
| `Base de Datos` | Base de Datos | "Acceso inusual..." | false | 2 | Database |
| `Servidor de Correo` | Servidor de Correo | "Correo con adjunto..." | false | 2 | Server |
| `Proxy` | Proxy | "Saltos extraños..." | false | 1 | Proxy |
| `Router Core` | Router Core | "Este nodo contiene el proceso raíz..." | **true** | 3 | Router |

### Estructura de conexiones

| From Node | To Node | Weight |
|-----------|---------|--------|
| Firewall Central | Proxy | 1.0 |
| Proxy | Router Core | 1.0 |
| Proxy | Servidor de Correo | 1.0 |
| Servidor de Correo | Base de Datos | 1.0 |

---

## 🔧 Solución de Problemas

### El grafo no se muestra

- ✅ Verifica que el nodo se llame exactamente `GraphBuilder`
- ✅ Asegúrate de que hay al menos un nodo configurado
- ✅ Revisa que los `node_key` no estén vacíos

### Las conexiones no aparecen

- ✅ Verifica que `from_node` y `to_node` coincidan exactamente con `node_key` de nodos existentes
- ✅ Los keys son **sensibles a mayúsculas**: `"proxy"` ≠ `"Proxy"`

### No veo las propiedades de NetworkNodeMeta

- ✅ Asegúrate de haber creado un **"New NetworkNodeMeta"** en el campo **Vertex Meta**
- ✅ Haz clic en la flecha junto al Resource para expandir sus propiedades
- ✅ Si creaste un VertexMeta básico por error, cámbialo por NetworkNodeMeta desde el dropdown

---

## 🚀 Ventajas del Sistema

1. **Sin código**: Los diseñadores pueden modificar grafos sin tocar scripts
2. **Visual**: Todo se configura desde el Inspector de Godot
3. **Desacoplado**: La misión solo lee el grafo, no lo construye
4. **Validación**: Detecta errores comunes automáticamente
5. **Hot-reload**: Cambios se aplican inmediatamente al guardar la escena
6. **Reutilizable**: El mismo sistema funciona para todas las misiones

---

## 📚 Archivos Relacionados

- **GraphBuilder.gd**: Nodo principal que construye el grafo
- **GraphNodeData.gd**: Resource para configurar nodos
- **GraphConnectionData.gd**: Resource para configurar conexiones
- **NetworkNodeMeta.gd**: Metadata especializada para Mission_1

---

## 💡 Tips para Diseñadores

- **Nomenclatura consistente**: Usa nombres descriptivos y únicos para `node_key`
- **Validación temprana**: Ejecuta la escena frecuentemente para detectar errores
- **Backup**: Guarda versiones de la escena antes de cambios grandes
- **Documentación**: Usa `hidden_message` para contar una historia coherente
- **Iteración rápida**: Modifica valores en el Inspector y presiona F5 para probar inmediatamente
