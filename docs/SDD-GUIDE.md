# Guia de Uso: Spec-Driven Development (SDD)

## Que es SDD

SDD es un flujo de desarrollo donde **primero defines que vas a construir** (specs) y **como lo vas a construir** (design), y despues implementas. Un orquestador coordina sub-agentes especializados que trabajan con contexto aislado: cada uno lee y escribe en `openspec/`, sin que el orquestador toque el contenido.

```
Tu idea
  |
  v
Orquestador (coordina, no lee artifacts)
  |
  +-> Sub-agente Explore   -> lee codigo, escribe exploration.md
  +-> Sub-agente Propose   -> lee exploration, escribe proposal.md
  +-> Sub-agente Spec      -> lee proposal, escribe specs/
  +-> Sub-agente Design    -> lee proposal + specs, escribe design.md
  +-> Sub-agente Tasks     -> lee design + specs, escribe tasks.md
  +-> Sub-agente Apply     -> lee tasks + design, escribe codigo
  +-> Sub-agente Verify    -> lee specs + codigo, escribe verify-report.md
  +-> Sub-agente Archive   -> fusiona specs, archiva el cambio
```

Todos los artifacts se guardan en `openspec/changes/{nombre-del-cambio}/`. El orquestador nunca lee esos archivos -- solo pasa rutas a los sub-agentes.

---

## Cuando Usar SDD

### Usa SDD cuando:

- **Cambios multi-archivo** que afectan 3+ archivos
- **Features nuevos** que necesitan planificacion antes de escribir codigo
- **Refactors grandes** donde quieres documentar el antes y el despues
- **Trabajo en equipo** donde otros necesitan entender que se hizo y por que
- **Cambios con riesgo** donde un error puede romper funcionalidad existente
- **Cuando no tienes claro** como implementar algo y necesitas explorar primero

### NO uses SDD cuando:

- **Fixes simples** de 1-2 archivos donde ya sabes que hacer
- **Cambios cosmeticos** como renombrar una variable o ajustar un estilo
- **Tareas triviales** que toman menos de 5 minutos
- **Hotfixes urgentes** donde la velocidad es prioridad absoluta
- **Explorar una idea** sin compromiso (usa `/sdd-explore` suelto, sin SDD completo)

### Regla rapida:

> Si puedes describir el cambio en una oracion y ya sabes que archivos tocar, no necesitas SDD. Si necesitas pensar "como voy a hacer esto", usa SDD.

---

## Antes de Empezar

### 1. Instalar

```bash
git clone https://github.com/diegoRambao/ai-env-setup.git
cd ai-env-setup
./install.sh
```

### 2. Inicializar SDD en tu proyecto

Abre tu asistente de AI en tu proyecto y ejecuta:

```
/sdd-init
```

Esto crea:

```
openspec/
  specs/           <- specs del proyecto (fuente de verdad)
  changes/         <- cambios activos
    archive/       <- cambios completados
  config.yaml      <- stack detectado, configuracion
```

Solo necesitas hacer esto una vez por proyecto.

---

## Comandos

| Comando | Que hace |
|---------|----------|
| `/sdd-init` | Inicializa SDD. Detecta stack, crea `openspec/` |
| `/sdd-explore <tema>` | Investiga una idea sin crear archivos permanentes |
| `/sdd-new <nombre>` | Inicia un cambio nuevo (crea proposal) |
| `/sdd-ff <nombre>` | Fast-forward: proposal -> specs + design (paralelo) -> tasks |
| `/sdd-continue` | Ejecuta la siguiente fase pendiente |
| `/sdd-apply` | Implementa las tareas por lotes |
| `/sdd-verify` | Valida que el codigo cumpla las specs |
| `/sdd-archive` | Archiva el cambio completado |

---

## Flujo Completo Paso a Paso

### Ejemplo: "Quiero agregar exportacion a CSV"

#### Paso 1: Iniciar el cambio

```
/sdd-new add-csv-export
```

El orquestador lanza el sub-agente **Propose** que:
- Lee el codigo del proyecto
- Crea `openspec/changes/add-csv-export/proposal.md`
- Retorna un resumen: objetivo, alcance, enfoque

El orquestador te muestra el resumen y pregunta: **"Continuo con specs y design?"**

#### Paso 2: Specs + Design

