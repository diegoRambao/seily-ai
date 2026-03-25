use directories::ProjectDirs;
use rusqlite::{Connection, Result, params};
use std::path::PathBuf;

use crate::types::{Entry, EntryType};

const SCHEMA: &str = "
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

CREATE TRIGGER IF NOT EXISTS entries_ai AFTER INSERT ON entries BEGIN
    INSERT INTO entries_fts(rowid, content, tags) VALUES (new.id, new.content, new.tags);
END;

CREATE TRIGGER IF NOT EXISTS entries_ad AFTER DELETE ON entries BEGIN
    INSERT INTO entries_fts(entries_fts, rowid, content, tags) VALUES('delete', old.id, old.content, old.tags);
END;
";

fn db_path() -> PathBuf {
    if let Some(dirs) = ProjectDirs::from("", "", "seily") {
        let config = dirs.config_dir().to_path_buf();
        std::fs::create_dir_all(&config).ok();
        config.join("sailymem.db")
    } else {
        PathBuf::from("memory.db")
    }
}

pub fn init_db() -> Result<Connection> {
    let conn = Connection::open(db_path())?;
    conn.execute_batch(SCHEMA)?;
    Ok(conn)
}

pub fn add_entry(
    conn: &Connection,
    entry_type: &EntryType,
    content: &str,
    tags: &[String],
    session_id: Option<&str>,
) -> Result<i64> {
    conn.execute(
        "INSERT INTO entries (type, content, tags, session_id) VALUES (?1, ?2, ?3, ?4)",
        params![entry_type.to_string(), content, tags.join(","), session_id],
    )?;
    Ok(conn.last_insert_rowid())
}

pub fn delete_entry(conn: &Connection, id: i64) -> Result<bool> {
    let affected = conn.execute("DELETE FROM entries WHERE id = ?1", params![id])?;
    Ok(affected > 0)
}

pub fn search_fts(
    conn: &Connection,
    query: &str,
    type_filter: Option<&EntryType>,
    tag_filter: Option<&str>,
) -> Result<Vec<Entry>> {
    let mut sql = String::from(
        "SELECT e.id, e.type, e.content, e.tags, e.session_id, e.created_at
         FROM entries_fts f
         JOIN entries e ON e.id = f.rowid
         WHERE entries_fts MATCH ?1"
    );
    if type_filter.is_some() {
        sql.push_str(" AND e.type = ?2");
    }
    if tag_filter.is_some() {
        sql.push_str(if type_filter.is_some() {
            " AND e.tags LIKE ?3"
        } else {
            " AND e.tags LIKE ?2"
        });
    }
    sql.push_str(" ORDER BY rank");

    let mut stmt = conn.prepare(&sql)?;

    let map_row = |row: &rusqlite::Row| -> Result<Entry> {
        let type_str: String = row.get(1)?;
        let tags_str: String = row.get(3)?;
        Ok(Entry {
            id: row.get(0)?,
            entry_type: type_str.parse().unwrap_or(EntryType::Context),
            content: row.get(2)?,
            tags: if tags_str.is_empty() {
                vec![]
            } else {
                tags_str.split(',').map(|s| s.trim().to_string()).collect()
            },
            session_id: row.get(4)?,
            created_at: row.get(5)?,
        })
    };

    let rows = match (type_filter, tag_filter) {
        (Some(t), Some(tag)) => {
            stmt.query_map(params![query, t.to_string(), format!("%{}%", tag)], map_row)?
        }
        (Some(t), None) => {
            stmt.query_map(params![query, t.to_string()], map_row)?
        }
        (None, Some(tag)) => {
            stmt.query_map(params![query, format!("%{}%", tag)], map_row)?
        }
        (None, None) => {
            stmt.query_map(params![query], map_row)?
        }
    };

    rows.collect()
}

pub fn list_entries(
    conn: &Connection,
    last_n: Option<u32>,
    type_filter: Option<&EntryType>,
) -> Result<Vec<Entry>> {
    let mut sql = String::from(
        "SELECT id, type, content, tags, session_id, created_at FROM entries"
    );
    if type_filter.is_some() {
        sql.push_str(" WHERE type = ?1");
    }
    sql.push_str(" ORDER BY created_at DESC");
    if last_n.is_some() {
        sql.push_str(if type_filter.is_some() { " LIMIT ?2" } else { " LIMIT ?1" });
    }

    let mut stmt = conn.prepare(&sql)?;

    let map_row = |row: &rusqlite::Row| -> Result<Entry> {
        let type_str: String = row.get(1)?;
        let tags_str: String = row.get(3)?;
        Ok(Entry {
            id: row.get(0)?,
            entry_type: type_str.parse().unwrap_or(EntryType::Context),
            content: row.get(2)?,
            tags: if tags_str.is_empty() {
                vec![]
            } else {
                tags_str.split(',').map(|s| s.trim().to_string()).collect()
            },
            session_id: row.get(4)?,
            created_at: row.get(5)?,
        })
    };

    let rows = match (type_filter, last_n) {
        (Some(t), Some(n)) => stmt.query_map(params![t.to_string(), n], map_row)?,
        (Some(t), None) => stmt.query_map(params![t.to_string()], map_row)?,
        (None, Some(n)) => stmt.query_map(params![n], map_row)?,
        (None, None) => stmt.query_map([], map_row)?,
    };

    rows.collect()
}

pub fn export_all(conn: &Connection) -> Result<Vec<Entry>> {
    list_entries(conn, None, None)
}

pub fn filter_entries(
    conn: &Connection,
    type_filter: Option<&EntryType>,
    tag_filter: Option<&str>,
) -> Result<Vec<Entry>> {
    let mut sql = String::from(
        "SELECT id, type, content, tags, session_id, created_at FROM entries WHERE 1=1"
    );
    if type_filter.is_some() {
        sql.push_str(" AND type = ?1");
    }
    if tag_filter.is_some() {
        sql.push_str(if type_filter.is_some() {
            " AND tags LIKE ?2"
        } else {
            " AND tags LIKE ?1"
        });
    }
    sql.push_str(" ORDER BY created_at DESC");

    let mut stmt = conn.prepare(&sql)?;

    let map_row = |row: &rusqlite::Row| -> Result<Entry> {
        let type_str: String = row.get(1)?;
        let tags_str: String = row.get(3)?;
        Ok(Entry {
            id: row.get(0)?,
            entry_type: type_str.parse().unwrap_or(EntryType::Context),
            content: row.get(2)?,
            tags: if tags_str.is_empty() {
                vec![]
            } else {
                tags_str.split(',').map(|s| s.trim().to_string()).collect()
            },
            session_id: row.get(4)?,
            created_at: row.get(5)?,
        })
    };

    let rows = match (type_filter, tag_filter) {
        (Some(t), Some(tag)) => stmt.query_map(params![t.to_string(), format!("%{}%", tag)], map_row)?,
        (Some(t), None) => stmt.query_map(params![t.to_string()], map_row)?,
        (None, Some(tag)) => stmt.query_map(params![format!("%{}%", tag)], map_row)?,
        (None, None) => stmt.query_map([], map_row)?,
    };

    rows.collect()
}
