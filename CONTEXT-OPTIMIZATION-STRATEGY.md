# Estrategia de Optimización de Contexto para Sub-agentes SDD

> Basado en Agent Teams Lite — patrón del 15% de contexto

## Objetivo

Reducir el contexto que cada sub-agente recibe, pasando **solo los archivos necesarios** para su fase específica. Esto:

- ✅ Reduce consumo de tokens (15% vs 100%)
- ✅ Reduce alucinaciones (menos ruido)
- ✅ Mejora velocidad (menos texto a procesar)
- ✅ Permite sesiones más largas antes de compactación

---

## El Patrón: Contexto Mínimo por Fase

### 1. **sdd-orchestrator** (coordinador)

**Contexto permitido:**
- Estado actual: `{ current_phase, artifacts_created, user_approved }`
- Resúmenes ejecutivos de fases completadas (NO los archivos completos)
- Skill registry (`.atl/skill-registry.md`)

**Prohibido:**
- Archivos completos de artifacts (proposal.md, specs, design.md)
- Conversaciones previas completas
- Código del proyecto (solo lo necesario para decision-making)

**Implementación:**
```markdown
## Contexto mínimo del orchestrator

El orchestrator mantiene solo:
1. Estado del workflow (JSON o YAML simple)
2. Resúmenes ejecutivos de cada fase (1-3 párrafos máximo)
3. Decisiones del usuario (aprobaciones/cambios solicitados)

Cuando delega a un sub-agente:
- NO pasa toda la conversación
- SÍ pasa solo los archivos que el sub-agente necesita (ver matriz abajo)
```

---

### 2. **Matriz de Contexto por Sub-agente**

| Sub-agente | Archivos necesarios | Archivos prohibidos |
|------------|---------------------|---------------------|
| **sdd-explore** | - Instrucciones del usuario<br>- Skill registry | - Artifacts previos<br>- Código no relevante |
| **sdd-propose** | - Exploration summary<br>- Skill registry | - Código detallado<br>- Specs de otros cambios |
| **sdd-spec** | - `proposal.md`<br>- Skill registry<br>- Specs existentes (solo las afectadas) | - Design.md<br>- Tasks.md<br>- Código |
| **sdd-design** | - `proposal.md`<br>- `specs.md` (solo delta)<br>- Skill registry | - Tasks.md<br>- Código implementado |
| **sdd-tasks** | - `design.md`<br>- `specs.md` (solo para referencia)<br>- Skill registry | - Proposal completo<br>- Conversación inicial |
| **sdd-apply** | - `tasks.md`<br>- `design.md`<br>- Skill registry<br>- Archivos a modificar | - Proposal<br>- Specs (a menos que necesite validar algo específico) |
| **sdd-verify** | - `specs.md`<br>- Código modificado<br>- Tests<br>- Skill registry | - Proposal<br>- Design.md<br>- Tasks.md |
| **sdd-archive** | - Todos los artifacts finales | - Conversación<br>- Versiones intermedias |

---

### 3. **Protocol de Delegación en el Orchestrator**

Actualiza el prompt del `sdd-orchestrator` con esto:

```markdown
## Protocol de Delegación con Contexto Mínimo

Cuando delegues a un sub-agente via Task tool:

1. **Identifica la fase** (explore, propose, spec, design, tasks, apply, verify, archive)

2. **Filtra el contexto** usando la matriz de arriba

3. **Construye el prompt del sub-agente:**
   ```
   Task(
     subagent_type: 'general',
     prompt: '''
       Carga el skill: sdd-<fase>
       
       CONTEXTO MÍNIMO:
       - Skill registry: [pasar .atl/skill-registry.md]
       - Artifact de entrada: [pasar SOLO el archivo necesario]
       
       TAREA:
       [Instrucción específica de la fase]
       
       RESULTADO ESPERADO:
       - Artifact creado/actualizado: <nombre>
       - Resumen ejecutivo: <formato>
     '''
   )
   ```

4. **Cuando el sub-agente retorna:**
   - Guarda el artifact (engram/openspec según config)
   - Extrae el resumen ejecutivo
   - **Descarta el resto del contexto del sub-agente**
   - Actualiza tu estado mínimo

5. **NUNCA** mantengas en tu contexto:
   - Logs completos del sub-agente
   - Código leído durante exploration
   - Versiones intermedias de artifacts
```

---

## 4. **Actualización de Skills SDD**

Cada skill debe incluir al inicio:

```markdown
## Contexto de Entrada Requerido

Este sub-agente necesita ÚNICAMENTE:

1. **Skill registry**: `.atl/skill-registry.md` (siempre)
2. **Artifact de entrada**: 
   - [Listar archivos específicos según matriz]
3. **Instrucción del usuario** (si aplica)

**NO** debes recibir:
- [Listar archivos prohibidos según matriz]

Si el orchestrator te pasó más contexto del necesario, **ignóralo**.
```