Si aceptas, el orquestador lanza **Spec** y **Design** en paralelo:

- **Spec** lee `proposal.md`, crea `specs/export/spec.md` con reglas de negocio y escenarios Given/When/Then
- **Design** lee `proposal.md` + specs, crea `design.md` con arquitectura, decisiones y archivos afectados

El orquestador te muestra ambos resúmenes. **"Continuo con tasks?"**

#### Paso 3: Tasks

El orquestador lanza **Tasks** que:
- Lee `design.md` + specs
- Crea `tasks.md` con fases numeradas (3-5 tareas por fase)

**"Listo para implementar. Ejecuto /sdd-apply?"**

#### Paso 4: Apply (por lotes)

El orquestador lanza **Apply** con el lote "Fase 1":
- Lee `tasks.md` + `design.md`
- Implementa las tareas
- Marca `[x]` en `tasks.md`

Despues de cada lote, te muestra progreso: "3/12 tareas completadas. Continuo con Fase 2?"

#### Paso 5: Verify

```
/sdd-verify
```

El sub-agente **Verify**:
- Lee specs + codigo implementado
- Ejecuta tests si existen
- Crea `verify-report.md` con APROBADO/RECHAZADO y cobertura

#### Paso 6: Archive

```
/sdd-archive
```

El sub-agente **Archive**:
- Verifica que no haya errores criticos
- Fusiona las specs del cambio con `openspec/specs/`
- Mueve todo a `openspec/changes/archive/2026-03-12-add-csv-export/`

---

## Fast-Forward: Para Cuando ya Sabes lo que Quieres

Si no necesitas revisar cada fase individualmente:

```
/sdd-ff add-csv-export
```

Esto ejecuta automaticamente:

```
proposal -> specs + design (paralelo) -> tasks
```

Te muestra un resumen consolidado al final. Util cuando tienes una idea clara y solo quieres llegar rapido a la implementacion.

---

## Cuando Usar un PRD.md

### Que es un PRD

Un PRD (Product Requirements Document) es un documento externo que ya describe lo que quieres construir. Puede venir de:

- Un product manager
- Un ticket de Jira/Linear
- Un documento de Google Docs
- Un spec tecnico que escribiste tu mismo

### Como usarlo

1. **Crea el archivo** en tu proyecto (o en cualquier ruta accesible):

```markdown
# PRD: Sistema de Exportacion CSV

## Objetivo
Permitir a los usuarios exportar sus datos a formato CSV.

## Requisitos
- El sistema debe soportar exportacion de todas las observaciones
- Los headers deben coincidir con los campos de la base de datos
- Debe soportar filtros por fecha y tipo

## Criterios de Aceptacion
- DADO que el usuario tiene observaciones
- CUANDO solicita exportar a CSV
- ENTONCES recibe un archivo .csv con todos los campos

## Fuera de Alcance
- Exportacion a Excel (.xlsx)
- Exportacion programada (cron)
```

2. **Pasalo al orquestador:**

```
Aqui tienes el PRD para el cambio: docs/prd-csv-export.md
```

3. **El orquestador hace triaje automatico:**

```
Triaje del documento:
[OK] propose   -- cubierto (objetivo y alcance definidos)
[OK] spec      -- cubierto (3 criterios de aceptacion)
[  ] design    -- no cubierto (falta definir archivos a modificar)
[  ] tasks     -- no cubierto (no hay desglose de tareas)

Plan: ejecutar design -> tasks -> apply -> verify
```

4. **Confirmas** y el orquestador ejecuta solo las fases faltantes.

### Cuando SI usar un PRD

- **Cuando recibes requerimientos de un PM o stakeholder** y quieres que SDD los procese
- **Cuando ya escribiste un documento** con la idea y no quieres repetir la fase de proposal/specs
- **Cuando tienes un ticket detallado** con criterios de aceptacion claros
- **Cuando trabajas en equipo** y alguien ya definio los requerimientos

### Cuando NO usar un PRD

- **Cuando la idea es vaga** -- mejor usa `/sdd-explore` primero
- **Cuando el PRD es solo un titulo** sin detalles -- no ahorra tiempo
- **Cuando quieres que la AI descubra** el enfoque -- deja que SDD genere el proposal

### Formato del PRD

