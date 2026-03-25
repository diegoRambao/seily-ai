# Seily

Your AI development companion. Installs the SDD (Spec-Driven Development) agent bundle — skills, agents, and **Seily Memory** (`sailymem`) — across multiple AI coding tools with a single command.

## Quick start

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/diegoRambao/ai-env-setup/main/install.sh | bash
```

### Interactive (recommended)

```bash
git clone https://github.com/diegoRambao/ai-env-setup.git
cd ai-env-setup
./install.sh
```

### Specific tools

```bash
./install.sh --opencode --claude           # OpenCode + Claude Code, global + project
./install.sh --global --kiro               # Only Kiro, only global
./install.sh --project --copilot           # Only project level
./install.sh --all                         # Everything
./install.sh --dry-run --all               # Preview without changes
```

## Prerequisites

| Requirement | Why | How to install |
|-------------|-----|----------------|
| Bash 4+ | Installer uses associative arrays | `brew install bash` (macOS ships Bash 3) |
| python3 | JSON manipulation in installer | Comes with macOS / `apt install python3` |
| curl or git | Download repo in one-liner mode | Pre-installed on most systems |
| Rust toolchain | Build `sailymem` | Auto-installed by installer if missing |

> The installer will automatically install Rust via [rustup](https://rustup.rs) if it's not found.

## What gets installed

### 1. SDD Skills (9 skills)

| Skill | Purpose |
|-------|---------|
| `sdd-init` | Initialize SDD environment in a project |
| `sdd-propose` | Create a change proposal |
| `sdd-spec` | Write business specs and scenarios |
| `sdd-design` | Technical architecture and design |
| `sdd-task` | Break design into step-by-step tasks |
| `sdd-explore` | Research and explore the codebase |
| `sdd-apply` | Implement tasks (writes code) |
| `sdd-verify` | Verify implementation matches specs |
| `sdd-archive` | Archive and document completed changes |

### 2. Agents (2)

| Agent | Mode | Purpose |
|-------|------|---------|
| `sdd-orchestrator` | all | SDD workflow orchestrator — delegates to sub-agents, never writes code itself |
| `tech-lead` | primary | Senior engineer / tutor — explains concepts, enforces best practices |

### 3. Seily Memory (`sailymem`)

A fast, persistent memory system for AI agent sessions. Built in Rust with SQLite + FTS5 full-text search.

Installed globally to `/usr/local/bin/sailymem`.

---

## Seily Memory

### Why

AI agents lose context between sessions. Every time you start a new conversation, the agent forgets past decisions, code patterns, and project context. **Seily Memory solves this** by giving agents a persistent, searchable memory store they can read and write to via a simple CLI.

### How it works

`sailymem` is a Rust binary that stores entries in a local SQLite database with FTS5 full-text indexing. The agent calls `sailymem` as a subprocess and gets JSON back on stdout. Searches run in **sub-millisecond** time.

```
┌─────────────┐  sailymem search "auth"  ┌──────────────┐     ┌──────────────┐
│   AI Agent  │ ───────────────────────▶  │   sailymem   │ ──▶ │ SQLite + FTS5│
│             │ ◀──── JSON on stdout ──── │              │ ◀── │ sailymem.db  │
└─────────────┘                           └──────────────┘     └──────────────┘
```

### Entry types

| Type | What to store | Example |
|------|---------------|---------|
| `decision` | Technical decisions and rationale | "Chose SQLite over Postgres for embedded use" |
| `snippet` | Reusable code patterns | Error handling patterns, utility functions |
| `context` | Session context and project knowledge | "User prefers Rust for CLI tools" |

### Commands

```bash
# Add entries
sailymem add --type decision --content "Use SQLite for FTS5 support" --tags db,perf
sailymem add --type snippet --file ./auth-middleware.rs --tags auth,middleware
sailymem add --type context --content "Project uses monorepo with Cargo workspaces" --tags architecture

# Search (full-text, sub-millisecond)
sailymem search "sqlite"                          # FTS5 full-text search
sailymem search --type decision                   # Filter by type
sailymem search --type decision --tags db         # Filter by type + tag
sailymem search "authentication" --type snippet   # Full-text + type filter

# List recent entries
sailymem list                                     # All entries, newest first
sailymem list --last 10                           # Last 10 entries
sailymem list --type decision                     # Only decisions

# Manage
sailymem delete 42                                # Delete by ID
sailymem export                                   # Dump everything as JSON
```

### Output format

All output is JSON on stdout. Errors go to stderr. Exit code 0 = success, 1 = error.

```bash
$ sailymem add --type decision --content "Use FTS5" --tags db
{"status":"ok","id":1}

$ sailymem search "FTS5"
[{"id":1,"type":"decision","content":"Use FTS5","tags":["db"],"created_at":"2025-03-25T05:17:18Z"}]

