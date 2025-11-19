extends Node
## GlossaryManager - Gestiona el glosario de términos técnicos de grafos
## Proporciona definiciones, categorías, visualizaciones y recursos externos

## Representa un término en el glosario
class GlossaryTerm:
	var id: String
	var name: String
	var category: String
	var short_description: String
	var full_description: String
	var complexity: String  # "Básico", "Intermedio", "Avanzado"
	var visualization_type: String  # "graph", "animation", "diagram", "none"
	var external_links: Array[Dictionary]  # [{title: String, url: String}]
	var related_terms: Array[String]  # IDs de términos relacionados
	var used_in_missions: Array[String]  # IDs de misiones donde se usa
	
	func _init(
		p_id: String,
		p_name: String,
		p_category: String,
		p_short_desc: String,
		p_full_desc: String,
		p_complexity: String = "Básico",
		p_viz_type: String = "none",
		p_links: Array = [],
		p_related: Array = [],
		p_missions: Array = []
	):
		id = p_id
		name = p_name
		category = p_category
		short_description = p_short_desc
		full_description = p_full_desc
		complexity = p_complexity
		visualization_type = p_viz_type
		external_links = []
		for link in p_links:
			external_links.append(link)
		related_terms = []
		for term in p_related:
			related_terms.append(term)
		used_in_missions = []
		for mission in p_missions:
			used_in_missions.append(mission)

var terms: Dictionary = {}  # id -> GlossaryTerm
var categories: Array[String] = [
	"Algoritmos de Recorrido",
	"Caminos Mínimos",
	"Árboles de Expansión",
	"Flujo en Redes",
	"Estructuras de Datos",
	"Conceptos Básicos"
]

func _ready() -> void:
	_initialize_terms()