No hay un formato obligatorio. El orquestador analiza el contenido y clasifica que fases cubre. Pero cuanto mas completo sea, mas fases se salta:

| El PRD tiene... | Fase que cubre |
|-----------------|----------------|
| Objetivo + alcance | `propose` |
| Reglas de negocio + escenarios | `spec` |
| Arquitectura + archivos afectados | `design` |
| Lista de tareas paso a paso | `tasks` |

Un PRD que cubre las 4 fases va directo a `apply`.

---

## Estructura de Archivos

Cuando ejecutas SDD, tu proyecto genera esta estructura:

```
tu-proyecto/
  openspec/
    config.yaml                         <- Stack detectado (openspec/config.yaml)
    specs/                              <- Fuente de verdad: como funciona el sistema HOY
      auth/spec.md
      export/spec.md
    changes/
      add-csv-export/                   <- Cambio activo
        proposal.md                     <- QUE vamos a construir y POR QUE
        specs/                          <- Specs delta (nuevo/modificado)
          export/spec.md
        design.md                       <- COMO lo vamos a construir
        tasks.md                        <- Lista de tareas por fases
        verify-report.md                <- Resultado de verificacion
        prd.md                          <- Documento externo (si se uso)
        exploration.md                  <- Analisis de exploracion (si se hizo)
      archive/                          <- Cambios completados
        2026-03-12-fix-auth/
        2026-03-10-add-dark-mode/
```

### Que es cada archivo

| Archivo | Quien lo crea | Que contiene |
|---------|---------------|--------------|
| `config.yaml` | sdd-init | Stack, lenguajes, frameworks, comando de test |
| `proposal.md` | sdd-propose | Objetivo, alcance, enfoque a alto nivel |
| `specs/` | sdd-spec | Reglas de negocio, escenarios Given/When/Then |
| `design.md` | sdd-design | Arquitectura, decisiones clave, archivos afectados |
| `tasks.md` | sdd-tasks | Tareas por fases, checkboxes para tracking |
| `verify-report.md` | sdd-verify | Resultado de QA, cobertura de specs, hallazgos |
| `prd.md` | orquestador (copia) | Documento externo que el usuario proporciono |
| `exploration.md` | sdd-explore | Analisis del codigo, enfoques evaluados |

---

## Como Funciona el Orquestador

### Principio fundamental

```
Orquestador = coordinador que pasa RUTAS, no contenido.
Sub-agentes = trabajadores que leen y escriben en openspec/.
```

El orquestador:
- **SI** rastrea que fase estamos y que artifacts existen
- **SI** muestra resumenes al usuario y pide aprobacion
- **SI** lanza sub-agentes via Task()
- **SI** lee documentos externos (PRDs) para triaje
- **NO** lee proposal.md, design.md, specs, tasks.md, ni ningun artifact
- **NO** escribe codigo, specs ni diseño
- **NO** pasa contenido de artifacts a sub-agentes

### Flujo interno del orquestador

```
1. Usuario: /sdd-new add-csv-export

2. Orquestador:
   - Lanza Task(sdd-propose, proyecto=/path, cambio=add-csv-export)
   - Espera retorno JSON del sub-agente
   - Muestra al usuario: "Proposal creado. Resumen: ..."
   - Pregunta: "Continuo con specs y design?"

3. Usuario: "Si"

4. Orquestador:
   - Lanza Task(sdd-spec, proyecto=/path, cambio=add-csv-export)
   - Lanza Task(sdd-design, proyecto=/path, cambio=add-csv-export)
   - Espera ambos retornos
   - Muestra resumenes
   - Pregunta: "Continuo con tasks?"

5. (repite hasta archive)
```

### Estado interno del orquestador

El orquestador solo mantiene esto en su contexto:

```
Cambio: add-csv-export
Fase completada: design
Artifacts existentes: [proposal.md, specs/, design.md]
Siguiente fase: tasks
```

No mantiene contenido de artifacts, ni codigo, ni logs de sub-agentes.

---

## Escenarios Comunes

### "Quiero explorar antes de comprometerme"

```
/sdd-explore autenticacion con OAuth
```

El sub-agente explora el codigo, evalua opciones y retorna un resumen. No crea archivos permanentes (a menos que le des un nombre de cambio). Util para investigar antes de decidir.

### "Ya se exactamente que quiero, dame las tareas rapido"

