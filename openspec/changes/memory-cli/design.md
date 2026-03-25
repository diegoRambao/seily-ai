# Design: memory-cli

## Arquitectura

```
┌─────────────┐     stdin/stdout      ┌──────────────┐
│   Agente IA │ ──── mem <cmd> ─────▶ │  memory-cli   │
└─────────────┘      JSON response    │              │
                    ◀──────────────── │  ┌────────┐  │
                                      │  │ clap   │  │
                                      │  │ router │  │
                                      │  └───┬────┘  │
                                      │      │       │
                                      │  ┌───▼────┐  │
                                      │  │   db   │  │
                                      │  │ module │  │
                                      │  └───┬────┘  │
                                      └──────┼───────┘
                                             │
                                      ┌──────▼───────┐
                                      │ SQLite + FTS5│
                                      │  memory.db   │
                                      └──────────────┘
```

Arquitectura simple de 3 capas: CLI parsing → lógica de negocio → storage.

## Estructura de Archivos

```
memory-cli/
├── Cargo.toml
└── src/
    ├── main.rs        # Entry point, clap CLI definition, routing
    ├── db.rs          # SQLite connection, schema init, CRUD + FTS5 queries
    └── types.rs       # Structs: Entry, EntryType, AddResult, SearchResult
```

3 archivos. Sin over-engineering.

## Schema SQLite

```sql
CREATE TABLE IF NOT EXISTS entries (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    type       TEXT NOT NULL CHECK(type IN ('decision','snippet','context')),
    content    TEXT NOT NULL,
    tags       TEXT DEFAULT '',
    session_id TEXT,
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);

CREATE VIRTUAL TABLE IF NOT EXISTS entries_fts USING fts5(
    content,
    tags,
    content=entries,
    content_rowid=id
);

-- Triggers para mantener FTS5 sincronizado
CREATE TRIGGER IF NOT EXISTS entries_ai AFTER INSERT ON entries BEGIN
    INSERT INTO entries_fts(rowid, content, tags) VALUES (new.id, new.content, new.tags);
END;

CREATE TRIGGER IF NOT EXISTS entries_ad AFTER DELETE ON entries BEGIN
    INSERT INTO entries_fts(entries_fts, rowid, content, tags) VALUES('delete', old.id, old.content, old.tags);
END;
```

## Interfaces (structs públicos)

### types.rs
```rust
pub enum EntryType { Decision, Snippet, Context }

pub struct Entry {
    pub id: i64,
    pub entry_type: EntryType,
    pub content: String,
    pub tags: Vec<String>,
    pub session_id: Option<String>,
    pub created_at: String,
}
```

### db.rs — funciones públicas
```rust
pub fn init_db() -> Result<Connection>
pub fn add_entry(conn: &Connection, entry_type: EntryType, content: &str, tags: &[String], session_id: Option<&str>) -> Result<i64>
pub fn search_fts(conn: &Connection, query: &str, type_filter: Option<EntryType>, tag_filter: Option<&str>) -> Result<Vec<Entry>>
pub fn list_entries(conn: &Connection, last_n: Option<u32>, type_filter: Option<EntryType>) -> Result<Vec<Entry>>
pub fn delete_entry(conn: &Connection, id: i64) -> Result<bool>
pub fn export_all(conn: &Connection) -> Result<Vec<Entry>>
```

### main.rs — clap CLI
```rust
#[derive(Parser)]
#[command(name = "mem")]
enum Cli {
    Add { type, content/file, tags, session_id },
    Search { query, type, tags },
    List { last, type },
    Delete { id },
    Export {},
}
```

## Dependencias (Cargo.toml)
```toml
[dependencies]
clap = { version = "4", features = ["derive"] }
rusqlite = { version = "0.31", features = ["bundled", "fts5"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
directories = "5"
```

## Decisiones de Diseño

1. **Sin async** — operaciones son locales y síncronas, async agrega complejidad sin beneficio
2. **FTS5 triggers** — mantienen el índice sincronizado automáticamente, sin lógica extra en Rust
3. **bundled SQLite** — el binario incluye SQLite, zero dependencias externas en runtime
4. **3 archivos** — suficiente separación sin fragmentar un proyecto pequeño
5. **JSON siempre a stdout** — el agente parsea sin ambigüedad, errores a stderr como texto
