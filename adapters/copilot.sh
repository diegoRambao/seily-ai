#!/usr/bin/env bash
# adapters/copilot.sh — Adapter for GitHub Copilot (VS Code)
#
# Global:
#   ~/.agents/skills/<name>/SKILL.md  (cross-agent skills.sh ecosystem)
#   ~/.config/github-copilot/         (auth only, no skill config supported natively)
#
# Project:
#   .github/skills/               → symlink to $BUNDLE_DIR/skills
#   .github/copilot-instructions.md  (generated)

AGENTS_GLOBAL_DIR="$HOME/.agents/skills"

setup_copilot_global() {
  log_section "GitHub Copilot — Global"

  # GitHub Copilot doesn't have a dedicated global skills directory.
  # The best approach is to install into ~/.agents/skills which is the
  # cross-agent ecosystem used by skills.sh and consumed by Copilot.
  log_info "Installing skills to ~/.agents/skills/ (cross-agent ecosystem)..."
  ensure_dir "$AGENTS_GLOBAL_DIR"
  install_skills_as_skillmd "$BUNDLE_DIR/skills" "$AGENTS_GLOBAL_DIR"

  # Update .skill-lock.json if it exists
  _update_skill_lock

  # 3. Install custom agents
  log_info "Creating agent configs in ~/.copilot/agents/..."
  install_agents_copilot "$BUNDLE_DIR/agents" "$HOME/.copilot/agents"

  log_ok "GitHub Copilot global setup complete"
  log_warn "Note: Copilot reads skills via the ~/.agents/ cross-agent ecosystem."
  log_warn "      Restart VS Code / Copilot to load the new skills."
}

setup_copilot_project() {
  local project_dir="${1:-$(pwd)}"
  log_section "GitHub Copilot — Project ($(basename "$project_dir"))"

  # 1. Symlink .github/skills
  local link_path="$project_dir/.github/skills"
  ensure_dir "$project_dir/.github"
  safe_symlink "$link_path" "$BUNDLE_DIR/skills"

  # 2. Generate copilot-instructions.md
  log_info "Generating .github/copilot-instructions.md..."
  generate_instructions_md \
    "$BUNDLE_DIR/skills" \
    "$BUNDLE_DIR/agents" \
    "$project_dir/.github/copilot-instructions.md" \
    "GitHub Copilot"

  # 3. Install custom agents
  log_info "Creating agent configs in .github/agents/..."
  install_agents_copilot "$BUNDLE_DIR/agents" "$project_dir/.github/agents"

  log_ok "GitHub Copilot project setup complete"
}

_update_skill_lock() {
  local lock_file="$HOME/.agents/.skill-lock.json"
  if [[ ! -f "$lock_file" ]]; then
    if [[ "$DRY_RUN" != "true" ]]; then
      ensure_dir "$HOME/.agents"
      cat > "$lock_file" <<'EOF'
{
  "version": 3,
  "skills": {},
  "dismissed": {},
  "lastSelectedAgents": []
}
EOF
    else
      log_dim "[dry-run] Would create $lock_file"
      return 0
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_dim "[dry-run] Would update $lock_file"
    return 0
  fi

  require_python3 || return 1

  python3 - "$lock_file" "$BUNDLE_DIR/skills" <<'PYEOF'
import json, sys, os
from datetime import datetime

lock_path   = sys.argv[1]
skills_dir  = sys.argv[2]

with open(lock_path) as f:
    lock = json.load(f)

now = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")

for entry in os.listdir(skills_dir):
    skill_md = os.path.join(skills_dir, entry, "SKILL.md")
    if not os.path.isfile(skill_md):
        continue
    if entry not in lock["skills"]:
        lock["skills"][entry] = {
            "source": "local/ai-env-setup",
            "sourceType": "local",
            "sourceUrl": "",
            "skillPath": f"skills/{entry}/SKILL.md",
            "skillFolderHash": "",
            "pluginName": entry,
            "installedAt": now,
            "updatedAt": now
        }
    else:
        lock["skills"][entry]["updatedAt"] = now

with open(lock_path, "w") as f:
    json.dump(lock, f, indent=2, ensure_ascii=False)
    f.write("\n")
PYEOF
  log_ok "Updated ~/.agents/.skill-lock.json"
}

setup_copilot() {
  [[ "$SCOPE_GLOBAL"  == "true" ]] && setup_copilot_global
  [[ "$SCOPE_PROJECT" == "true" ]] && setup_copilot_project
  return 0
}
