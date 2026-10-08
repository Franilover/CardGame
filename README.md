# Garlia CardGame

Primer juego de Garlia: deckbuilder roguelite táctico de combate por turnos.

## Estado actual

- Godot 4.7
- Renderer GL Compatibility
- Pantalla de carga
- Menú principal
- Colección de cartas
- Campo compartido 9x8
- Rey/Reina permanente con trono y condición de derrota
- Inventario de cartas
- Mezclador IUM 3x3
- Indicador de Eterium
- Movimiento y ataques por casillas
- Comandos y eventos
- Diagnóstico centralizado
- Smoke test headless
- Catálogo canónico de Supabase
- Caché local offline

## Arquitectura

Supabase / Canon
-> SupabaseClient
-> CanonRepository
-> caché local
-> GameCatalogs
-> Definitions
-> BattleCommand
-> BattleValidator
-> BattleEngine
-> BattleState
-> BattleEvent
-> UI / Debug

La batalla no consulta Supabase directamente.

## Campo

Un único campo de batalla compartido de 9x8.

- fila 0, columna 4: trono de la Reina enemiga
- filas 0-2: zona enemiga
- filas 3-4: centro neutral
- filas 5-7: zona inicial del jugador
- fila 7, columna 4: trono del Rey del jugador

Los tronos son casillas exclusivas de los héroes. Las criaturas no pueden ocuparlas.
Cada bando tiene un Rey/Reina permanente fuera del mazo con 30 V. Derrotar al héroe enemigo termina la ronda inmediatamente.

## Movimiento

Mover una criatura cuesta 1 Eterium y no consume una acción de turno.
Cada criatura puede moverse una vez por turno, hasta su atributo de movimiento. El Rey/Reina no puede moverse.

## Mezclador

El mezclador es una rejilla 3x3 para preparar IUMs.
Las recetas de procesos deben existir como datos estructurados del canon antes de producir un proceso.

## Próximos sistemas

- DamageResolver
- MovementResolver
- AttackResolver
- BoardCatalog
- EncounterCatalog
- reglas únicas por tablero
- recompensas de run
- colección persistente
- Arena
- Online
