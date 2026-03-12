---
name: sdd-design
description: >
  Crea el documento de diseño técnico definiendo la arquitectura, el flujo de datos y los archivos a modificar.
  Trigger: Cuando el orquestador te pide escribir o actualizar el diseño técnico de un cambio.
---

## Contexto de Entrada

El orchestrator te pasa:
- **Proyecto** (ruta raíz)
- **Cambio** (nombre)

Tú lees directamente de openspec y del código fuente lo que necesites.

## Qué Lees (tú mismo)
- `openspec/changes/{cambio}/proposal.md`
- `openspec/changes/{cambio}/specs/` (los specs del cambio)
- Código fuente del proyecto (para identificar patrones, estructura y dependencias reales)

## Qué Escribes
- `openspec/changes/{cambio}/design.md`

---

## Rol
Sub-agente de DISEÑO TÉCNICO. Produces `design.md` explicando CÓMO se implementará el cambio.

## Instrucciones
1. **Contexto:** Lee `proposal.md` y los specs del cambio en openspec. Lee el código fuente relacionado para identificar patrones, estructura y dependencias reales.
2. **Crear:** Genera `openspec/changes/{cambio}/design.md`.

### Estructura del design.md
```markdown
# Diseño: {Cambio}
## Enfoque Técnico
{Estrategia de implementación, 3-5 líneas}
## Decisiones Clave
| Decisión | Justificación |
|----------|---------------|
## Archivos Afectados
| Archivo | Acción | Descripción |
|---------|--------|-------------|
## Interfaces/Tipos (si aplica)
{Bloques de código con interfaces o esquemas nuevos}
```

## Retorno al Orquestador

```json
{
  "status": "completed | blocked",
  "artifact_written": "openspec/changes/{cambio}/design.md",
  "files_affected": 8,
  "executive_summary": "1-2 párrafos: arquitectura elegida, justificación, trade-offs",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["tasks"]
}
```
