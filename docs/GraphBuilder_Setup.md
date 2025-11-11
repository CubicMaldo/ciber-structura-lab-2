# 🎮 Sistema GraphBuilder - Configuración Rápida

## ✅ Sistema Implementado

Se ha creado un sistema completo de **GraphBuilder** que desacopla la definición del grafo de la lógica de la misión.

---

## 🔧 Próximo Paso: Configurar en el Editor de Godot

### 1. Abrir la escena Mission_1

1. Abre Godot Editor
2. Navega a `scenes/missions/Mission_1.tscn`
3. Haz doble clic para abrir la escena

### 2. Agregar el nodo GraphBuilder

1. En el árbol de escena, haz clic derecho en el nodo raíz `Mission_1`
2. Selecciona **"Add Child Node"**
3. En el diálogo, busca: `GraphBuilder`
4. Selecciona `GraphBuilder` y haz clic en **"Create"**
5. **IMPORTANTE**: Asegúrate de que el nodo se llame exactamente `GraphBuilder` (sin números ni sufijos)

### 3. Configurar los nodos del grafo

1. Selecciona el nodo `GraphBuilder` en el árbol de escena
2. En el **Inspector** (panel derecho), localiza la propiedad **`Nodes`**
3. Haz clic en el ícono de array para expandir
4. Configura 5 nodos (haz clic en `+` para cada uno):

#### Nodo 1: Firewall Central
- **Node Key**: `Firewall Central`
- **Vertex Meta**: Haz clic en el dropdown y selecciona **"New NetworkNodeMeta"**
  - Se creará un nuevo Resource de tipo `NetworkNodeMeta`
  - Haz clic en el ícono de flecha para expandir las propiedades del Resource:
    - **Display Name**: `Firewall Central`
    - **Hidden Message**: `Registros sospechosos en horario nocturno.`
    - **Is Root**: `false` (desmarcado)
    - **Threat Level**: `1`
    - **Device Type**: `Firewall`

#### Nodo 2: Base de Datos
- **Node Key**: `Base de Datos`
- **Vertex Meta**: **"New NetworkNodeMeta"**
  - **Display Name**: `Base de Datos`
  - **Hidden Message**: `Acceso inusual desde una IP interna.`
  - **Is Root**: `false`
  - **Threat Level**: `2`
  - **Device Type**: `Database`

#### Nodo 3: Servidor de Correo
- **Node Key**: `Servidor de Correo`
- **Vertex Meta**: **"New NetworkNodeMeta"**
  - **Display Name**: `Servidor de Correo`
  - **Hidden Message**: `Correo con adjunto malicioso detectado.`
  - **Is Root**: `false`
  - **Threat Level**: `2`
  - **Device Type**: `Server`

#### Nodo 4: Proxy
- **Node Key**: `Proxy`
- **Vertex Meta**: **"New NetworkNodeMeta"**
  - **Display Name**: `Proxy`
  - **Hidden Message**: `Saltos extraños en la ruta.`
  - **Is Root**: `false`
  - **Threat Level**: `1`
  - **Device Type**: `Proxy`

#### Nodo 5: Router Core ⭐ (RAÍZ)
- **Node Key**: `Router Core`
- **Vertex Meta**: **"New NetworkNodeMeta"**
  - **Display Name**: `Router Core`
  - **Hidden Message**: `Este nodo contiene el proceso raíz del virus.`
  - **Is Root**: `true` ✅ (marcado)
  - **Threat Level**: `3`
  - **Device Type**: `Router`

### 4. Configurar las conexiones

1. En el mismo nodo `GraphBuilder`, localiza la propiedad **`Connections`**
2. Haz clic en el ícono de array para expandir
3. Configura 4 conexiones (haz clic en `+` para cada una):

#### Conexión 1
- **From Node**: `Firewall Central`
- **To Node**: `Proxy`
- **Weight**: `1.0`
- **Edge Meta**: Dejar vacío (se creará EdgeMeta por defecto) o crear **"New EdgeMeta"** si necesitas metadata adicional

#### Conexión 2
- **From Node**: `Proxy`
- **To Node**: `Router Core`
- **Weight**: `1.0`
- **Edge Meta**: (opcional)

#### Conexión 3
- **From Node**: `Proxy`
- **To Node**: `Servidor de Correo`
- **Weight**: `1.0`
- **Edge Meta**: (opcional)

#### Conexión 4
- **From Node**: `Servidor de Correo`
- **To Node**: `Base de Datos`
- **Weight**: `1.0`
- **Edge Meta**: (opcional)

> **Nota**: Las conexiones en este sistema son **bidireccionales** por defecto (el grafo subyacente maneja esto automáticamente)

### 5. Guardar y probar

1. Guarda la escena: **Ctrl+S**
2. Ejecuta la escena: **F5** o haz clic en el botón **"Play Scene"**
3. Prueba la misión:
   - Selecciona algoritmo (BFS o DFS)
   - Haz clic en "Iniciar"
   - Haz clic en "Paso" repetidamente para avanzar
   - Observa cómo los nodos cambian de color y se revelan las pistas

---

## 🎯 Resultado Esperado

- Los nodos deben aparecer en un layout circular
- Al hacer clic en "Paso", cada nodo debe:
  - Cambiar a color amarillo (estado "current")
  - El nodo anterior debe cambiar a verde (estado "visited")
  - Mostrar el mensaje oculto como clue
- Al llegar al "Router Core", el nodo debe cambiar a rojo (root) y mostrar el mensaje de éxito

---

## 🔍 Validación

Puedes validar que el grafo esté correctamente configurado ejecutando esto en el debugger de Godot:

1. Abre la consola de Godot (pestaña **"Debugger"** → **"Output"**)
2. En el script `Mission1.gd`, agrega temporalmente en `_ready()`:
   ```gdscript
   var graph_builder = get_node("GraphBuilder")
   if graph_builder:
       graph_builder.debug_print()
   ```
3. Ejecuta la escena y verifica la salida en consola

---

## 📚 Documentación Completa

- **Guía del diseñador**: `docs/GraphBuilder_Guide.md`
- **Arquitectura del sistema**: `docs/GraphBuilder_Architecture.md`

---

## ⚠️ Solución de Problemas

### No veo los nodos en la pantalla
- ✅ Verifica que el nodo `GraphDisplay` esté presente en la escena
- ✅ Asegúrate de que `node_scene` y `edge_scene` estén configurados en `GraphDisplay`

### Los nodos aparecen pero sin pistas
- ✅ Verifica que `Hidden Message` no esté vacío en cada nodo
- ✅ Confirma que `Metadata Type` sea `NetworkNodeMeta` (no `VertexMeta`)

### Error "GraphBuilder not found"
- ✅ Asegúrate de que el nodo se llame exactamente `GraphBuilder`
- ✅ Verifica que sea hijo directo del nodo raíz de la misión

---

## 🎉 ¡Listo!

Una vez configurado, el grafo estará completamente desacoplado de la lógica de la misión. Puedes modificar nodos, conexiones, y propiedades directamente desde el Inspector sin tocar código.
