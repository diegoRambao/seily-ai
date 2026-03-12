# Ejemplo: sdd-apply Optimizado para Contexto Mínimo

## ❌ Versión Actual (recibe todo el contexto)

```markdown
## Instrucciones
1. **Contexto:** Lee las specs y el design del cambio.
2. **Implementar:** Solo las tareas asignadas en este lote.
3. **Actualizar progreso:** Marca en tasks.md las tareas completadas.
```

**Problema:** El orchestrator le pasa:
- proposal.md completo
- specs.md completo  
- design.md completo
- tasks.md completo
- Toda la conversación previa

**Resultado:** ~5000 tokens de entrada

---

## ✅ Versión Optimizada (contexto mínimo del 15%)

```markdown
---
name: sdd-apply
description: >
  Implementa las tareas asignadas escribiendo código real basado en las especificaciones y el diseño.
  Trigger: Cuando el orquestador te pide implementar una o más tareas de un cambio.
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Skill registry** (`.atl/skill-registry.md`) — auto-descubre skills de código
- ✅ **Tasks pendientes** (extracto de `tasks.md`) — solo las tareas de este lote
- ✅ **Decisiones de diseño** (extracto de `design.md`) — arquitectura y patrones clave
- ✅ **Archivos a modificar** — código existente relevante

NO debes recibir:
- ❌ proposal.md completo
- ❌ specs.md completo (solo si necesitas validar algo específico)
- ❌ Conversación completa del cambio
- ❌ Tasks ya completadas
- ❌ Exploraciones iniciales

**Si recibiste más contexto del necesario, ignóralo.**

---

## Rol
Sub-agente de IMPLEMENTACIÓN. Escribes código real para las tareas que te asigne el orquestador.

## Instrucciones

### Paso 0: Cargar Skills
1. Lee el skill registry (`.atl/skill-registry.md`)
2. Identifica skills relevantes para el código a escribir:
   - Si trabajas con React → carga skill `react-19`
   - Si hay tests → carga skill `tdd` o `playwright`
   - Si hay estilos → carga skill `tailwind-4`
3. Carga los skills identificados ANTES de escribir código

### Paso 1: Entender el Contexto Mínimo
1. **Tasks asignadas:** Lee solo las tareas de este lote que te pasó el orchestrator
2. **Decisiones de diseño:** Lee el extracto de design.md (solo arquitectura clave)
3. **Código existente:** Lee los archivos que vas a modificar para mantener estilo

**NO busques más contexto.** Si algo falta, pregunta al orchestrator.

### Paso 2: Implementar
1. **Solo las tareas asignadas** en este lote
2. Sigue los patrones de los skills cargados en el Paso 0
3. Mantén el estilo del código existente
4. Si encuentras un blocker (diseño incompleto, dependencia faltante), **detente y reporta**

### Paso 3: Actualizar Progreso
1. Marca `- [x]` en `tasks.md` las tareas completadas
2. **NO actualices tasks.md localmente** — solo reporta al orchestrator qué completaste
3. El orchestrator se encarga de persistir el progreso

### Reglas
- Respeta los patrones existentes del proyecto
- No inventes soluciones fuera del diseño
- Si descubres un error en el diseño, repórtalo como blocker
- **NO pidas el proposal o specs completos** — trabaja con lo que tienes

---

## Retorno al Orquestador

Formato estructurado:

```json
{
  "status": "completed | partial | blocked",
  "tasks_completed": [
    "1.1 Crear ThemeContext",
    "1.2 Añadir CSS variables"
  ],
  "files_modified": [
    "src/contexts/ThemeContext.tsx",
    "src/styles/globals.css"
  ],
  "skills_used": [
    "react-19",
    "typescript",
    "tailwind-4"
  ],
  "executive_summary": "Implementé la base del sistema de temas con React Context y CSS variables. Falta añadir el toggle component (Fase 2).",
  "blockers": "Ninguno" | "El diseño no especifica cómo detectar preferencia del sistema",
  "next_recommended": ["continue-phase-2"]
}
```

**CRÍTICO:** NO incluyas en tu retorno:
- ❌ Todo el código escrito (solo lista de archivos)
- ❌ Explicaciones largas de cada cambio
- ❌ Contexto repetido del diseño

El orchestrator solo necesita:
- ✅ Qué completaste (lista)
- ✅ Resumen ejecutivo (1 párrafo)
- ✅ Blockers (si hay)

---

## Ejemplo de Uso

### Prompt del Orchestrator (optimizado):

```
Task(
  subagent_type: 'general',
  prompt: '''
    Carga el skill: sdd-apply
    
    CONTEXTO MÍNIMO:
    
    1. Skill registry:
       | Trigger | Skill | Path |
       |---------|-------|------|
       | React components | react-19 | ~/.claude/skills/react-19/SKILL.md |
       | TypeScript | typescript | ~/.claude/skills/typescript/SKILL.md |
       | Tailwind CSS | tailwind-4 | ~/.claude/skills/tailwind-4/SKILL.md |
    
    2. Tasks de este lote (Fase 1 - Foundation):
       - [ ] 1.1 Crear ThemeContext con React 19 (sin Provider wrapper innecesario)
       - [ ] 1.2 Añadir CSS custom properties para light/dark
       - [ ] 1.3 Implementar persistencia con localStorage
    
    3. Decisiones de diseño clave:
       - Arquitectura: React Context API (sin Redux)
       - Estilos: CSS variables vía Tailwind theme extend
       - Persistencia: localStorage (key: "theme-preference")
       - Patrones: React 19 (no necesita useMemo, use() para Context)
    
    4. Archivos a modificar:
       - src/contexts/ (crear ThemeContext.tsx)
       - src/styles/globals.css (añadir :root variables)
       - tailwind.config.ts (extend theme colors)
    
    TAREA:
    Implementa las 3 tareas de la Fase 1.
    Marca cada tarea como completa al terminar.
    
    RESULTADO ESPERADO:
    - Formato JSON estructurado (ver skill)
    - Resumen ejecutivo (1 párrafo)
    - Lista de archivos modificados
  '''
)
```

**Tokens de entrada:** ~800 (vs ~5000 antes)

---

## Comparación: Antes vs Después

| Aspecto | Versión Actual | Versión Optimizada | Mejora |
|---------|----------------|-------------------|--------|
| **Contexto recibido** | proposal + specs + design + tasks completos | Solo tasks pendientes + extracto de design | **85% menos tokens** |
| **Skills auto-discovery** | No especificado | Paso 0 explícito | **Mejor calidad** |
| **Retorno al orchestrator** | Texto libre | JSON estructurado | **Más parseable** |
| **Blockers** | Informal | Campo explícito | **Mejor tracking** |
| **Orchestrator overhead** | Recibe todo el código | Recibe solo resumen | **90% menos tokens** |

---

## Implementación en tu Setup

### 1. Actualiza el skill:
```bash
cp /Users/andres.rambao/Documents/dev/ai-env-setup/bundle/skills/sdd-apply/SKILL.md \
   /Users/andres.rambao/Documents/dev/ai-env-setup/bundle/skills/sdd-apply/SKILL.md.backup

