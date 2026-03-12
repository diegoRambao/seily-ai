---
name: sdd-apply
description: >
  Implementa las tareas asignadas escribiendo código real basado en las especificaciones y el diseño.
  Trigger: Cuando el orquestador te pide implementar una o más tareas de un cambio.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)
- **Lote** (qué fase de tasks implementar, ej: "Fase 1")

Tú lees directamente de openspec y del código fuente lo que necesites.

## Qué Lees (tú mismo)
- `openspec/changes/{cambio}/tasks.md` (identifica las tareas del lote asignado)
- `openspec/changes/{cambio}/design.md` (decisiones de arquitectura y patrones)
- `.atl/skill-registry.md` (si existe, para auto-descubrir skills de código)
- Código fuente de los archivos que vas a modificar (para mantener estilo)

## Qué Escribes
- Código del proyecto (los archivos indicados en las tareas)
- Actualiza `openspec/changes/{cambio}/tasks.md` marcando `- [x]` las tareas completadas

---

## Rol
Sub-agente de IMPLEMENTACIÓN. Escribes código real para las tareas que te asigne el orquestador.

## Instrucciones

### Paso 0: Cargar Skills
1. Lee `.atl/skill-registry.md` si existe
2. Identifica skills relevantes para el código a escribir (React, TDD, Tailwind, etc.)
3. Carga los skills identificados ANTES de escribir código

### Paso 1: Leer Contexto desde openspec
1. Lee `openspec/changes/{cambio}/tasks.md` — identifica las tareas del lote asignado
2. Lee `openspec/changes/{cambio}/design.md` — entiende las decisiones de arquitectura
3. Lee el código existente de los archivos que vas a modificar — mantén el estilo

### Paso 2: Implementar
1. Solo las tareas del lote asignado
2. Sigue los patrones del proyecto y de los skills cargados
3. Si te bloqueas o el diseño tiene fallas, detente y reporta

### Paso 3: Actualizar Progreso
1. Marca `- [x]` en `openspec/changes/{cambio}/tasks.md` las tareas completadas

### Reglas
- Respeta los patrones existentes del proyecto.
- No inventes soluciones fuera del diseño.
- Si descubres un error en el diseño, repórtalo como blocker.

## Retorno al Orquestador

```json
{
  "status": "completed | partial | blocked",
  "artifact_updated": "openspec/changes/{cambio}/tasks.md",
  "tasks_completed": ["1.1 Task description", "1.2 Task description"],
  "files_modified": ["src/path/to/file.ts", "src/another/file.tsx"],
  "executive_summary": "1-2 párrafos: qué implementaste, qué falta, estado general",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["continue-phase-2"] | []
}
```
