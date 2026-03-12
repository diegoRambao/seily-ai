#!/usr/bin/env bash
set -euo pipefail

# Script para optimizar contexto de sub-agentes SDD
# Basado en Agent Teams Lite (patrón del 15%)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/bundle/skills"
BACKUP_DIR="$SCRIPT_DIR/backups/context-optimization-$(date +%Y%m%d-%H%M%S)"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Optimización de Contexto para Sub-agentes SDD${NC}"
echo -e "${BLUE}  Patrón del 15% (Agent Teams Lite)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo

# Función para hacer backup
backup_skill() {
    local skill_name=$1
    local skill_path="$SKILLS_DIR/$skill_name/SKILL.md"
    
    if [[ -f "$skill_path" ]]; then
        mkdir -p "$BACKUP_DIR/$skill_name"
        cp "$skill_path" "$BACKUP_DIR/$skill_name/SKILL.md"
        echo -e "${GREEN}✓${NC} Backup de $skill_name guardado"
    fi
}

# Función para añadir sección de contexto mínimo
add_context_section() {
    local skill_name=$1
    local skill_path="$SKILLS_DIR/$skill_name/SKILL.md"
    local required_context=$2
    local prohibited_context=$3
    
    # Buscar línea después del frontmatter (después de segundo ---)
    local insert_line=$(awk '/^---$/{count++; if(count==2){print NR+1; exit}}' "$skill_path")
    
    if [[ -n "$insert_line" ]]; then
        # Crear contenido a insertar
        local context_section="
## ⚙️ Contexto de Entrada (Mínimo)

Este sub-agente requiere:
$required_context

NO debes recibir:
$prohibited_context

**Si recibiste más contexto del necesario, ignóralo.**

---
"
        
        # Insertar después del frontmatter
        awk -v line="$insert_line" -v text="$context_section" '
            NR==line {print text}
            {print}
        ' "$skill_path" > "${skill_path}.tmp" && mv "${skill_path}.tmp" "$skill_path"
        
        echo -e "${GREEN}✓${NC} Sección de contexto añadida a $skill_name"
    else
        echo -e "${YELLOW}⚠${NC} No se pudo encontrar frontmatter en $skill_name"
    fi
}

echo "Este script va a:"
echo "  1. Crear backups de todos los skills"
echo "  2. Añadir sección '⚙️ Contexto de Entrada (Mínimo)' a cada skill"
echo "  3. Generar prompt optimizado para sdd-orchestrator"
echo
read -p "¿Continuar? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operación cancelada."
    exit 0
fi

echo
echo -e "${BLUE}Paso 1: Creando backups...${NC}"
mkdir -p "$BACKUP_DIR"

# Backup de todos los skills SDD
for skill in sdd-explore sdd-propose sdd-spec sdd-design sdd-task sdd-apply sdd-verify sdd-archive; do
    backup_skill "$skill"
done

echo
echo -e "${BLUE}Paso 2: Optimizando skills...${NC}"

# sdd-explore
add_context_section "sdd-explore" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **Instrucción del usuario** (topic a explorar)
- ✅ **Archivos relevantes** (auto-descubre con glob/grep)" \
"- ❌ Artifacts de otros cambios
- ❌ Specs completos
- ❌ Conversación completa"

# sdd-propose
add_context_section "sdd-propose" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **Exploration summary** (1-2 párrafos del explorer)
- ✅ **Instrucción del usuario** (intent del cambio)" \
"- ❌ Código detallado explorado
- ❌ Specs de otros cambios
- ❌ Conversación completa"

# sdd-spec
add_context_section "sdd-spec" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **proposal.md** (intent, scope, approach)
- ✅ **Specs existentes afectados** (solo las secciones relevantes)" \
"- ❌ design.md
- ❌ tasks.md
- ❌ Código implementado
- ❌ Conversación completa"

# sdd-design
add_context_section "sdd-design" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **proposal.md** (intent, scope, approach)
- ✅ **specs.md delta** (solo requirements añadidos/modificados)" \
"- ❌ tasks.md
- ❌ Código implementado
- ❌ Exploration details
- ❌ Conversación completa"

