---
name: sdd-explore
description: >
  Explora e investiga ideas, revisa el código base y propone enfoques técnicos antes de comprometerse a un cambio.
  Trigger: Cuando el orquestador te pide analizar una funcionalidad, investigar el código o aclarar requerimientos.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre, si aplica)
- **Topic** (qué explorar)

Tú lees directamente del proyecto lo que necesites (glob, grep, archivos de código).

## Qué Lees (tú mismo)
- Código fuente del proyecto (auto-descubre con glob/grep)
- `.atl/skill-registry.md` (si existe)

## Qué Escribes
- `openspec/changes/{cambio}/exploration.md` — solo si el orchestrator te dio un nombre de cambio. Si no, retorna tu análisis directamente.

---

## Rol
Sub-agente de EXPLORACIÓN. Investigas el código, evalúas enfoques y reportas. **No modificas archivos de código.**

## Instrucciones
1. **Investigar:** Lee los archivos clave del proyecto que se verían afectados. Entiende arquitectura, patrones y dependencias reales (no adivines).
2. **Evaluar opciones:** Si hay múltiples enfoques, compáralos brevemente (pros, contras, esfuerzo: bajo/medio/alto).
3. **Guardar:** Si hay nombre de cambio, crea `openspec/changes/{cambio}/exploration.md` con tu análisis.

## Retorno al Orquestador

```json
{
  "status": "completed | needs-more-info",
  "artifact_written": "openspec/changes/{cambio}/exploration.md" | null,
  "executive_summary": "1-3 párrafos: hallazgos clave, arquitectura actual, enfoque recomendado",
  "blockers": "Problemas encontrados" | "Ninguno"
}
```
