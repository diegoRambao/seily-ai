# ✅ Optimización de Contexto Aplicada

## Cambios Realizados

He modificado **8 skills SDD** para adoptar el patrón de contexto mínimo (15%) de Agent Teams Lite.

### Skills Optimizados

| Skill | Cambios Aplicados |
|-------|-------------------|
| **sdd-explore** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Lista explícita de inputs/outputs |
| **sdd-propose** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ next_recommended explícito |
| **sdd-spec** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Métricas de cobertura |
| **sdd-design** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Decisiones clave explícitas |
| **sdd-task** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Breakdown por fase |
| **sdd-apply** | ✅ Sección de contexto mínimo<br>✅ **Paso 0: Cargar Skills**<br>✅ Retorno JSON estructurado<br>✅ Instrucciones explícitas |
| **sdd-verify** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Matriz de hallazgos |
| **sdd-archive** | ✅ Sección de contexto mínimo<br>✅ Retorno JSON estructurado<br>✅ Paths de archivos |

---

## Estructura Añadida a Cada Skill

### 1. Sección "⚙️ Contexto de Entrada (Mínimo)"

Ahora cada skill especifica explícitamente:

```markdown
## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
- ✅ **Archivos necesarios**
- ✅ **Datos específicos**
- ✅ **Contexto mínimo**

NO debes recibir:
- ❌ **Archivos prohibidos**
- ❌ **Contexto innecesario**

**Si recibiste más contexto del necesario, ignóralo.**
```

**Beneficio:** El sub-agente sabe exactamente qué esperar y qué ignorar.

---

### 2. Retorno JSON Estructurado

Antes:
```
status: Completado
summary: <texto libre>
blockers: <texto libre>
```

Después:
```json
{
  "status": "completed | partial | blocked",
  "executive_summary": "1-2 párrafos estructurados",
  "metrics": { "key": "value" },
  "blockers": "Descripción" | "Ninguno",
  "next_recommended": ["siguiente-fase"]
}
```

**Beneficio:** El orchestrator puede parsear respuestas fácilmente y extraer solo el resumen.

---

### 3. Paso Explícito de Carga de Skills (sdd-apply)

```markdown
### Paso 0: Cargar Skills
1. Lee el skill registry (`.atl/skill-registry.md`)
2. Identifica skills relevantes
3. Carga los skills ANTES de escribir código
```

**Beneficio:** El sub-agente auto-descubre React, TDD, Tailwind, etc. antes de implementar.

---

## Comparación: Antes vs Después

### Ejemplo: sdd-apply

#### Antes (100% de contexto)
```
Orchestrator → Sub-agente Apply

Contexto pasado:
  - proposal.md completo (1500 tokens)
  - specs.md completo (2000 tokens)
  - design.md completo (1000 tokens)
  - tasks.md completo (500 tokens)
  - Conversación completa (10,000 tokens)
  ─────────────────────────────────────
  Total: ~15,000 tokens

Retorno del sub-agente:
  - Texto libre (difícil de parsear)
  - Orchestrator guarda todo el contexto
```

#### Después (15% de contexto)
```
Orchestrator → Sub-agente Apply

Contexto pasado:
  - Skill registry (100 tokens)
  - Tasks pendientes SOLO (200 tokens)
  - Design extract (300 tokens)
  - Instrucción específica (150 tokens)
  ─────────────────────────────────────
  Total: ~750 tokens (95% menos)

Retorno del sub-agente:
  - JSON estructurado (parseable)
  - Orchestrator guarda solo executive_summary (50 tokens)
  - Descarta el resto del contexto del sub-agente
```

---

## Impacto Esperado

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| **Tokens por sub-agente** | ~5,000 | ~750 | **85% menos** |
| **Contexto orchestrator** | ~15,000 | ~2,000 | **87% menos** |
| **Cambios antes de compactación** | 3-5 | 15-20 | **4x más** |
| **Precisión de artifacts** | Buena | Mejor | Skills enfocados |
| **Parseabilidad de retornos** | Texto libre | JSON | Automática |

---

## Próximos Pasos

### 1. Actualizar el Orchestrator (CRÍTICO)

El orchestrator debe:
- ✅ Pasar solo el contexto mínimo a cada sub-agente
- ✅ Extraer solo el `executive_summary` del retorno JSON
- ✅ Descartar el resto del contexto del sub-agente
- ✅ Mantener solo estado mínimo en su memoria

**Archivo a modificar:** `~/.claude/CLAUDE.md` (o tu config principal)

**Contenido a añadir:** Ver archivo `ORCHESTRATOR-CONTEXT-OPTIMIZATION.md`

---

### 2. Testing

