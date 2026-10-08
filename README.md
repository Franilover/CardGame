# Garlia CardGame

Primer juego de Garlia: deckbuilder roguelite táctico de combate por turnos.

## Estado actual

- Godot 4.7
- Renderer GL Compatibility
- Pantalla de carga
- Menú principal
- Colección de cartas
- Campo compartido 9x8
- Personajes con vida
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

- filas 0-2: zona enemiga
- filas 3-4: centro neutral
- filas 5-7: zona inicial del jugador

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
