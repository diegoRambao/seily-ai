---
name: sdd-archive
description: >
  Sincroniza las especificaciones finales con la documentación principal y archiva el cambio completado.
  Trigger: Cuando el orquestador te pide archivar un cambio tras su implementación y verificación.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)

Tú lees directamente de openspec lo que necesites.

## Qué Lees (tú mismo)
- `openspec/changes/{cambio}/tasks.md` (verificar que todas las tareas estén completas)
- `openspec/changes/{cambio}/verify-report.md` (verificar que no haya errores críticos)
- `openspec/changes/{cambio}/specs/` (specs del cambio para fusionar)
- `openspec/specs/` (specs principales del proyecto)

## Qué Escribes
- Actualiza `openspec/specs/` (fusiona specs del cambio con los principales)
- Mueve `openspec/changes/{cambio}/` → `openspec/changes/archive/{YYYY-MM-DD}-{cambio}/`

---

## Rol
Sub-agente de ARCHIVO. Sincronizas docs y mueves artefactos al historial.

## Instrucciones
1. **Verificar estado:** Revisa `tasks.md` y `verify-report.md`. NUNCA archives si hay errores críticos pendientes o tareas incompletas — detente y avisa.
2. **Actualizar docs:** Fusiona las specs del cambio con la documentación principal en `openspec/specs/`.
3. **Archivar:** Mueve `openspec/changes/{cambio}/` → `openspec/changes/archive/{YYYY-MM-DD}-{cambio}/`.

## Retorno al Orquestador

```json
{
  "status": "archived | blocked",
  "artifact_written": "openspec/changes/archive/{YYYY-MM-DD}-{cambio}/",
  "archive_path": "openspec/changes/archive/2026-03-12-nombre-del-cambio",
  "docs_updated": ["openspec/specs/auth/spec.md", "openspec/specs/export/spec.md"],
  "executive_summary": "1-2 párrafos: qué se archivó, docs fusionadas, estado final",
  "blockers": "Tareas pendientes o errores críticos" | "Ninguno"
}
```
