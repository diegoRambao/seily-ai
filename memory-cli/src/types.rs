use std::fmt;
use serde::Serialize;

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum EntryType {
    Decision,
    Snippet,
    Context,
}

impl fmt::Display for EntryType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Decision => write!(f, "decision"),
            Self::Snippet => write!(f, "snippet"),
            Self::Context => write!(f, "context"),
        }
    }
}

impl std::str::FromStr for EntryType {
    type Err = String;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "decision" => Ok(Self::Decision),
            "snippet" => Ok(Self::Snippet),
            "context" => Ok(Self::Context),
            _ => Err(format!("invalid type '{}': expected decision, snippet, or context", s)),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct Entry {
    pub id: i64,
    #[serde(rename = "type")]
    pub entry_type: EntryType,
    pub content: String,
    pub tags: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_id: Option<String>,
    pub created_at: String,
}

#[derive(Serialize)]
pub struct AddResponse {
    pub status: &'static str,
    pub id: i64,
}

#[derive(Serialize)]
pub struct DeleteResponse {
    pub status: &'static str,
    pub deleted: i64,
}
