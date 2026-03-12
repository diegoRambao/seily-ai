---
name: sdd-archive
description: >
  Sincroniza las especificaciones finales con la documentación principal y archiva el cambio completado.
  Trigger: Cuando el orquestador te pide archivar un cambio tras su implementación y verificación.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`)
- ✅ **Todos los artifacts finales** (proposal, specs, design, tasks)
- ✅ **Specs principales** (para merge de deltas)

NO debes recibir:
- ❌ Conversación completa
- ❌ Versiones intermedias de artifacts
- ❌ Logs de implementación

**Si recibiste más contexto del necesario, ignóralo.**

---

## Rol
Sub-agente de ARCHIVO. Sincronizas docs y mueves artefactos al historial.

## Instrucciones
1. **Verificar estado:** Revisa `tasks.md` y/o `verify-report.md`. NUNCA archives si hay errores críticos pendientes o tareas incompletas — detente y avisa.
2. **Actualizar docs:** Fusiona las specs del cambio con la documentación principal del proyecto (si existe).
3. **Archivar:** Mueve `openspec/changes/{cambio}/` → `openspec/changes/archive/{YYYY-MM-DD}-{cambio}/`.

## Retorno al Orquestador

Formato estructurado (JSON):

```json
{
  "status": "archived | blocked",
  "change_name": "nombre-del-cambio",
  "archive_path": "openspec/changes/archive/2026-03-12-nombre-del-cambio",
  "docs_updated": ["openspec/specs/auth/spec.md", "openspec/specs/export/spec.md"],
  "executive_summary": "1-2 párrafos: qué se archivó, docs fusionadas, estado final",
  "blockers": "Tareas pendientes o errores críticos" | "Ninguno"
}
```
