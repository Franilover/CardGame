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

## Acciones

Cada turno tienes 2 acciones.
Mover una criatura o héroe consume 1 acción.
Atacar consume 1 acción.
Jugar una criatura consume 1 acción.
Una criatura puede moverse y atacar en el mismo turno si todavía quedan acciones.

## Eterium

Eterium comienza en 3 y aumenta en 1 su máximo cada turno, restaurándose al nuevo máximo.
No se consume al mover ni al atacar.
Se consume al crear o usar IUMs y para desplegar una criatura fuera de la fila trasera.

## Despliegue

Las criaturas entran gratis por la fila trasera.
Colocarlas en otra casilla de la zona del jugador consume 1 Eterium además de la acción de jugar.

## Ataque del Rey

El Rey tiene un ataque especial que consume 1 acción.
Se puede elegir una de cuatro direcciones: arriba, abajo, izquierda o derecha.
La dirección seleccionada golpea las 3 casillas frontales del Rey simultáneamente.
Si una dirección no permite formar las 3 casillas dentro del tablero, esa dirección se deshabilita.

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
