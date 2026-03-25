#!/usr/bin/env bash
# adapters/opencode.sh — Adapter for OpenCode
#
# Global:
#   ~/.config/opencode/skills/<name>/SKILL.md  (native format, direct copy)
#   ~/.config/opencode/opencode.json           (agents injected under "agent" key)
#
# Project:
#   .opencode/skills/ → symlink to $BUNDLE_DIR/skills  (OpenCode reads natively)

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_CONFIG_FILE="$OPENCODE_CONFIG_DIR/opencode.json"

setup_opencode_global() {
  log_section "OpenCode — Global"

  # 1. Install skills
  log_info "Installing skills..."
  ensure_dir "$OPENCODE_CONFIG_DIR/skills"
  install_skills_as_skillmd "$BUNDLE_DIR/skills" "$OPENCODE_CONFIG_DIR/skills"

  # 2. Inject agents into opencode.json
  log_info "Injecting agents into opencode.json..."
  ensure_dir "$OPENCODE_CONFIG_DIR"

  # If no opencode.json exists, create a minimal one
  if [[ ! -f "$OPENCODE_CONFIG_FILE" ]]; then
    if [[ "$DRY_RUN" != "true" ]]; then
      cat > "$OPENCODE_CONFIG_FILE" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "anthropic/claude-opus-4-6",
  "autoupdate": true,
  "agent": {}
}
EOF
    else
      log_dim "[dry-run] Would create $OPENCODE_CONFIG_FILE"
    fi
    log_ok "Created opencode.json"
  fi

  inject_agents_opencode "$BUNDLE_DIR/agents" "$OPENCODE_CONFIG_FILE"

  log_ok "OpenCode global setup complete"
}

setup_opencode_project() {
  local project_dir="${1:-$(pwd)}"
  log_section "OpenCode — Project ($(basename "$project_dir"))"

  # OpenCode reads .opencode/skills/*.*/SKILL.md natively
  local link_path="$project_dir/.opencode/skills"
  ensure_dir "$project_dir/.opencode"

  safe_symlink "$link_path" "$BUNDLE_DIR/skills"
  log_info "OpenCode uses AGENTS.md natively — no extra instruction file needed."
  log_ok "OpenCode project setup complete"
}

setup_opencode() {
  [[ "$SCOPE_GLOBAL"  == "true" ]] && setup_opencode_global
  [[ "$SCOPE_PROJECT" == "true" ]] && setup_opencode_project
  return 0
}
