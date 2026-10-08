# Garlia CardGame

Primer juego de Garlia: deckbuilder roguelite de combate por turnos.

## Estado actual

- Godot 4.7
- Renderer GL Compatibility
- Pantalla de carga con bootstrap
- Menú principal
- Colección de cartas
- Tablero 3x3 por jugador
- Mazo y mano
- Eterium
- Puntos de acción
- Invocación de criaturas
- Ataques con objetivos
- Combate criatura contra criatura
- Objetos con mejoras
- IUMs, procesos y Oris con efectos
- IA enemiga
- Robo, límite de mano y fatiga
- Descarte
- Victoria / derrota
- Reinicio y regreso al menú
- Catálogo canónico de Supabase
- Caché local para jugar sin conexión
- Fallback completo a catálogo local

## Arquitectura

Supabase / Canon
→ SupabaseClient
→ CanonRepository
→ caché local
→ CardCatalog
→ CardDefinition
→ BattleState
→ UI

La batalla no consulta Supabase directamente. El repositorio carga los datos canónicos y los proyecta a cartas jugables. Esto mantiene el motor de combate desacoplado de la base de datos.

## Datos canónicos cargados

El cliente intenta sincronizar:

- criaturas
- items
- items_game
- iums
- oris
- procesos
- personajes_game
- reinos_game

Las criaturas aprovechan datos existentes como stats_dnd, biologia_calculada e ia_config cuando están disponibles. Los objetos combinan items con items_game.

La colección de cartas utiliza el mismo repositorio, por lo que sirve también como comprobación visual de la sincronización del canon.

## Supabase

El proyecto utiliza la Data REST API de Supabase.

La aplicación distribuida no debe contener secret keys ni service_role. El cliente usa una publishable key suministrada externamente.

Configuración aceptada:

- Variable de entorno GARLIA_SUPABASE_PUBLISHABLE_KEY
- Archivo user://garlia_supabase_key.txt

Cuando existe conexión, el juego sincroniza el canon y crea el caché local en:

user://garlia_cardgame_canon.json

Cuando no existe conexión, usa el caché anterior. Sin caché, usa el catálogo local de desarrollo.

## Seguridad

La base de datos actual todavía tiene advertencias de seguridad que son independientes del juego, incluyendo tablas públicas con RLS deshabilitado y varias funciones SECURITY DEFINER accesibles desde roles externos.

No se habilita RLS automáticamente desde CardGame porque hacerlo sin políticas puede bloquear el acceso legítimo. Estas políticas deben diseñarse según la intención de cada tabla antes de permitir operaciones de escritura desde un cliente público.

## Próximos sistemas

- Construcción y edición de mazos
- Colección persistente por jugador
- Selección de personaje
- Recompensas de run
- Encuentros y jefes
- Habilidades y estados persistentes
- Proyección más profunda de procesos, IUMs y Oris
- Guardado local
- Sincronización de progreso autenticado
- Online
- Multiplayer posteriormente
