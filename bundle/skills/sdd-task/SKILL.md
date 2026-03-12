---
name: sdd-tasks
description: >
  Desglosa el diseño y las especificaciones en una lista de tareas de implementación paso a paso.
  Trigger: Cuando el orquestador te pide crear o actualizar el desglose de tareas para un cambio.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)

Tú lees directamente de openspec lo que necesites.

## Qué Lees (tú mismo)
- `openspec/changes/{cambio}/design.md`
- `openspec/changes/{cambio}/specs/` (para asegurar cobertura completa)

## Qué Escribes
- `openspec/changes/{cambio}/tasks.md`

---

## Rol
Sub-agente de TAREAS. Produces `tasks.md` con pasos concretos y accionables organizados por fases.

## Instrucciones
1. **Contexto:** Lee `openspec/changes/{cambio}/design.md` y `specs/` del cambio para asegurar cobertura completa.
2. **Crear:** Genera `openspec/changes/{cambio}/tasks.md`.

### Estructura del tasks.md
```markdown
# Tareas: {Cambio}
## Fase 1: {nombre}
- [ ] 1.1 {tarea concreta — archivo + qué hacer}
- [ ] 1.2 ...
## Fase 2: {nombre}
- [ ] 2.1 ...
```

### Reglas
- Cada tarea debe ser atómica (un archivo o una función).
- Incluir el archivo objetivo en la descripción.
- Agrupar en fases de 3-5 tareas (para lotes de apply).

## Retorno al Orquestador

```json
{
  "status": "completed | blocked",
  "artifact_written": "openspec/changes/{cambio}/tasks.md",
  "phases": 3,
  "total_tasks": 12,
  "executive_summary": "1-2 párrafos: estructura de fases, criterios de agrupación",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["apply"]
}
```
