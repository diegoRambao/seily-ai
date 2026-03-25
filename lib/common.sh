#!/usr/bin/env bash
# lib/common.sh — Shared utilities: colors, logging, backup, tool detection
# Sourced by install.sh and all adapters. Do NOT execute directly.

# =============================================================================
# COLORS & FORMATTING
# =============================================================================

if [[ -t 1 ]] && command -v tput &>/dev/null; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  BLUE=$(tput setaf 4)
  CYAN=$(tput setaf 6)
  BOLD=$(tput bold)
  DIM=$(tput dim)
  NC=$(tput sgr0)
else
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  DIM='\033[2m'
  NC='\033[0m'
fi

# =============================================================================
# LOGGING
# =============================================================================

log_info()    { echo -e "  ${BLUE}→${NC} $*"; }
log_ok()      { echo -e "  ${GREEN}✓${NC} $*"; }
log_warn()    { echo -e "  ${YELLOW}!${NC} $*"; }
log_error()   { echo -e "  ${RED}✗${NC} $*" >&2; }
log_step()    { echo -e "${BOLD}${CYAN}[$1/$2]${NC} ${BOLD}$3${NC}"; }
log_section() { echo -e "\n${BOLD}$*${NC}"; }
log_dim()     { echo -e "  ${DIM}$*${NC}"; }

# =============================================================================
# DRY-RUN SUPPORT
# =============================================================================

# Set DRY_RUN=true before sourcing to enable dry-run mode.
# All mutating operations should gate on this flag via `run_cmd`.
DRY_RUN=${DRY_RUN:-false}

run_cmd() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_dim "[dry-run] $*"
  else
    "$@"
  fi
}

# =============================================================================
# BACKUP
# =============================================================================

# Create a timestamped backup of a file or directory.
# Usage: backup_if_exists "/path/to/file"
backup_if_exists() {
  local target="$1"
  if [[ -e "$target" ]]; then
    local backup="${target}.bak.$(date +%s)"
    run_cmd cp -r "$target" "$backup"
    log_warn "Backed up existing $(basename "$target") → $(basename "$backup")"
    echo "$backup"  # Return backup path on stdout
  fi
}

# =============================================================================
# FILE / DIRECTORY HELPERS
# =============================================================================

# Ensure a directory exists (no-op if it already does).
ensure_dir() {
  local dir="$1"
  # Remove blocking file or broken symlink before creating directory
  if [[ -e "$dir" && ! -d "$dir" ]] || [[ -L "$dir" && ! -d "$dir" ]]; then
    run_cmd rm -f "$dir"
  fi
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
    log_info "Created directory: $dir"
  fi
}

# Copy a file, creating parent dirs as needed.
# Usage: safe_copy <src> <dst>
safe_copy() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  run_cmd cp "$src" "$dst"
}

# Copy a directory recursively (merge, not replace).
# Usage: safe_copy_dir <src_dir> <dst_dir>
safe_copy_dir() {
  local src="$1" dst="$2"
  ensure_dir "$dst"
  run_cmd cp -r "$src/." "$dst/"
}

# Create/replace a symlink safely.
# Usage: safe_symlink <link_path> <target>
safe_symlink() {
  local link="$1" target="$2"
  ensure_dir "$(dirname "$link")"
  if [[ -L "$link" ]]; then
    run_cmd rm "$link"
  elif [[ -e "$link" ]]; then
    backup_if_exists "$link"
    run_cmd rm -rf "$link"
  fi
  run_cmd ln -s "$target" "$link"
  log_ok "Symlink: $link → $target"
}

# =============================================================================
# JSON HELPERS (pure bash + python3 fallback)
# =============================================================================

# Check if python3 is available (needed for JSON manipulation)
require_python3() {
  if ! command -v python3 &>/dev/null; then
    log_error "python3 is required for JSON manipulation but was not found."
    return 1
  fi
}

# Merge a JSON object into an existing JSON file under a given key path.
# Usage: json_merge_key <file> <key> <json_value_file>
# Example: json_merge_key ~/.config/opencode/opencode.json "agent.tech-lead" /tmp/tech-lead.json
json_merge_key() {
  local target_file="$1"
  local key_path="$2"
  local value_file="$3"

  require_python3 || return 1

  if [[ "$DRY_RUN" == "true" ]]; then
    log_dim "[dry-run] Would merge $key_path into $target_file"
    return 0
  fi

  python3 - "$target_file" "$key_path" "$value_file" <<'PYEOF'
import json, sys

target_path = sys.argv[1]
key_path    = sys.argv[2]
value_path  = sys.argv[3]

with open(target_path) as f:
    target = json.load(f)

with open(value_path) as f:
    value = json.load(f)

# Navigate / create nested keys
keys = key_path.split(".")
node = target
for k in keys[:-1]:
    node = node.setdefault(k, {})

# Merge (not replace) if both are dicts
leaf_key = keys[-1]
if isinstance(node.get(leaf_key), dict) and isinstance(value, dict):
    node[leaf_key].update(value)
else:
    node[leaf_key] = value

with open(target_path, "w") as f:
    json.dump(target, f, indent=2, ensure_ascii=False)
    f.write("\n")

print("ok")
PYEOF
}