# sdd-task
add_context_section "sdd-task" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **design.md** (arquitectura y decisiones clave)
- ✅ **specs.md** (solo para referencia rápida)" \
"- ❌ proposal.md completo
- ❌ Conversación inicial
- ❌ Exploration details"

# sdd-apply
add_context_section "sdd-apply" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **Tasks pendientes** (extracto de tasks.md, solo este lote)
- ✅ **Decisiones de diseño** (extracto de design.md)
- ✅ **Archivos a modificar** (código existente relevante)" \
"- ❌ proposal.md completo
- ❌ specs.md completo
- ❌ Tasks ya completadas
- ❌ Conversación completa"

# sdd-verify
add_context_section "sdd-verify" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **specs.md** (requirements y scenarios)
- ✅ **Código modificado** (files changed en este cambio)
- ✅ **Tests** (archivos de test relevantes)" \
"- ❌ proposal.md
- ❌ design.md
- ❌ tasks.md
- ❌ Conversación completa"

# sdd-archive
add_context_section "sdd-archive" \
"- ✅ **Skill registry** (\`.atl/skill-registry.md\`)
- ✅ **Todos los artifacts finales** (proposal, specs, design, tasks)
- ✅ **Specs principales** (para merge)" \
"- ❌ Conversación completa
- ❌ Versiones intermedias de artifacts
- ❌ Logs de implementación"

echo
echo -e "${BLUE}Paso 3: Generando prompt para orchestrator...${NC}"

cat > "$SCRIPT_DIR/ORCHESTRATOR-CONTEXT-OPTIMIZATION.md" << 'EOF'
# Prompt Optimizado para sdd-orchestrator

Añade esta sección a tu `~/.claude/CLAUDE.md` (o config equivalente):

---

## CRÍTICO: Contexto Mínimo para Sub-agentes

Cuando uses Task tool para delegar a skills SDD:

### 1. Principio General
**NUNCA pases toda la conversación al sub-agente.**
Solo pasa:
- ✅ Skill registry (siempre)
- ✅ El artifact de entrada específico (ver matriz abajo)
- ✅ Instrucción clara de la tarea

### 2. Matriz de Contexto por Sub-agente

| Sub-agente | Pasa SOLO | NO pases |
|------------|-----------|----------|
| **sdd-explore** | • Skill registry<br>• Topic del usuario<br>• Archivos relevantes (auto-descubre) | • Artifacts previos<br>• Código no relevante<br>• Conversación completa |
| **sdd-propose** | • Skill registry<br>• Exploration summary (1-2 párrafos)<br>• Intent del usuario | • Código detallado<br>• Specs de otros cambios<br>• Conversación completa |
| **sdd-spec** | • Skill registry<br>• proposal.md<br>• Specs existentes (solo afectados) | • design.md<br>• tasks.md<br>• Código<br>• Conversación completa |
| **sdd-design** | • Skill registry<br>• proposal.md<br>• specs.md delta (solo nuevo/modificado) | • tasks.md<br>• Código<br>• Exploration<br>• Conversación completa |
| **sdd-tasks** | • Skill registry<br>• design.md<br>• specs.md (referencia) | • proposal.md<br>• Conversación<br>• Exploration |
| **sdd-apply** | • Skill registry<br>• Tasks pendientes (solo este lote)<br>• Design extract (decisiones clave)<br>• Archivos a modificar | • proposal.md<br>• specs.md completo<br>• Tasks completadas<br>• Conversación completa |
| **sdd-verify** | • Skill registry<br>• specs.md<br>• Código modificado<br>• Tests | • proposal.md<br>• design.md<br>• tasks.md<br>• Conversación completa |
| **sdd-archive** | • Skill registry<br>• Todos los artifacts finales<br>• Specs principales (para merge) | • Conversación<br>• Versiones intermedias<br>• Logs |

### 3. Formato de Delegación

```
Task(
  subagent_type: 'general',
  prompt: '''
    Carga el skill: sdd-<fase>
    
    CONTEXTO MÍNIMO:
    
    1. Skill registry:
       <contenido de .atl/skill-registry.md>
    
    2. Artifact de entrada:
       <solo el contenido necesario según matriz>
    
    3. Instrucción:
       <tarea específica de esta fase>
    
    RESULTADO ESPERADO:
    - Artifact creado/actualizado: <nombre>
    - Formato: JSON estructurado
    - Resumen ejecutivo: 1-3 párrafos
  '''
)
```