func _initialize_terms() -> void:
	# Algoritmos de Recorrido
	add_term(GlossaryTerm.new(
		"bfs",
		"BFS (Breadth-First Search)",
		"Algoritmos de Recorrido",
		"Algoritmo de búsqueda por amplitud que explora vecinos nivel por nivel.",
		"El BFS (Breadth-First Search) o Búsqueda en Amplitud es un algoritmo fundamental para recorrer o buscar en estructuras de grafos. Comienza en un nodo raíz y explora todos los vecinos en el nivel actual antes de moverse a los nodos del siguiente nivel.\n\n[b]Características:[/b]\n• Utiliza una cola (FIFO) para mantener el orden de visita\n• Encuentra el camino más corto en grafos no ponderados\n• Complejidad temporal: O(V + E) donde V = vértices, E = aristas\n• Complejidad espacial: O(V)\n\n[b]Aplicaciones:[/b]\n• Encontrar el camino más corto\n• Detección de componentes conectadas\n• Verificar si un grafo es bipartito\n• Redes sociales (grados de separación)",
		"Básico",
		"animation",
		[
			{"title": "Wikipedia - BFS", "url": "https://es.wikipedia.org/wiki/B%C3%BAsqueda_en_amplitud"},
			{"title": "VisuAlgo - BFS Visualization", "url": "https://visualgo.net/en/dfsbfs"},
			{"title": "GeeksforGeeks - BFS", "url": "https://www.geeksforgeeks.org/breadth-first-search-or-bfs-for-a-graph/"}
		],
		["dfs", "queue", "graph"],
		["Mission_1"]
	))
	
	add_term(GlossaryTerm.new(
		"dfs",
		"DFS (Depth-First Search)",
		"Algoritmos de Recorrido",
		"Algoritmo de búsqueda por profundidad que explora lo más lejos posible antes de retroceder.",
		"El DFS (Depth-First Search) o Búsqueda en Profundidad es un algoritmo para recorrer o buscar en estructuras de grafos. Explora cada rama completamente antes de retroceder.\n\n[b]Características:[/b]\n• Utiliza una pila (LIFO) o recursión\n• Puede no encontrar el camino más corto\n• Complejidad temporal: O(V + E)\n• Complejidad espacial: O(V) en el peor caso\n\n[b]Aplicaciones:[/b]\n• Detección de ciclos\n• Ordenamiento topológico\n• Resolución de laberintos\n• Análisis de dependencias\n• Encontrar componentes fuertemente conexas",
		"Básico",
		"animation",
		[
			{"title": "Wikipedia - DFS", "url": "https://es.wikipedia.org/wiki/B%C3%BAsqueda_en_profundidad"},
			{"title": "VisuAlgo - DFS Visualization", "url": "https://visualgo.net/en/dfsbfs"},
			{"title": "GeeksforGeeks - DFS", "url": "https://www.geeksforgeeks.org/depth-first-search-or-dfs-for-a-graph/"}
		],
		["bfs", "stack", "graph"],
		["Mission_1"]
	))
	
	# Caminos Mínimos
	add_term(GlossaryTerm.new(
		"dijkstra",
		"Algoritmo de Dijkstra",
		"Caminos Mínimos",
		"Encuentra el camino más corto desde un origen a todos los demás nodos.",
		"El Algoritmo de Dijkstra es uno de los algoritmos más importantes para encontrar caminos mínimos en grafos ponderados con pesos no negativos.\n\n[b]Características:[/b]\n• Encuentra el camino más corto desde un nodo origen a todos los demás\n• Requiere pesos no negativos\n• Usa una cola de prioridad (min-heap)\n• Complejidad: O((V + E) log V) con heap binario\n\n[b]Funcionamiento:[/b]\n1. Inicializar distancias a infinito excepto el origen (0)\n2. Agregar origen a la cola de prioridad\n3. Extraer nodo con menor distancia\n4. Actualizar distancias de vecinos\n5. Repetir hasta visitar todos los nodos\n\n[b]Aplicaciones:[/b]\n• GPS y sistemas de navegación\n• Enrutamiento de redes\n• Planificación de rutas óptimas",
		"Intermedio",
		"animation",
		[
			{"title": "Wikipedia - Dijkstra", "url": "https://es.wikipedia.org/wiki/Algoritmo_de_Dijkstra"},
			{"title": "VisuAlgo - Dijkstra", "url": "https://visualgo.net/en/sssp"},
			{"title": "Brilliant - Dijkstra", "url": "https://brilliant.org/wiki/dijkstras-short-path-finder/"}
		],
		["shortest_path", "priority_queue", "graph"],
		["Mission_2"]
	))
	
	# Árboles de Expansión
	add_term(GlossaryTerm.new(
		"mst",
		"MST (Minimum Spanning Tree)",
		"Árboles de Expansión",
		"Árbol que conecta todos los nodos con el costo total mínimo.",
		"Un Árbol de Expansión Mínima (MST) es un subconjunto de aristas de un grafo conectado y ponderado que conecta todos los vértices sin formar ciclos y con el peso total mínimo posible.\n\n[b]Propiedades:[/b]\n• Conecta todos los vértices\n• No contiene ciclos (es un árbol)\n• Tiene exactamente V-1 aristas (V = número de vértices)\n• Minimiza la suma total de pesos\n\n[b]Aplicaciones:[/b]\n• Diseño de redes de telecomunicaciones\n• Planificación de rutas de cables\n• Clustering y análisis de datos\n• Diseño de circuitos\n\n[b]Algoritmos principales:[/b]\n• Kruskal: Ordena aristas y las agrega si no forman ciclos\n• Prim: Construye el árbol creciendo desde un nodo inicial",
		"Intermedio",
		"graph",
		[
			{"title": "Wikipedia - MST", "url": "https://es.wikipedia.org/wiki/%C3%81rbol_de_expansi%C3%B3n_m%C3%ADnima"},
			{"title": "VisuAlgo - MST", "url": "https://visualgo.net/en/mst"},
			{"title": "GeeksforGeeks - MST", "url": "https://www.geeksforgeeks.org/minimum-spanning-tree-mst/"}
		],
		["kruskal", "prim", "spanning_tree"],
		["Mission_3"]
	))
	
	add_term(GlossaryTerm.new(
		"kruskal",
		"Algoritmo de Kruskal",
		"Árboles de Expansión",
		"Construye el MST ordenando aristas y agregándolas si no forman ciclos.",
		"El Algoritmo de Kruskal encuentra el MST mediante una estrategia voraz (greedy) que selecciona aristas en orden creciente de peso.\n\n[b]Funcionamiento:[/b]\n1. Ordenar todas las aristas por peso (menor a mayor)\n2. Crear conjuntos disjuntos para cada vértice\n3. Para cada arista en orden:\n   • Si conecta vértices en diferentes conjuntos, agregarla\n   • Unir los conjuntos\n4. Terminar cuando se tengan V-1 aristas\n\n[b]Características:[/b]\n• Complejidad: O(E log E) por el ordenamiento\n• Usa estructura Union-Find (conjuntos disjuntos)\n• Enfoque: selección de aristas (edge-based)\n• Funciona bien con grafos dispersos\n\n[b]Ventajas:[/b]\n• Fácil de implementar\n• Eficiente para grafos con pocas aristas",
		"Intermedio",
		"animation",
		[
			{"title": "Wikipedia - Kruskal", "url": "https://es.wikipedia.org/wiki/Algoritmo_de_Kruskal"},
			{"title": "VisuAlgo - Kruskal", "url": "https://visualgo.net/en/mst"},
			{"title": "GeeksforGeeks - Kruskal", "url": "https://www.geeksforgeeks.org/kruskals-minimum-spanning-tree-algorithm-greedy-algo-2/"}
		],
		["mst", "union_find", "greedy"],
		["Mission_3"]
	))
	
	add_term(GlossaryTerm.new(
		"prim",
		"Algoritmo de Prim",
		"Árboles de Expansión",
		"Construye el MST creciendo el árbol desde un nodo inicial.",
		"El Algoritmo de Prim encuentra el MST construyendo el árbol incrementalmente desde un vértice inicial.\n\n[b]Funcionamiento:[/b]\n1. Iniciar con un vértice arbitrario\n2. Mantener dos conjuntos: vértices en el MST y fuera\n3. Repetir hasta incluir todos los vértices:\n   • Seleccionar la arista de menor peso que conecte el MST con un vértice externo\n   • Agregar el vértice y la arista al MST\n\n[b]Características:[/b]\n• Complejidad: O((V + E) log V) con heap binario\n• Usa cola de prioridad\n• Enfoque: crecimiento de árbol (vertex-based)\n• Funciona bien con grafos densos\n\n[b]Ventajas:[/b]\n• Más eficiente que Kruskal en grafos densos\n• Construye el árbol de forma incremental",
		"Intermedio",
		"animation",
		[
			{"title": "Wikipedia - Prim", "url": "https://es.wikipedia.org/wiki/Algoritmo_de_Prim"},
			{"title": "VisuAlgo - Prim", "url": "https://visualgo.net/en/mst"},
			{"title": "GeeksforGeeks - Prim", "url": "https://www.geeksforgeeks.org/prims-minimum-spanning-tree-mst-greedy-algo-5/"}
		],
		["mst", "priority_queue", "greedy"],
		["Mission_3"]
	))
	
	# Flujo en Redes
	add_term(GlossaryTerm.new(
		"max_flow",
		"Flujo Máximo (Maximum Flow)",
		"Flujo en Redes",
		"Cantidad máxima de flujo que puede pasar desde origen a destino.",
		"El problema de Flujo Máximo busca determinar la mayor cantidad de flujo que puede enviarse desde un nodo fuente a un nodo sumidero en una red de flujo.\n\n[b]Conceptos clave:[/b]\n• Red de flujo: grafo dirigido con capacidades en aristas\n• Fuente (source): nodo origen del flujo\n• Sumidero (sink): nodo destino del flujo\n• Capacidad: cantidad máxima que puede fluir por una arista\n• Flujo: cantidad actual fluyendo por la red\n\n[b]Restricciones:[/b]\n• Conservación: flujo entrante = flujo saliente (excepto fuente/sumidero)\n• Capacidad: flujo en arista ≤ capacidad de la arista\n\n[b]Aplicaciones:[/b]\n• Sistemas de distribución de agua/electricidad\n• Redes de comunicación\n• Asignación de recursos\n• Matching bipartito",
		"Avanzado",
		"graph",
		[
			{"title": "Wikipedia - Flujo Máximo", "url": "https://es.wikipedia.org/wiki/Problema_de_flujo_m%C3%A1ximo"},
			{"title": "VisuAlgo - Max Flow", "url": "https://visualgo.net/en/maxflow"},
			{"title": "Brilliant - Max Flow", "url": "https://brilliant.org/wiki/maximum-flow/"}
		],
		["ford_fulkerson", "edmonds_karp", "network"],
		["Mission_4", "Mission_Final"]
	))
	
	add_term(GlossaryTerm.new(
		"ford_fulkerson",
		"Algoritmo de Ford-Fulkerson",
		"Flujo en Redes",
		"Método para calcular el flujo máximo usando caminos de aumento.",
		"Ford-Fulkerson es un método para encontrar el flujo máximo en una red de flujo. No es un algoritmo específico sino una familia de algoritmos basados en la misma idea.\n\n[b]Concepto de Camino de Aumento:[/b]\nUn camino desde la fuente al sumidero en la red residual donde se puede aumentar el flujo.\n\n[b]Funcionamiento:[/b]\n1. Iniciar con flujo = 0\n2. Mientras exista un camino de aumento:\n   • Encontrar un camino de fuente a sumidero\n   • Determinar la capacidad residual mínima del camino\n   • Aumentar el flujo a lo largo del camino\n3. Retornar el flujo total\n\n[b]Características:[/b]\n• Complejidad: O(E × f*) donde f* es el flujo máximo\n• Puede no terminar con capacidades irracionales\n• La implementación específica depende de cómo se encuentren los caminos",
		"Avanzado",
		"animation",
		[
			{"title": "Wikipedia - Ford-Fulkerson", "url": "https://es.wikipedia.org/wiki/Algoritmo_de_Ford-Fulkerson"},
			{"title": "GeeksforGeeks - Ford-Fulkerson", "url": "https://www.geeksforgeeks.org/ford-fulkerson-algorithm-for-maximum-flow-problem/"},
			{"title": "CP-Algorithms", "url": "https://cp-algorithms.com/graph/edmonds_karp.html"}
		],
		["max_flow", "edmonds_karp", "augmenting_path"],
		["Mission_4"]
	))
	
	add_term(GlossaryTerm.new(
		"edmonds_karp",
		"Algoritmo de Edmonds-Karp",
		"Flujo en Redes",
		"Implementación de Ford-Fulkerson usando BFS para encontrar caminos.",
		"Edmonds-Karp es una implementación específica del método Ford-Fulkerson que usa BFS para encontrar caminos de aumento.\n\n[b]Funcionamiento:[/b]\n1. Crear grafo residual\n2. Mientras BFS encuentre camino de fuente a sumidero:\n   • Usar BFS para encontrar camino más corto\n   • Calcular flujo mínimo en el camino (cuello de botella)\n   • Actualizar capacidades residuales\n   • Agregar flujo al resultado\n3. Retornar flujo máximo\n\n[b]Características:[/b]\n• Complejidad garantizada: O(V × E²)\n• Siempre termina en tiempo finito\n• BFS garantiza el camino más corto\n• Más eficiente que Ford-Fulkerson básico\n\n[b]Ventajas:[/b]\n• Tiempo de ejecución predecible\n• Implementación relativamente simple",
		"Avanzado",
		"animation",
		[
			{"title": "Wikipedia - Edmonds-Karp", "url": "https://es.wikipedia.org/wiki/Algoritmo_de_Edmonds-Karp"},
			{"title": "CP-Algorithms", "url": "https://cp-algorithms.com/graph/edmonds_karp.html"},
			{"title": "GeeksforGeeks", "url": "https://www.geeksforgeeks.org/edmonds-karp-algorithm-for-maximum-flow-problem/"}
		],
		["max_flow", "ford_fulkerson", "bfs"],
		["Mission_4"]
	))
	
	# Estructuras de Datos
	add_term(GlossaryTerm.new(
		"graph",
		"Grafo (Graph)",
		"Conceptos Básicos",
		"Estructura de datos formada por vértices y aristas.",
		"Un grafo es una estructura de datos fundamental compuesta por un conjunto de vértices (nodos) y un conjunto de aristas (edges) que conectan pares de vértices.\n\n[b]Tipos de grafos:[/b]\n• Dirigido: aristas tienen dirección\n• No dirigido: aristas bidireccionales\n• Ponderado: aristas tienen pesos/costos\n• No ponderado: todas las aristas son iguales\n\n[b]Representaciones:[/b]\n• Matriz de adyacencia: matriz V×V\n• Lista de adyacencia: lista de vecinos por nodo\n• Lista de aristas: lista de pares (u, v)\n\n[b]Propiedades:[/b]\n• Grado: número de aristas conectadas a un vértice\n• Camino: secuencia de vértices conectados\n• Ciclo: camino que comienza y termina en el mismo vértice\n• Conectividad: todos los pares de vértices tienen un camino",
		"Básico",
		"diagram",
		[
			{"title": "Wikipedia - Grafo", "url": "https://es.wikipedia.org/wiki/Grafo"},
			{"title": "VisuAlgo - Graph", "url": "https://visualgo.net/en/graphds"},
			{"title": "GeeksforGeeks - Graph", "url": "https://www.geeksforgeeks.org/graph-data-structure-and-algorithms/"}
		],
		["vertex", "edge", "adjacency"],
		["Mission_1", "Mission_2", "Mission_3", "Mission_4"]
	))
	
	add_term(GlossaryTerm.new(
		"queue",
		"Cola (Queue)",
		"Estructuras de Datos",
		"Estructura FIFO (First In, First Out) para almacenar elementos.",
		"Una cola es una estructura de datos lineal que sigue el principio FIFO: el primer elemento en entrar es el primero en salir.\n\n[b]Operaciones básicas:[/b]\n• Enqueue (encolar): agregar elemento al final\n• Dequeue (desencolar): remover elemento del frente\n• Front/Peek: ver el primer elemento sin removerlo\n• IsEmpty: verificar si está vacía\n\n[b]Complejidad:[/b]\n• Enqueue: O(1)\n• Dequeue: O(1)\n• Búsqueda: O(n)\n\n[b]Aplicaciones:[/b]\n• BFS en grafos\n• Procesamiento de tareas (job scheduling)\n• Buffers de impresión\n• Manejo de peticiones en servidores",
		"Básico",
		"diagram",
		[
			{"title": "Wikipedia - Cola", "url": "https://es.wikipedia.org/wiki/Cola_(inform%C3%A1tica)"},
			{"title": "VisuAlgo - Queue", "url": "https://visualgo.net/en/list"},
			{"title": "GeeksforGeeks - Queue", "url": "https://www.geeksforgeeks.org/queue-data-structure/"}
		],
		["bfs", "stack"],
		["Mission_1"]
	))
	
	add_term(GlossaryTerm.new(
		"stack",
		"Pila (Stack)",
		"Estructuras de Datos",
		"Estructura LIFO (Last In, First Out) para almacenar elementos.",
		"Una pila es una estructura de datos lineal que sigue el principio LIFO: el último elemento en entrar es el primero en salir.\n\n[b]Operaciones básicas:[/b]\n• Push: agregar elemento en la cima\n• Pop: remover elemento de la cima\n• Top/Peek: ver el elemento en la cima sin removerlo\n• IsEmpty: verificar si está vacía\n\n[b]Complejidad:[/b]\n• Push: O(1)\n• Pop: O(1)\n• Búsqueda: O(n)\n\n[b]Aplicaciones:[/b]\n• DFS en grafos\n• Evaluación de expresiones\n• Deshacer/Rehacer (Undo/Redo)\n• Navegación del historial del navegador\n• Gestión de llamadas recursivas",
		"Básico",
		"diagram",
		[
			{"title": "Wikipedia - Pila", "url": "https://es.wikipedia.org/wiki/Pila_(inform%C3%A1tica)"},
			{"title": "VisuAlgo - Stack", "url": "https://visualgo.net/en/list"},
			{"title": "GeeksforGeeks - Stack", "url": "https://www.geeksforgeeks.org/stack-data-structure/"}
		],
		["dfs", "queue"],
		["Mission_1"]
	))
	
	add_term(GlossaryTerm.new(
		"priority_queue",
		"Cola de Prioridad (Priority Queue)",
		"Estructuras de Datos",
		"Cola donde cada elemento tiene una prioridad asociada.",
		"Una cola de prioridad es una estructura de datos donde cada elemento tiene una prioridad, y los elementos se procesan según su prioridad.\n\n[b]Características:[/b]\n• Elemento con mayor (o menor) prioridad se procesa primero\n• Típicamente implementada con heap\n• Diferentes de colas normales (no FIFO)\n\n[b]Operaciones:[/b]\n• Insert: agregar elemento con prioridad - O(log n)\n• ExtractMax/Min: remover elemento prioritario - O(log n)\n• Peek: ver elemento prioritario - O(1)\n• ChangePriority: modificar prioridad - O(log n)\n\n[b]Aplicaciones:[/b]\n• Algoritmo de Dijkstra\n• Algoritmo de Prim\n• Schedulers de sistemas operativos\n• Simulaciones de eventos\n• A* pathfinding",
		"Intermedio",
		"diagram",
		[
			{"title": "Wikipedia - Priority Queue", "url": "https://es.wikipedia.org/wiki/Cola_de_prioridad"},
			{"title": "VisuAlgo - Heap", "url": "https://visualgo.net/en/heap"},
			{"title": "GeeksforGeeks", "url": "https://www.geeksforgeeks.org/priority-queue-set-1-introduction/"}
		],
		["dijkstra", "prim", "heap"],
		["Mission_2", "Mission_3"]
	))
	
	add_term(GlossaryTerm.new(
		"union_find",
		"Union-Find (Conjuntos Disjuntos)",
		"Estructuras de Datos",
		"Estructura para rastrear elementos particionados en conjuntos disjuntos.",
		"Union-Find o Disjoint Set Union (DSU) es una estructura de datos que mantiene una colección de conjuntos disjuntos y soporta dos operaciones principales.\n\n[b]Operaciones:[/b]\n• Find: determinar a qué conjunto pertenece un elemento\n• Union: unir dos conjuntos en uno solo\n\n[b]Optimizaciones:[/b]\n• Path compression: acortar caminos en Find\n• Union by rank/size: unir árbol pequeño bajo el grande\n• Con optimizaciones: casi O(1) amortizado\n\n[b]Aplicaciones:[/b]\n• Algoritmo de Kruskal (MST)\n• Detección de ciclos en grafos\n• Componentes conectadas dinámicas\n• Problemas de conectividad\n• Percolación en física\n\n[b]Complejidad:[/b]\nO(α(n)) por operación, donde α es la función inversa de Ackermann (prácticamente constante)",
		"Intermedio",
		"diagram",
		[
			{"title": "Wikipedia - Union-Find", "url": "https://es.wikipedia.org/wiki/Estructura_de_datos_para_conjuntos_disjuntos"},
			{"title": "VisuAlgo - Union-Find", "url": "https://visualgo.net/en/ufds"},
			{"title": "CP-Algorithms", "url": "https://cp-algorithms.com/data_structures/disjoint_set_union.html"}
		],
		["kruskal", "mst"],
		["Mission_3"]
	))
	
	# Conceptos adicionales
	add_term(GlossaryTerm.new(
		"greedy",
		"Algoritmo Voraz (Greedy)",
		"Conceptos Básicos",
		"Estrategia que toma la mejor decisión local en cada paso.",
		"Un algoritmo voraz (greedy) es un paradigma que construye una solución tomando en cada paso la opción que parece mejor en ese momento (óptimo local).\n\n[b]Características:[/b]\n• Toma decisiones irrevocables\n• No reconsider opciones pasadas\n• Simple de implementar\n• No siempre garantiza la solución óptima global\n\n[b]Cuándo funciona:[/b]\nSe requieren dos propiedades:\n1. Propiedad de elección voraz: elección local óptima lleva a solución global óptima\n2. Subestructura óptima: solución óptima contiene soluciones óptimas de subproblemas\n\n[b]Ejemplos de algoritmos voraces:[/b]\n• Dijkstra (camino mínimo)\n• Kruskal y Prim (MST)\n• Huffman (compresión)\n• Cambio de monedas (con ciertas denominaciones)",
		"Intermedio",
		"diagram",
		[
			{"title": "Wikipedia - Greedy", "url": "https://es.wikipedia.org/wiki/Algoritmo_voraz"},
			{"title": "GeeksforGeeks - Greedy", "url": "https://www.geeksforgeeks.org/greedy-algorithms/"},
			{"title": "Brilliant - Greedy", "url": "https://brilliant.org/wiki/greedy-algorithm/"}
		],
		["dijkstra", "kruskal", "prim"],
		["Mission_2", "Mission_3"]
	))
	
	add_term(GlossaryTerm.new(
		"complexity",
		"Complejidad Algorítmica",
		"Conceptos Básicos",
		"Medida de recursos (tiempo/espacio) que requiere un algoritmo.",
		"La complejidad algorítmica mide los recursos necesarios para ejecutar un algoritmo en función del tamaño de entrada.\n\n[b]Tipos de complejidad:[/b]\n• Temporal: tiempo de ejecución\n• Espacial: memoria utilizada\n\n[b]Notación Big-O:[/b]\nDescribe el peor caso asintótico:\n• O(1): Constante\n• O(log n): Logarítmica\n• O(n): Lineal\n• O(n log n): Lineal-logarítmica\n• O(n²): Cuadrática\n• O(2ⁿ): Exponencial\n\n[b]Análisis:[/b]\n• Mejor caso: mínimo tiempo posible\n• Caso promedio: tiempo esperado\n• Peor caso: máximo tiempo posible\n\n[b]Importancia:[/b]\nPermite comparar algoritmos y predecir su comportamiento con entradas grandes.",
		"Básico",
		"diagram",
		[
			{"title": "Wikipedia - Complejidad", "url": "https://es.wikipedia.org/wiki/Cota_superior_asint%C3%B3tica"},
			{"title": "Big-O Cheat Sheet", "url": "https://www.bigocheatsheet.com/"},
			{"title": "GeeksforGeeks", "url": "https://www.geeksforgeeks.org/understanding-time-complexity-simple-examples/"}
		],
		[],
		["Mission_1", "Mission_2", "Mission_3", "Mission_4"]
	))

