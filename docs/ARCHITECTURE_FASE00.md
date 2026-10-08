# Garlia CardGame — Arquitectura FASE 00

## Objetivo

Crear una frontera clara entre interfaz, comandos, motor de batalla y estado.
La batalla existente permanece como implementación de transición para no romper el prototipo.

## Flujo obligatorio

UI -> BattleCommand -> BattleValidator -> BattleEngine -> BattleState -> BattleEvent -> UI / Debug

Supabase no participa directamente en la resolución de combate.

## Responsabilidades

### BattleCommand

Describe una intención del jugador.
No modifica estado.

### BattleValidator

Comprueba si el comando puede ejecutarse.
No modifica estado.

### BattleEngine

Único punto autorizado para ejecutar comandos durante una batalla.
En FASE 00 funciona como fachada sobre BattleState.

### BattleState

Mantiene el estado actual de la partida.
En fases posteriores se irá vaciando de lógica de resolución.

### BattleEvent

Describe algo que ya ocurrió.
Será la base de UI reactiva, diagnóstico, replay y online.

### Definitions

BoardDefinition, BoardCellDefinition, RuleDefinition y EncounterDefinition contienen datos.
No ejecutan reglas de combate.

### DiagnosticsService

Centraliza contexto, sesión, nivel, sistema, evento y datos de diagnóstico.

## Regla crítica

Nunca agregar lógica nueva de gameplay a scripts/main.gd.

Nunca hacer que la UI cambie directamente BattleState.

Nunca hacer consultas de Supabase desde BattleEngine o BattleState.

## Migración

1. Integrar BattleEngine en la UI existente.
2. Confirmar que el prototipo sigue funcionando.
3. Mover resolución real desde BattleState a BattleEngine gradualmente.
4. Añadir BoardDefinition y EncounterDefinition al flujo real.
5. Añadir RuleResolver.
6. Reemplazar efectos hardcodeados por definiciones declarativas.

## Gate FASE 00A

Antes de pasar a la migración de UI, el proyecto debe:

- arrancar sin errores de parseo;
- cargar el autoload GarliaDiagnostics;
- poder ejecutar BattleSmokeTest;
- conservar el combate actual intacto;
- permitir rastrear comandos y eventos desde BattleEngine.

La validación real del proyecto Godot debe ejecutarse localmente porque este repositorio no se ejecuta dentro del entorno de esta edición.
