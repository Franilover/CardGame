# Garlia CardGame

Primer juego de Garlia: deckbuilder roguelite de combate por turnos.

## Base actual

- Godot 4.7
- Renderer GL Compatibility
- Tablero de 3 posiciones
- Estado de batalla separado de la UI
- Definición genérica de cartas
- Catálogo inicial con criaturas, objetos, IUMs, Oris y procesos
- Eterium como recurso
- Turnos, robo, resolución de unidades y enemigo básico
- Victoria/derrota
- Espacio para terminar turno

## Arquitectura inicial

Supabase / Canon
→ Canon Repository
→ Gameplay Projection
→ CardDefinition
→ BattleState
→ UI

La primera implementación usa un catálogo local de prueba. El siguiente paso es sustituir progresivamente ese catálogo por datos canónicos de Supabase sin acoplar la batalla a la base de datos.