# Read a JSON field value from a file.
# Usage: json_get <file> <key_path>
json_get() {
  local file="$1" key_path="$2"
  require_python3 || return 1
  python3 - "$file" "$key_path" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
keys = sys.argv[2].split(".")
node = data
for k in keys:
    if isinstance(node, dict):
        node = node.get(k)
    else:
        node = None
        break
if node is not None:
    print(json.dumps(node) if isinstance(node, (dict, list)) else str(node))
PYEOF
}

# =============================================================================
# YAML FRONTMATTER HELPERS
# =============================================================================

# Extract a top-level scalar field from YAML frontmatter of a SKILL.md file.
# Usage: skill_get_field <skill_md_file> <field_name>
skill_get_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---$/ { fm = !fm; next }
    fm && $1 == f":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      # Multi-line block scalar (">")
      if ($0 == ">" || $0 == "|") {
        val = ""; getline
        while (/^[[:space:]]/ && !/^---$/) { gsub(/^[[:space:]]+/, ""); val = val $0 " "; getline }
        sub(/ $/, "", val); print val; exit
      }
      gsub(/^["'"'"'"]|["'"'"'"]$/, ""); print; exit
    }
  ' "$file"
}

# Get skill name from SKILL.md frontmatter.
skill_name() { skill_get_field "$1" "name"; }

# Get skill description from SKILL.md frontmatter.
skill_description() { skill_get_field "$1" "description"; }

# =============================================================================
# TOOL DETECTION
# =============================================================================

# Check if a tool config directory exists.
# Usage: tool_installed <dir_path>
tool_installed() {
  [[ -d "$1" ]]
}

detect_tools() {
  OPENCODE_INSTALLED=false
  CLAUDE_INSTALLED=false
  KIRO_INSTALLED=false
  COPILOT_INSTALLED=false
  ANTIGRAVITY_INSTALLED=false

  tool_installed "$HOME/.config/opencode"        && OPENCODE_INSTALLED=true
  tool_installed "$HOME/.claude"                 && CLAUDE_INSTALLED=true
  [[ -d "$HOME/.kiro" || -d "$HOME/.config/kiro" ]] && KIRO_INSTALLED=true
  tool_installed "$HOME/.config/github-copilot"  && COPILOT_INSTALLED=true
  tool_installed "$HOME/.gemini/antigravity"     && ANTIGRAVITY_INSTALLED=true
}

# Print detection summary
print_detection() {
  log_section "Detected tools on this system:"
  local tools=(
    "OpenCode:$OPENCODE_INSTALLED:~/.config/opencode/"
    "Claude Code:$CLAUDE_INSTALLED:~/.claude/"
    "Kiro (AWS):$KIRO_INSTALLED:~/.kiro/"
    "GitHub Copilot:$COPILOT_INSTALLED:~/.config/github-copilot/"
    "Antigravity:$ANTIGRAVITY_INSTALLED:~/.gemini/antigravity/"
  )
  for entry in "${tools[@]}"; do
    IFS=: read -r name installed path <<< "$entry"
    if [[ "$installed" == "true" ]]; then
      echo -e "  ${GREEN}✓${NC} $name ${DIM}($path)${NC}"
    else
      echo -e "  ${DIM}○ $name (not detected)${NC}"
    fi
  done
  echo ""
}

# =============================================================================
# BUNDLE LOCATION
# =============================================================================

# Resolve the bundle directory.
# When run via curl pipe, BUNDLE_DIR is set by install.sh to the temp clone.
# When run from the cloned repo, it's relative to the script dir.
resolve_bundle_dir() {
  if [[ -n "$BUNDLE_DIR" && -d "$BUNDLE_DIR" ]]; then
    return 0
  fi
  # Relative to this lib/ file: ../bundle
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BUNDLE_DIR="$(dirname "$script_dir")/bundle"
  if [[ ! -d "$BUNDLE_DIR" ]]; then
    log_error "Bundle directory not found at $BUNDLE_DIR"
    return 1
  fi
}
