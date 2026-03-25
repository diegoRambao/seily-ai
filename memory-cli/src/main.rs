mod db;
mod types;

use clap::{Parser, Subcommand};
use std::process;
use types::{AddResponse, DeleteResponse, EntryType};

#[derive(Parser)]
#[command(name = "sailymem", version, about = "Seily — Persistent memory for AI agent sessions")]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    /// Add a memory entry
    Add {
        #[arg(short, long, value_parser = parse_entry_type)]
        r#type: EntryType,
        #[arg(short, long, group = "input")]
        content: Option<String>,
        #[arg(short, long, group = "input")]
        file: Option<String>,
        #[arg(long, value_delimiter = ',')]
        tags: Vec<String>,
        #[arg(long)]
        session_id: Option<String>,
    },
    /// Search entries (full-text via FTS5)
    Search {
        query: Option<String>,
        #[arg(short, long, value_parser = parse_entry_type)]
        r#type: Option<EntryType>,
        #[arg(long)]
        tags: Option<String>,
    },
    /// List recent entries
    List {
        #[arg(short, long)]
        last: Option<u32>,
        #[arg(short, long, value_parser = parse_entry_type)]
        r#type: Option<EntryType>,
    },
    /// Delete an entry by ID
    Delete { id: i64 },
    /// Export all entries as JSON
    Export,
}

fn parse_entry_type(s: &str) -> Result<EntryType, String> {
    s.parse()
}

fn err(msg: &str) -> ! {
    eprintln!("error: {msg}");
    process::exit(1);
}

fn main() {
    let cli = Cli::parse();
    let conn = db::init_db().unwrap_or_else(|e| err(&format!("db init failed: {e}")));

    match cli.cmd {
        Cmd::Add { r#type, content, file, tags, session_id } => {
            let body = match (content, file) {
                (Some(c), None) => c,
                (None, Some(path)) => std::fs::read_to_string(&path)
                    .unwrap_or_else(|_| err(&format!("file not found: {path}"))),
                (None, None) => err("--content or --file is required"),
                _ => unreachable!(),
            };
            if body.is_empty() {
                err("content cannot be empty");
            }
            let tags: Vec<String> = tags
                .iter()
                .map(|t| t.trim().to_lowercase())
                .filter(|t| !t.is_empty())
                .collect();
            let id = db::add_entry(&conn, &r#type, &body, &tags, session_id.as_deref())
                .unwrap_or_else(|e| err(&format!("add failed: {e}")));
            print_json(&AddResponse { status: "ok", id });
        }
        Cmd::Search { query, r#type, tags } => {
            let entries = if let Some(q) = &query {
                db::search_fts(&conn, q, r#type.as_ref(), tags.as_deref())
                    .unwrap_or_else(|e| err(&format!("search failed: {e}")))
            } else if r#type.is_some() || tags.is_some() {
                db::filter_entries(&conn, r#type.as_ref(), tags.as_deref())
                    .unwrap_or_else(|e| err(&format!("search failed: {e}")))
            } else {
                err("provide a query or --type/--tags filter");
            };
            print_json(&entries);
        }
        Cmd::List { last, r#type } => {
            let entries = db::list_entries(&conn, last, r#type.as_ref())
                .unwrap_or_else(|e| err(&format!("list failed: {e}")));
            print_json(&entries);
        }
        Cmd::Delete { id } => {
            let found = db::delete_entry(&conn, id)
                .unwrap_or_else(|e| err(&format!("delete failed: {e}")));
            if !found {
                err(&format!("entry {id} not found"));
            }
            print_json(&DeleteResponse { status: "ok", deleted: id });
        }
        Cmd::Export => {
            let entries = db::export_all(&conn)
                .unwrap_or_else(|e| err(&format!("export failed: {e}")));
            print_json(&entries);
        }
    }
}

fn print_json<T: serde::Serialize>(val: &T) {
    println!("{}", serde_json::to_string(val).unwrap());
}