### 4. Después de que el Sub-agente Retorna

1. **Guarda el artifact** (engram/openspec según config)
2. **Extrae el resumen ejecutivo** (1-3 párrafos)
3. **DESCARTA el resto del contexto del sub-agente**
4. **Actualiza tu estado mínimo:**
   ```json
   {
     "change": "nombre-del-cambio",
     "phase": "actual",
     "artifacts": ["proposal", "specs", "design"],
     "summaries": {
       "proposal": "1 párrafo",
       "specs": "1 párrafo",
       "design": "1 párrafo"
     },
     "next": ["tasks"]
   }
   ```

### 5. Tu Contexto como Orchestrator

Mantén SOLO:
- Estado del workflow (JSON pequeño)
- Resúmenes ejecutivos (1-3 párrafos por fase)
- Aprobaciones/cambios del usuario

**NO mantengas:**
- ❌ Artifacts completos
- ❌ Logs de sub-agentes
- ❌ Código leído durante exploration
- ❌ Versiones intermedias

### 6. Ejemplo Completo: Fase Apply

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
    
    2. Tasks de este lote (Fase 1):
       - [ ] 1.1 Crear ThemeContext
       - [ ] 1.2 Añadir CSS variables
    
    3. Decisiones de diseño clave:
       - Arquitectura: React Context API
       - Estilos: CSS variables vía Tailwind
       - Persistencia: localStorage
    
    4. Archivos a modificar:
       - src/contexts/ThemeContext.tsx (crear)
       - src/styles/globals.css (modificar)
    
    TAREA:
    Implementa las 2 tareas de la Fase 1.
    Marca cada tarea al completar.
    
    RESULTADO ESPERADO:
    - Formato JSON con: status, tasks_completed, files_modified, executive_summary, blockers
  '''
)
```

**Cuando retorna:**
```json
{
  "status": "completed",
  "tasks_completed": ["1.1", "1.2"],
  "executive_summary": "Implementé ThemeContext y CSS variables. Sistema base listo.",
  "blockers": "Ninguno"
}
```

**Tu acción:**
1. Guarda artifact (tasks.md actualizado)
2. Extrae solo: "Implementé ThemeContext y CSS variables. Sistema base listo."
3. Descarta el resto del contexto del sub-agente
4. Pregunta al usuario: "Fase 1 completada. ¿Continúo con Fase 2?"

---

## Métricas Esperadas

Después de implementar este patrón:

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Contexto orchestrator | ~15K tokens | ~2K tokens | **87% menos** |
| Contexto sub-agente | ~5K tokens | ~750 tokens | **85% menos** |
| Sesiones antes de compactación | 3-5 cambios | 15-20 cambios | **4x más** |

---

## Testing

1. Inicia un cambio nuevo:
   ```
   /sdd-new test-context-optimization
   ```

2. Monitorea el contexto:
   - Después de cada fase, verifica que solo guardaste el resumen
   - El orchestrator NO debe tener artifacts completos

3. Valida calidad:
   - Los artifacts deben ser correctos
   - Los sub-agentes NO deben pedir más contexto
   - El workflow debe completarse sin errores

EOF

echo -e "${GREEN}✓${NC} Prompt generado: ORCHESTRATOR-CONTEXT-OPTIMIZATION.md"

echo
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ Optimización completada${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo
echo "Archivos generados:"
echo "  • Backups: $BACKUP_DIR"
echo "  • Documentación: CONTEXT-OPTIMIZATION-STRATEGY.md"
echo "  • Ejemplo: EXAMPLE-OPTIMIZED-SDD-APPLY.md"
echo "  • Prompt orchestrator: ORCHESTRATOR-CONTEXT-OPTIMIZATION.md"
echo
echo "Próximos pasos:"
echo "  1. Revisa los skills modificados en $SKILLS_DIR"
echo "  2. Lee ORCHESTRATOR-CONTEXT-OPTIMIZATION.md"
echo "  3. Añade la sección 'Contexto Mínimo' a tu ~/.claude/CLAUDE.md"
echo "  4. Testing: /sdd-new test-context-optimization"
echo
echo "Para revertir: cp -r $BACKUP_DIR/* $SKILLS_DIR/"
