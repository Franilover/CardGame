# Garlia CardGame — Arquitectura FASE 00

## Estado

FASE 00A: Foundation validada mediante smoke test.

FASE 00B: campo de batalla unificado, pantalla de batalla y mezclador estructural.

## Flujo obligatorio

UI
-> BattleCommand
-> BattleValidator
-> BattleEngine
-> BattleState
-> BattleEvent
-> UI / Debug

Supabase entrega canon; nunca resuelve directamente una batalla.

## Campo de batalla

Un solo campo compartido de 9 x 8 = 72 casillas.

Zonas iniciales:

- filas 0-2: enemigo
- filas 3-4: centro
- filas 5-7: jugador

BattleBoard administra ocupación, propietario, terreno, bloqueos, distancia y posiciones.

## Pantalla de batalla

La pantalla central contiene:

- personaje enemigo con retrato y vida
- personaje jugador con retrato y vida
- campo de batalla
- inventario de cartas
- mezclador 3 x 3
- indicador de Eterium
- procesar
- terminar turno
- retroceder

La interfaz solo crea controles, mantiene selección y envía comandos.

## Mezclador

MixerState guarda nueve posiciones.

MixerEngine solamente reconoce una mezcla cuando existe una receta estructurada en el canon de procesos.

No se inventan recetas en Godot.

La condición esperada para una receta es una lista estructurada de identificadores IUM en los datos de proceso. Mientras esa relación no exista, la interfaz muestra los IUM colocados pero no genera un proceso ficticio.

## Unidades

CardDefinition conserva:

- vida
- ataque
- armadura
- movimiento
- alcance
- contraataque
- estado de acción
- agotamiento

Una unidad realiza una acción por turno: mover o atacar.

Una unidad recién invocada comienza agotada.

La geometría usa distancia Chebyshev inicialmente para mantener una lógica espacial simple y extensible.

## Diagnóstico

Todos los comandos pasan por BattleValidator y BattleEngine.

BattleEngine emite BattleEvent y registra eventos en GarliaDiagnostics.

## Reglas de arquitectura

- No agregar nueva lógica de gameplay a scripts/main.gd.
- La UI nunca modifica BattleState directamente.
- BattleEngine es la frontera de ejecución de comandos.
- BattleState conserva estado y comportamiento de transición mientras se extraen los resolvers especializados.
- BattleBoard es el dueño de ocupación y posiciones.
- Supabase no se consulta desde BattleEngine ni BattleState.

## Próximos pasos

1. Extraer DamageResolver.
2. Extraer MovementResolver.
3. Extraer AttackResolver.
4. Crear BoardCatalog.
5. Crear EncounterCatalog.
6. Añadir reglas de tablero.
7. Añadir recetas estructuradas IUM -> Proceso al canon.
8. Crear cinco encuentros únicos.
9. Progresión de run.
10. Arena.
11. Online.
