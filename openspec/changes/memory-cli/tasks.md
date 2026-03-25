# Tasks: memory-cli

## Lote 1: Scaffold + Storage (tareas 1-3)

### T1: Inicializar proyecto Cargo
- `cargo init --name memory-cli`
- Configurar Cargo.toml con dependencias: clap (derive), rusqlite (bundled, fts5), serde (derive), serde_json, directories
- Verificar: `cargo check` pasa

### T2: Crear types.rs
- Definir `EntryType` enum con Display/FromStr para clap + serde
- Definir `Entry` struct con Serialize
- Definir structs de respuesta JSON: `AddResponse`, `DeleteResponse`

### T3: Crear db.rs — init + add + delete
- `init_db()`: abrir/crear DB en XDG config dir, ejecutar schema SQL (tabla entries + entries_fts + triggers)
- `add_entry()`: INSERT en entries, retornar id
- `delete_entry()`: DELETE por id, retornar bool (existía o no)

## Lote 2: Queries + CLI (tareas 4-6)

### T4: db.rs — search + list + export
- `search_fts()`: query FTS5 con filtros opcionales de type y tag
- `list_entries()`: SELECT con ORDER BY created_at DESC, LIMIT opcional, filtro type opcional
- `export_all()`: SELECT * ordenado por id

### T5: Crear main.rs — CLI con clap
- Definir enum `Cli` con derive(Parser) y subcomandos: Add, Search, List, Delete, Export
- Add: --type (required), --content o --file (mutuamente excluyentes), --tags, --session-id
- Search: query posicional opcional, --type, --tags
- List: --last, --type
- Delete: id posicional
- Export: sin args

### T6: main.rs — routing y output JSON
- Match sobre Cli, llamar funciones de db.rs
- Serializar resultados a JSON y escribir a stdout
- Errores a stderr con exit code 1
- Validaciones: content no vacío, --file existe, --content y --file mutuamente excluyentes

## Lote 3: Polish (tarea 7)

### T7: Validación final
- Verificar `cargo build --release`
- Probar manualmente los 12 escenarios de specs.md
- Verificar que search FTS5 funciona con queries parciales
