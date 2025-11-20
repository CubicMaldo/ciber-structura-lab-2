extends Node
## SessionManager - Gestiona el seguimiento de sesiones y textos de historia

const SESSION_SAVE_PATH := "user://session_data.save"

var launch_count: int = 0
var has_seen_intro: bool = false

# Textos de historia para cutscenes
var story_texts := {
	"intro": {
		"title": "OPERACIÓN: GUARDIANES DE LA RED",
		"pages": [
			"""El año es 2045. Las redes digitales se han convertido en la columna vertebral de la civilización moderna.

Sistemas de energía, comunicaciones, transporte, salud... todo depende de la interconexión global de datos.

Pero con esta dependencia, ha llegado una nueva amenaza.""",
			"""Grupos de ciberdelincuentes avanzados han comenzado a infiltrarse en infraestructuras críticas.

Sus ataques son sofisticados, coordinados, y devastadores.

Los métodos tradicionales de defensa ya no son suficientes.""",
			"""Por eso se creó el programa CYBERQUEST.

Un equipo élite de analistas capaces de visualizar las redes como grafos matemáticos y aplicar algoritmos de última generación para defender la infraestructura digital.

Tú has sido seleccionado como uno de estos guardianes.""",
			"""Tu misión: Dominar los algoritmos fundamentales de teoría de grafos.

BFS y DFS para rastrear amenazas.
Dijkstra para encontrar rutas seguras.
Max Flow y Min Cut para optimizar y segmentar redes comprometidas.

El futuro digital está en tus manos, agente."""
		]
	},
	"Mission_1": {
		"title": "MISIÓN 1: NETWORK TRACER",
		"pages": [
			"""🚨 ALERTA DE SEGURIDAD 🚨

Sector: Infraestructura Financiera
Amenaza: Malware persistente detectado
Criticidad: ALTA""",
			"""Un malware sofisticado ha infiltrado la red bancaria regional. 

El sistema de detección ha identificado actividad anómala, pero no puede localizar el nodo raíz de la infección.

Tu tarea: Utilizar algoritmos de búsqueda (BFS/DFS) para rastrear el grafo de red y encontrar el origen del ataque antes de que se propague.""",
			"""Recuerda:
• BFS explora nivel por nivel - útil para encontrar el camino más corto
• DFS profundiza primero - útil para recorrer todo el grafo

Analiza el patrón de propagación y localiza el nodo infectado.

¡Buena suerte, agente!"""
		]
	},
	"Mission_2": {
		"title": "MISIÓN 2: SHORTEST PATH",
		"pages": [
			"""🚨 ALERTA DE SEGURIDAD 🚨

Sector: Red Hospitalaria
Amenaza: Ransomware activo
Criticidad: CRÍTICA""",
			"""Un ransomware ha comprometido varios nodos en la red de un hospital metropolitano.

Los sistemas de soporte vital están en riesgo. Necesitas aislar el nodo infectado enviando un parche de seguridad, pero el tráfico está comprometido.

Tu tarea: Usar el algoritmo de Dijkstra para encontrar la ruta más segura y rápida desde tu centro de operaciones hasta el nodo crítico.""",
			"""El algoritmo de Dijkstra encuentra el camino de menor costo en grafos ponderados.

Cada enlace tiene un nivel de seguridad. Encuentra la ruta óptima que minimice la exposición al ataque.

Cada segundo cuenta. ¡Adelante!"""
		]
	},
	"Mission_3": {
		"title": "MISIÓN 3: NETWORK FLOW",
		"pages": [
			"""🚨 ALERTA DE SEGURIDAD 🚨

Sector: Centro de Datos Gubernamental
Amenaza: DDoS coordinado
Criticidad: CRÍTICA""",
			"""Un ataque distribuido de denegación de servicio está saturando la red gubernamental.

Los servidores críticos están recibiendo demasiado tráfico malicioso. Necesitas redirigir el flujo de datos legítimos para mantener los servicios operativos.

Tu tarea: Aplicar algoritmos de flujo máximo para optimizar la distribución de tráfico en la red comprometida.""",
			"""Los algoritmos de Max Flow (Ford-Fulkerson, Edmonds-Karp) calculan el flujo máximo que puede pasar desde una fuente a un sumidero.

Maximiza el throughput de datos legítimos mientras el equipo de defensa mitiga el ataque DDoS.

¡El gobierno cuenta contigo!"""
		]
	},
	"Mission_4": {
		"title": "MISIÓN 4: MIN CUT",
		"pages": [
			"""🚨 ALERTA DE SEGURIDAD 🚨

Sector: Red Eléctrica Nacional
Amenaza: APT (Advanced Persistent Threat)
Criticidad: EXTREMA""",
			"""Un grupo APT ha comprometido múltiples nodos en la red de control eléctrico.

La amenaza se está propagando. Debes segmentar la red para contener la infección y proteger los sistemas críticos de generación de energía.

Tu tarea: Identificar el corte mínimo que segmente la red infectada del resto de la infraestructura.""",
			"""Min Cut identifica el conjunto mínimo de conexiones que separan dos partes de la red.

Encuentra el corte óptimo que:
• Aísle los nodos comprometidos
• Minimice el impacto en la conectividad general
• Proteja los sistemas críticos

¡La seguridad energética nacional depende de ti!"""
		]
	},
	"Mission_Final": {
		"title": "MISIÓN FINAL: RED GLOBAL",
		"pages": [
			"""🚨🚨 ALERTA MÁXIMA 🚨🚨

Sector: INFRAESTRUCTURA CRÍTICA GLOBAL
Amenaza: ATAQUE COORDINADO MULTI-VECTOR
Criticidad: ⚠️ CATASTRÓFICA ⚠️""",
			"""Los grupos de ciberterrorismo más avanzados han lanzado un ataque simultáneo contra la infraestructura crítica global.

Energía, comunicaciones, transporte, finanzas... todo está bajo ataque coordinado.

Esta es la amenaza para la que has sido entrenado.""",
			"""Tu tarea: Aplicar TODOS los algoritmos que has dominado.

• Rastrear el origen de los ataques (BFS/DFS)
• Encontrar rutas de comunicación seguras (Dijkstra)
• Optimizar el flujo de respuesta (Max Flow)
• Segmentar redes comprometidas (Min Cut)

Debes actuar rápido, con precisión quirúrgica.""",
			"""El mundo digital y el físico están entrelazados.

Miles de millones de personas dependen de que tengas éxito.

Esto es más que un examen de algoritmos. Es la defensa de la civilización conectada.

¿Estás listo, agente?

El futuro comienza ahora."""
		]
	}
}

func _ready() -> void:
	_load_session_data()
	launch_count += 1
	_save_session_data()

func is_first_launch() -> bool:
	return not has_seen_intro

func mark_intro_seen() -> void:
	has_seen_intro = true
	_save_session_data()

func get_story_text(story_id: String) -> Dictionary:
	return story_texts.get(story_id, {
		"title": "MISIÓN DESCONOCIDA",
		"pages": ["No hay información disponible para esta misión."]
	})

func reset_session_data() -> void:
	launch_count = 0
	has_seen_intro = false
	_save_session_data()
	print("SessionManager: Datos de sesión reiniciados")

func _save_session_data() -> void:
	var data = {
		"launch_count": launch_count,
		"has_seen_intro": has_seen_intro
	}
	var file = FileAccess.open(SESSION_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.flush()

func _load_session_data() -> void:
	if not FileAccess.file_exists(SESSION_SAVE_PATH):
		return
	var file = FileAccess.open(SESSION_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY:
		launch_count = parsed.get("launch_count", 0)
		has_seen_intro = parsed.get("has_seen_intro", false)