# Luego edita el skill con la nueva estructura
```

### 2. Actualiza el orchestrator (CLAUDE.md):
Añade esta sección al `sdd-orchestrator`:

```markdown
## Delegación a sdd-apply (Contexto Mínimo)

Cuando delegues implementación:

1. **Extrae solo las tasks del lote actual:**
   ```
   Fase 1 (Foundation):
   - [ ] 1.1 Task description
   - [ ] 1.2 Task description
   ```

2. **Extrae solo decisiones clave de design.md:**
   - Arquitectura principal (React Context, no Redux)
   - Patrones a seguir (React 19, sin useMemo)
   - Persistencia (localStorage, key name)
   
   **NO pases design.md completo**

3. **Lista archivos a modificar:**
   - src/contexts/ThemeContext.tsx
   - src/styles/globals.css
   
   **El sub-agente los leerá él mismo**

4. **Pasa skill registry completo:**
   <contenido de .atl/skill-registry.md>

5. **Lanza Task tool con formato del ejemplo**

6. **Cuando retorna:**
   - Guarda el artifact (tasks.md actualizado)
   - Extrae solo el executive_summary
   - **Descarta el resto del contexto del sub-agente**
   - Pregunta al usuario si continúa con siguiente lote
```

### 3. Testing:
```bash
# En un proyecto de prueba:
/sdd-new test-optimized-context

# Observa el tamaño del prompt al delegar a sdd-apply
# Debería ser ~800 tokens vs ~5000 antes
```

---

## Próximos Skills a Optimizar

Después de validar que `sdd-apply` funciona bien:

1. **sdd-spec** — solo necesita proposal.md + specs existentes afectados
2. **sdd-design** — solo necesita proposal.md + specs delta
3. **sdd-tasks** — solo necesita design.md + specs (sin proposal)
4. **sdd-verify** — solo necesita specs + código modificado

Usa esta misma estructura en cada uno.
