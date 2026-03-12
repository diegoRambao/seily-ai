---
name: sdd-spec
description: >
  Escribe las especificaciones detalladas: los requerimientos de negocio y los casos de uso (escenarios).
  Trigger: Cuando el orquestador te pide escribir o actualizar las especificaciones para un cambio.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)

Tú lees directamente de openspec lo que necesites.

## Qué Lees (tú mismo)
- `openspec/changes/{cambio}/proposal.md`
- `openspec/specs/` (specs existentes, para saber si agregas o modificas comportamiento)

## Qué Escribes
- `openspec/changes/{cambio}/specs/{dominio}/spec.md`

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

```json
{
  "status": "completed | blocked",
  "artifact_written": "openspec/changes/{cambio}/specs/",
  "domains_covered": ["auth", "export"],
  "scenarios_total": 12,
  "executive_summary": "1-2 párrafos: qué specs creaste, cobertura, decisiones clave",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["design"]
}
```