func add_term(term: GlossaryTerm) -> void:
	terms[term.id] = term

func get_term(id: String) -> GlossaryTerm:
	return terms.get(id, null)

func get_all_terms() -> Array[GlossaryTerm]:
	var result: Array[GlossaryTerm] = []
	for term in terms.values():
		result.append(term)
	return result

func get_terms_by_category(category: String) -> Array[GlossaryTerm]:
	var result: Array[GlossaryTerm] = []
	for term in terms.values():
		if term.category == category:
			result.append(term)
	return result

func search_terms(query: String) -> Array[GlossaryTerm]:
	var result: Array[GlossaryTerm] = []
	var lower_query = query.to_lower()
	
	for term in terms.values():
		if (term.name.to_lower().contains(lower_query) or
			term.short_description.to_lower().contains(lower_query) or
			term.full_description.to_lower().contains(lower_query)):
			result.append(term)
	
	return result

func get_categories() -> Array[String]:
	return categories.duplicate()

func get_terms_used_in_mission(mission_id: String) -> Array[GlossaryTerm]:
	var result: Array[GlossaryTerm] = []
	for term in terms.values():
		if mission_id in term.used_in_missions:
			result.append(term)
	return result

func get_related_terms(term_id: String) -> Array[GlossaryTerm]:
	var result: Array[GlossaryTerm] = []
	var term = get_term(term_id)
	if term:
		for related_id in term.related_terms:
			var related_term = get_term(related_id)
			if related_term:
				result.append(related_term)
	return result