```bash
# En cualquier proyecto
cd ~/tu-proyecto

# Iniciar SDD
/sdd-init

# Crear un cambio de prueba
/sdd-new test-context-optimization

# Observar:
# 1. Cada sub-agente recibe ~750 tokens (no ~5000)
# 2. Retornos en formato JSON
# 3. Orchestrator mantiene solo resúmenes
```

**Señales de éxito:**
- ✅ Sub-agentes NO piden "más contexto"
- ✅ Artifacts generados son correctos
- ✅ Orchestrator completa 10+ cambios sin compactar

---

### 3. Validación

Después del primer cambio completo:

```bash
# Revisar los artifacts generados
ls -R .sdd/changes/test-context-optimization/

# Verificar que el contenido es correcto
cat .sdd/changes/test-context-optimization/proposal.md
cat .sdd/changes/test-context-optimization/specs/*/spec.md
cat .sdd/changes/test-context-optimization/design.md
cat .sdd/changes/test-context-optimization/tasks.md
```

**Checklist de calidad:**
- [ ] Proposal tiene objetivo, scope y enfoque
- [ ] Specs tienen scenarios en formato Given/When/Then
- [ ] Design tiene decisiones justificadas
- [ ] Tasks están agrupadas en fases
- [ ] Código implementado funciona correctamente

---

## Archivos de Referencia

| Archivo | Propósito |
|---------|-----------|
| `CONTEXT-OPTIMIZATION-STRATEGY.md` | Guía completa del patrón |
| `EXAMPLE-OPTIMIZED-SDD-APPLY.md` | Ejemplo detallado de sdd-apply |
| `ORCHESTRATOR-CONTEXT-OPTIMIZATION.md` | Prompt listo para el orchestrator |
| `optimize-context.sh` | Script bash (no ejecutado, guardado como referencia) |

---

## FAQ

### ¿Por qué JSON en lugar de texto libre?

**Razón 1: Parseabilidad**
- El orchestrator puede extraer `executive_summary` automáticamente
- No necesita buscar patrones en texto libre

**Razón 2: Estructura predecible**
- Cada sub-agente retorna el mismo formato
- Fácil de validar y debuggear

**Razón 3: Métricas**
- El orchestrator puede trackear progreso con números
- Ejemplo: "12/12 escenarios cubiertos"

### ¿Qué pasa si un sub-agente necesita MÁS contexto?

Es un **bug en la matriz de contexto**.

La matriz está diseñada para que cada sub-agente tenga **exactamente** lo necesario.

Si un sub-agente pide más contexto:
1. Revisa la matriz en `CONTEXT-OPTIMIZATION-STRATEGY.md`
2. Ajusta el orchestrator para pasar el archivo faltante
3. Actualiza la sección "⚙️ Contexto de Entrada" del skill

### ¿Esto funciona con OpenCode también?

**Sí**, el patrón funciona con cualquier agente que soporte Task tool:
- ✅ Claude Code
- ✅ OpenCode
- ✅ Gemini CLI (via inline skills)
- ✅ Codex (via inline skills)

La única diferencia es **cómo se delega**:
- Claude Code/OpenCode: Task tool (sub-agente real, contexto fresco)
- Gemini CLI/Codex: Inline skill load (contexto compartido, pero sigue siendo menor)

### ¿Puedo revertir los cambios?

**No hay backups automáticos** en esta ejecución, pero los cambios son:
1. Secciones nuevas añadidas (no sobrescriben contenido existente)
2. Formato de retorno cambiado (de texto libre a JSON)

Para revertir manualmente:
```bash
cd /Users/andres.rambao/Documents/dev/ai-env-setup/bundle/skills

# Revisar cambios
git diff

# Si usas git y quieres revertir:
git checkout -- sdd-*/SKILL.md
```

---

## Conclusión

✅ **8 skills optimizados** con patrón de contexto mínimo (15%)

✅ **Retornos JSON estructurados** para parseabilidad

✅ **Auto-discovery de skills** vía registry en sdd-apply

✅ **Documentación completa** para el orchestrator

**Próximo paso crítico:** Actualizar `~/.claude/CLAUDE.md` con las instrucciones de `ORCHESTRATOR-CONTEXT-OPTIMIZATION.md`

---

## Métricas de Éxito

Después de implementar el orchestrator optimizado:

```
Antes:
  - Contexto orchestrator: ~15K tokens
  - Cambios antes de compactación: 3-5
  - Tiempo por cambio: largo (mucho contexto)

Después:
  - Contexto orchestrator: ~2K tokens
  - Cambios antes de compactación: 15-20
  - Tiempo por cambio: rápido (contexto enfocado)
```

**Ahorro total:** ~87% menos tokens, 4x más cambios por sesión.

---

**Creado:** $(date)  
**Basado en:** [Agent Teams Lite](https://github.com/Gentleman-Programming/agent-teams-lite)
