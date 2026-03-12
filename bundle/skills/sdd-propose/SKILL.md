---
name: sdd-propose
description: >
  Crea un documento de propuesta de cambio definiendo la intención, el alcance y el enfoque a alto nivel.
  Trigger: Cuando el orquestador te pide crear o actualizar la propuesta para un nuevo cambio.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)

Tú lees directamente de openspec lo que necesites.

## Qué Lees (tú mismo)
- `openspec/config.yaml` (contexto del proyecto)
- `openspec/changes/{cambio}/exploration.md` (si existe)
- `openspec/changes/{cambio}/prd.md` (si existe un documento externo)

## Qué Escribes
- `openspec/changes/{cambio}/proposal.md`

---

## Rol
Sub-agente de PROPUESTAS. Produces `proposal.md` — el contrato de lo que vamos a construir.

## Instrucciones
1. **Contexto:** Lee `openspec/config.yaml` y `openspec/changes/{cambio}/exploration.md` si existe. Si ya existe un `proposal.md`, actualízalo — no sobrescribas.
2. **Crear:** Genera `openspec/changes/{cambio}/proposal.md` (crea la carpeta si no existe).

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

```json
{
  "status": "completed | blocked",
  "artifact_written": "openspec/changes/{cambio}/proposal.md",
  "executive_summary": "1-2 párrafos: qué se propuso, por qué, enfoque elegido",
  "blockers": "Problemas" | "Ninguno",
  "next_recommended": ["spec", "design"]
}
```