---

## 5. **Ejemplo Práctico: Fase Apply**

### ❌ Contexto actual (100%):
```
- Toda la conversación desde /sdd-new
- proposal.md completo
- specs.md completo
- design.md completo
- tasks.md completo
- Archivos del proyecto explorados
- Decisiones de usuario en cada fase
```

### ✅ Contexto optimizado (15%):
```markdown
Task(
  subagent_type: 'general',
  prompt: '''
    Carga el skill: sdd-apply
    
    CONTEXTO MÍNIMO:
    1. Skill registry: <contenido de .atl/skill-registry.md>
    
    2. Tasks a implementar:
       <contenido de tasks.md SOLO las tareas pendientes>
    
    3. Decisiones de diseño (referencia rápida):
       <extracto de design.md: solo arquitectura y patrones clave>
    
    TAREA:
    Implementa las tareas de la Fase 1 (Foundation).
    Marca cada tarea como completa al terminar.
    
    RESULTADO:
    - Tareas completadas: [lista]
    - Archivos modificados: [lista]
    - Resumen ejecutivo: [1 párrafo]
  '''
)
```

**Reducción:** de ~5000 tokens a ~750 tokens (85% menos)

---

## 6. **Modificaciones a tu Setup Actual**

### Archivo a modificar: `~/.claude/CLAUDE.md` (o tu config principal)

Añade esta sección al orchestrator:

```markdown
## CRÍTICO: Contexto Mínimo para Sub-agentes

Cuando uses Task tool para delegar:

1. **NUNCA pases toda la conversación**
2. **SÍ pasa solo:**
   - Skill registry (siempre)
   - El artifact de entrada específico (ver matriz)
   - Instrucción clara de la tarea

3. **Matriz de contexto:**
   <copiar la tabla de la sección 2>

4. **Después de que el sub-agente retorna:**
   - Guarda el artifact
   - Extrae el resumen (1-3 párrafos)
   - **Descarta el resto**
   - Continúa solo con tu estado mínimo
```

### Skills a modificar: todos los `bundle/skills/sdd-*/SKILL.md`

Al inicio de cada skill, después del título:

```markdown
---

## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ Skill registry (`.atl/skill-registry.md`)
- ✅ [Listar según matriz]

NO debes recibir:
- ❌ [Listar según matriz]

Si recibiste más contexto, **ignóralo** y trabaja solo con lo listado arriba.

---
```

---

## 7. **Testing del Nuevo Patrón**

Después de implementar:

1. **Inicia un cambio nuevo:**
   ```
   /sdd-new test-context-optimization
   ```

2. **Monitorea el contexto del orchestrator:**
   - Después de cada fase, verifica que solo guardó el resumen
   - NO debe tener el artifact completo en su conversación

3. **Mide tokens (aproximado):**
   - Antes: orchestrator context después de apply = ~15K tokens
   - Después: orchestrator context después de apply = ~2K tokens

4. **Valida calidad:**
   - Los artifacts deben seguir siendo correctos
   - Los sub-agentes NO deben pedir más contexto
   - El workflow debe completarse sin errores

---

## 8. **Próximos Pasos (Opcionales)**

Una vez que domines este patrón:

1. **Engram como backend:**
   - Reemplaza `.sdd/changes/` con `mem_save`
   - Los artifacts quedan indexados en SQLite FTS5
   - Búsqueda instantánea: `mem_search "auth middleware"`

2. **Git sync:**
   - Adopta el sistema de chunks de Engram
   - Comparte memoria entre máquinas/equipo
   - No más "perdí mi contexto al cambiar de laptop"

3. **Session tracking:**
   - `mem_session_summary` al cerrar
   - `mem_context` al iniciar (recupera sesión previa)
   - Sobrevive a compactaciones

---

## Resumen Ejecutivo

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Contexto orchestrator** | ~15K tokens | ~2K tokens | **87% menos** |
| **Contexto sub-agente** | ~5K tokens | ~750 tokens | **85% menos** |
| **Sesiones antes de compactación** | 3-5 cambios | 15-20 cambios | **4x más** |
| **Precisión de artifacts** | Buena | Igual o mejor | Sin degradación |
| **Complejidad setup** | Baja | Media | Vale la pena |

---

## Referencias

- [Agent Teams Lite](https://github.com/Gentleman-Programming/agent-teams-lite)
- [Engram](https://github.com/Gentleman-Programming/engram)
- [Patrón de Progressive Disclosure](https://github.com/Gentleman-Programming/engram#progressive-disclosure-3-layer-pattern)
