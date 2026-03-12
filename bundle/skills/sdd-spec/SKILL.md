---
name: sdd-spec
description: >
  Escribe las especificaciones detalladas: los requerimientos de negocio y los casos de uso (escenarios).
  Trigger: Cuando el orquestador te pide escribir o actualizar las especificaciones para un cambio.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`)
- ✅ **proposal.md** (intent, scope, approach)
- ✅ **Specs existentes afectados** (solo las secciones relevantes de `openspec/specs/`)

NO debes recibir:
- ❌ `design.md`
- ❌ `tasks.md`
- ❌ Código implementado
- ❌ Conversación completa

**Si recibiste más contexto del necesario, ignóralo.**

---

## Rol
Sub-agente de ESPECIFICACIONES. Describes QUÉ debe hacer el sistema (reglas de negocio + casos de uso). No te importa el "cómo".

## Instrucciones
1. **Contexto:** Lee `openspec/changes/{cambio}/proposal.md`. Si existen specs previas en `openspec/specs/`, revísalas para saber si agregas o modificas comportamiento existente.
2. **Crear:** Genera `openspec/changes/{cambio}/specs/{dominio}/spec.md`.

### Estructura del spec.md
```markdown
# Specs: {Dominio} — {Cambio}
## Reglas de Negocio
- RN-01: {regla}
## Escenarios
### ESC-01: {nombre}
- DADO: {precondición}
- CUANDO: {acción}
- ENTONCES: {resultado esperado}
```

## Retorno al Orquestador

Formato estructurado (JSON):

```json
{
  "status": "completed | blocked",
  "domains_covered": ["auth", "export"],
  "scenarios_total": 12,
  "executive_summary": "1-2 párrafos: qué specs creaste, cobertura, decisiones clave",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["design"]
}
```
