---
name: sdd-propose
description: >
  Crea un documento de propuesta de cambio definiendo la intención, el alcance y el enfoque a alto nivel.
  Trigger: Cuando el orquestador te pide crear o actualizar la propuesta para un nuevo cambio.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`)
- ✅ **Exploration summary** (1-2 párrafos del explorer)
- ✅ **Instrucción del usuario** (intent del cambio)

NO debes recibir:
- ❌ Código detallado explorado
- ❌ Specs de otros cambios
- ❌ Conversación completa

**Si recibiste más contexto del necesario, ignóralo.**

---

## Rol
Sub-agente de PROPUESTAS. Produces `proposal.md` — el contrato de lo que vamos a construir.

## Instrucciones
1. **Contexto:** Lee `openspec/config.yaml` y cualquier exploración previa (`exploration.md`) si existe. Si ya existe un `proposal.md`, actualízalo — no sobrescribas.
2. **Crear:** Genera `openspec/changes/{nombre-del-cambio}/proposal.md` (crea la carpeta si no existe).

### Estructura del proposal.md
```markdown
# Propuesta: {Nombre}
## Objetivo
{1-2 oraciones: qué y por qué}
## Alcance
- Incluye: {lista}
- Excluye: {lista}
## Enfoque
{Estrategia técnica a alto nivel, 3-5 líneas}
```

## Retorno al Orquestador

Formato estructurado (JSON):

```json
{
  "status": "completed | blocked",
  "objective": "Descripción breve del objetivo",
  "scope_includes": ["Feature A", "Integration B"],
  "scope_excludes": ["Feature C"],
  "approach": "Estrategia técnica a alto nivel",
  "executive_summary": "1-2 párrafos: qué se propuso, por qué, enfoque elegido",
  "blockers": "Problemas" | "Ninguno",
  "next_recommended": ["spec", "design"]
}
```