$ sailymem delete 999
error: entry 999 not found    # stderr, exit code 1
```

### Use cases

**1. Persisting technical decisions across sessions**
```bash
# Session 1: Agent makes a decision
sailymem add --type decision --content "Using JWT for auth instead of sessions — stateless, scales horizontally" --tags auth,architecture

# Session 2 (days later): New agent picks up context
sailymem search "auth"
# → Returns the JWT decision with full rationale
```

**2. Saving reusable code patterns**
```bash
# Agent discovers a useful error handling pattern
sailymem add --type snippet --content "impl From<DbError> for ApiError { ... }" --tags error-handling,rust

# Later, in another project
sailymem search "error handling"
```

**3. Remembering user preferences**
```bash
sailymem add --type context --content "User prefers minimal dependencies, no async unless necessary" --tags preferences
sailymem add --type context --content "Project convention: all errors return JSON with status field" --tags conventions

# Any future agent session
sailymem search --type context --tags preferences
```

**4. Agent-to-agent knowledge transfer**
```bash
# SDD orchestrator archives a completed change
sailymem add --type decision --content "Migrated from REST to gRPC for internal services — 3x throughput improvement" --tags migration,grpc --session-id sdd-42

# Tech lead agent retrieves past migrations
sailymem search "migration" --type decision
```

### Storage location

| OS | Path |
|----|------|
| macOS | `~/Library/Application Support/seily/sailymem.db` |
| Linux | `~/.config/seily/sailymem.db` |

The database is created automatically on first use.

---

## Supported tools

| Tool | Global config | Project config |
|------|---------------|----------------|
| **OpenCode** | `~/.config/opencode/` | `.opencode/skills/` |
| **Claude Code** | `~/.claude/` | `CLAUDE.md` + `.claude/skills/` |
| **Kiro (AWS)** | `~/.kiro/` | `.kiro/skills/` + `.kiro/steering/` |
| **GitHub Copilot** | `~/.config/github-copilot/` | `.github/copilot-instructions.md` |
| **Antigravity** | `~/.gemini/antigravity/` | `.agents/skills/` |

## SDD Workflow

```
/sdd-new <name>    →  propose
/sdd-ff <name>     →  propose → spec + design (parallel) → tasks
/sdd-apply <name>  →  apply (in batches of 3-5 tasks)
/sdd-verify        →  verify
/sdd-archive       →  archive
```

All artifacts are stored in `openspec/changes/<name>/`.

## Repository structure

```
seily/
├── install.sh              # Main installer (entrypoint)
├── memory-cli/             # Seily Memory source (Rust)
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs         # CLI definition + routing
│       ├── db.rs           # SQLite + FTS5 storage layer
│       └── types.rs        # Data types and JSON responses
├── bundle/
│   ├── skills/             # Canonical SKILL.md files (source of truth)
│   │   ├── sdd-init/SKILL.md
│   │   ├── sdd-propose/SKILL.md
│   │   └── ...
│   └── agents/             # Agent definitions (canonical JSON)
│       ├── tech-lead.json
│       └── sdd-orchestrator.json
├── adapters/               # Per-tool transformation logic
│   ├── opencode.sh
│   ├── claude.sh
│   ├── kiro.sh
│   ├── copilot.sh
│   └── antigravity.sh
└── lib/                    # Shared utilities
    ├── common.sh           # Colors, logging, backup, JSON helpers
    ├── menu.sh             # Interactive checkbox menus
    └── transform.sh        # SKILL.md → native format transformers
```

## Scope: global vs project

| Scope | What it does |
|-------|-------------|
| **Global** | Installs skills and agents into the tool's user-level config directory. Active for every project. |
| **Project** | Creates symlinks and instruction files (CLAUDE.md, etc.) in the current working directory. Scoped to that repo. |

Both scopes can be enabled simultaneously. Seily Memory is always installed globally.

## Uninstall

```bash
# SDD skills & agents
rm -rf ~/.config/opencode/skills/sdd-*
rm -rf ~/.claude/skills/sdd-*  ~/.claude/CLAUDE.md
rm -rf ~/.kiro/skills/sdd-*    ~/.kiro/agents/sdd-orchestrator.json ~/.kiro/agents/tech-lead.json
rm -rf ~/.gemini/antigravity/skills/sdd-*

# Seily Memory
rm -f /usr/local/bin/sailymem
rm -rf ~/Library/Application\ Support/seily/   # macOS
rm -rf ~/.config/seily/                         # Linux

# Project level
rm -rf .opencode/skills .claude/skills .kiro/skills .github/skills .agents/skills
rm -f CLAUDE.md .github/copilot-instructions.md .kiro/kiro-instructions.md
```

## Adding skills

1. Add a directory under `bundle/skills/<skill-name>/`
2. Create a `SKILL.md` file with YAML frontmatter:

```markdown
---
name: my-skill
description: >
  What this skill does and when to trigger it.
---

## Instructions
...
```

3. Re-run `./install.sh` to push the new skill to all configured tools.

## License

MIT
