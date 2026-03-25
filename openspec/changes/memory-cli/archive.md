# Archive: memory-cli

## Estado: COMPLETADO ✅
## Fecha: 2026-03-25

## Resumen
CLI en Rust (`mem`) para memoria persistente de sesiones de agentes IA.
SQLite + FTS5 para búsqueda full-text sub-milisegundo.

## Artifacts producidos
- prd.md — requisitos del usuario
- proposal.md — objetivo, alcance, enfoque
- specs.md — 7 reglas de negocio, 12 escenarios
- design.md — arquitectura, schema SQL, interfaces
- tasks.md — 7 tareas en 3 lotes

## Archivos implementados
- memory-cli/Cargo.toml
- memory-cli/src/main.rs (CLI + routing)
- memory-cli/src/db.rs (SQLite + FTS5 + CRUD)
- memory-cli/src/types.rs (Entry, EntryType, responses)

## Verificación
- 12/12 escenarios pasados
- 7/7 reglas de negocio cumplidas
- 1 bug encontrado y corregido durante verify (filter_entries para search sin query)
- 1 fix de dependencia (rusqlite bundled-full)

## Comandos del CLI
| Comando | Descripción |
|---------|-------------|
| mem add --type <t> --content <c> [--tags t1,t2] | Agregar entrada |
| mem add --type <t> --file <path> [--tags t1,t2] | Agregar desde archivo |
| mem search <query> | Búsqueda full-text FTS5 |
| mem search --type <t> [--tags <tag>] | Filtrado exacto |
| mem list [--last N] [--type <t>] | Listar entradas |
| mem delete <id> | Eliminar entrada |
| mem export | Dump completo JSON |

## Decisiones técnicas clave
- SQLite + FTS5 sobre alternativas (redb, sled, LMDB) por FTS built-in
- rusqlite bundled-full para incluir FTS5 sin deps externas
- Sin async — operaciones locales síncronas
- 3 archivos — mínima separación sin over-engineering
- JSON siempre a stdout, errores a stderr
