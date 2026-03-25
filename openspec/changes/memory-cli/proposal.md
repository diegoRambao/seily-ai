# Proposal: memory-cli

## Objetivo
CLI en Rust que actúa como memoria persistente para agentes IA durante sesiones de desarrollo. Permite guardar, buscar y recuperar decisiones técnicas, snippets de código y contexto de conversación con latencia sub-milisegundo.

## Alcance

### Incluido
- Binario `mem` con subcomandos: add, search, list, delete, export
- Storage SQLite con FTS5 para búsqueda full-text
- Tipos de entrada: decision, snippet, context
- Sistema de tags para categorización
- Output JSON por stdout (consumible por agentes)
- Almacenamiento en ~/.config/memory-cli/memory.db (XDG)

### Excluido
- UI gráfica o TUI
- Sincronización remota / cloud
- Embeddings o búsqueda semántica (v1 es keyword-based)
- Autenticación o multi-usuario
- Daemon / servidor HTTP (es CLI puro)

## Enfoque Técnico
- **Rust** — rendimiento y binario estático
- **SQLite + FTS5** — búsqueda full-text en <1ms para cientos de entradas
- **clap derive** — parsing de argumentos ergonómico
- **rusqlite (bundled)** — SQLite embebido, sin dependencia externa
- **serde_json** — serialización de output
- **directories** — resolución de paths XDG multiplataforma

## Esquema de datos (conceptual)
- id: autoincrement
- type: enum (decision | snippet | context)
- content: texto libre (indexado por FTS5)
- tags: texto separado por comas
- created_at: timestamp ISO 8601
- session_id: identificador opcional de sesión

## Interfaz CLI
```
mem add --type <type> --tags <tags> --content <text>
mem add --type snippet --file <path>
mem search <query>                    # FTS5 full-text
mem search --type <type> --tags <tag> # filtrado exacto
mem list [--last N] [--type <type>]
mem delete <id>
mem export [--format json]
```

## Riesgos
- FTS5 no disponible en todas las builds de SQLite → mitigado con rusqlite bundled
- Para volúmenes >10k entradas, FTS5 sigue siendo rápido, pero el schema podría necesitar optimización → fuera de scope v1
