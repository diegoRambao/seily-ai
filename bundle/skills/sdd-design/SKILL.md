---
name: sdd-design
description: >
  Crea el documento de diseño técnico definiendo la arquitectura, el flujo de datos y los archivos a modificar.
  Trigger: Cuando el orquestador te pide escribir o actualizar el diseño técnico de un cambio.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`)
- ✅ **proposal.md** (intent, scope, approach)
- ✅ **specs.md delta** (solo requirements añadidos/modificados)

NO debes recibir:
- ❌ `tasks.md`
- ❌ Código implementado
- ❌ Exploration details
- ❌ Conversación completa

**Si recibiste más contexto del necesario, ignóralo.**

---

## Rol
Sub-agente de DISEÑO TÉCNICO. Produces `design.md` explicando CÓMO se implementará el cambio.

## Instrucciones
1. **Contexto:** Lee `proposal.md` y los specs del cambio. Lee el código fuente relacionado para identificar patrones, estructura y dependencias reales.
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

Formato estructurado (JSON):

```json
{
  "status": "completed | blocked",
  "approach": "Descripción breve del enfoque técnico",
  "files_affected": 8,
  "key_decisions": ["React Context API", "CSS variables", "localStorage"],
  "executive_summary": "1-2 párrafos: arquitectura elegida, justificación, trade-offs",
  "blockers": "Descripción del problema" | "Ninguno",
  "next_recommended": ["tasks"]
}
```
