---
name: sdd-tasks
description: >
  Desglosa el diseño y las especificaciones en una lista de tareas de implementación paso a paso.
  Trigger: Cuando el orquestador te pide crear o actualizar el desglose de tareas para un cambio.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`)
- ✅ **design.md** (arquitectura y decisiones clave)
- ✅ **specs.md** (solo para referencia rápida de cobertura)

NO debes recibir:
- ❌ `proposal.md` completo
- ❌ Conversación inicial
- ❌ Exploration details

**Si recibiste más contexto del necesario, ignóralo.**

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

Formato estructurado (JSON):

```json
{
  "status": "completed | blocked",
  "phases": 3,
  "total_tasks": 12,
  "phase_breakdown": {
    "Phase 1 - Foundation": 4,
    "Phase 2 - UI": 5,
    "Phase 3 - Integration": 3
  },
  "executive_summary": "1-2 párrafos: estructura de fases, criterios de agrupación, estimación",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["apply"]
}
```