```
/sdd-ff add-csv-export
```

Fast-forward: proposal -> specs + design -> tasks. Revision minima entre fases.

### "Tengo un PRD de mi PM"

```
Aqui tienes el PRD: docs/prd-dark-mode.md
```

El orquestador hace triaje, identifica que fases cubre el PRD, y ejecuta solo las faltantes.

### "Quiero implementar solo una fase de las tareas"

```
/sdd-apply
```

El orquestador implementa por lotes (Fase 1, luego Fase 2, etc.). Te muestra progreso entre lotes.

### "La verificacion fallo, que hago?"

El sub-agente de verificacion retorna un reporte con hallazgos FAIL. El orquestador te muestra las acciones requeridas. Puedes:

1. Corregir manualmente y re-verificar: `/sdd-verify`
2. Pedir al orquestador que lance apply para corregir los issues

### "Quiero retomar un cambio que deje a medias"

```
/sdd-continue add-csv-export
```

El orquestador detecta que artifacts existen y ejecuta la siguiente fase pendiente segun el grafo de dependencias.

---

## Sub-agentes: Que Lee y Que Escribe Cada Uno

Cada sub-agente es autonomo: sabe que archivos de `openspec/` leer y donde escribir. El orquestador solo le pasa el nombre del proyecto y del cambio.

| Sub-agente | Lee de openspec/ | Tambien lee | Escribe en openspec/ |
|------------|------------------|-------------|----------------------|
| **explore** | -- | Codigo del proyecto | exploration.md |
| **propose** | config.yaml, exploration.md (si existe) | -- | proposal.md |
| **spec** | proposal.md, specs/ existentes | -- | changes/{cambio}/specs/ |
| **design** | proposal.md, specs del cambio | Codigo fuente | design.md |
| **tasks** | design.md, specs del cambio | -- | tasks.md |
| **apply** | tasks.md, design.md | Codigo fuente, skill registry | Codigo + tasks.md (marca [x]) |
| **verify** | specs/, design.md, tasks.md | Codigo modificado, tests | verify-report.md |
| **archive** | tasks.md, verify-report.md, specs/ | specs/ principales | Mueve a archive/, actualiza specs/ |

---

## Tips

### Nombres de cambio

Usa nombres descriptivos y en kebab-case:

- `add-csv-export`
- `fix-auth-token-refresh`
- `refactor-user-service`
- `migrate-to-react-19`

### Revision entre fases

El orquestador siempre te pregunta antes de continuar. Aprovecha para:

- Revisar el proposal antes de que genere specs
- Ajustar el alcance si el design es demasiado ambicioso
- Reordenar tareas si el orden no tiene sentido

### Cuando un sub-agente se bloquea

Si un sub-agente retorna `status: blocked`, el orquestador te muestra el blocker. Opciones:

1. Resolver el problema manualmente y re-ejecutar la fase
2. Ajustar el artifact de la fase anterior (editar proposal.md, design.md, etc.)
3. Cancelar el cambio y empezar de nuevo

### Mantener specs actualizados

Cada vez que archivas un cambio, las specs del cambio se fusionan con `openspec/specs/`. Esto mantiene la fuente de verdad actualizada. Si otros cambios dependen de las mismas specs, se benefician automaticamente.

### Git y openspec

Incluye `openspec/` en tu repositorio. Los cambios activos en `openspec/changes/` documentan trabajo en progreso. Los archivados en `openspec/changes/archive/` son historial.

```gitignore
# No ignores openspec -- es documentacion valiosa
# openspec/
```

---

## Referencia Rapida

```
# Inicializar SDD en un proyecto
/sdd-init

# Explorar una idea (sin compromiso)
/sdd-explore como implementar dark mode

# Iniciar un cambio completo
/sdd-new add-dark-mode

# Fast-forward hasta tener tareas
/sdd-ff add-dark-mode

# Implementar por lotes
/sdd-apply

# Verificar contra specs
/sdd-verify

# Archivar cambio completado
/sdd-archive

# Retomar un cambio pendiente
/sdd-continue add-dark-mode
```

### Grafo de dependencias

```
proposal --> specs  \
                     +--> tasks --> apply --> verify --> archive
proposal --> design /
```

specs y design se pueden ejecutar en paralelo. Todo lo demas es secuencial.
