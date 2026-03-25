#!/usr/bin/env bash
# adapters/antigravity.sh — Adapter for Antigravity
#
# Global:
#   ~/.gemini/antigravity/skills/<name>/SKILL.md
#
# Project:
#   .agents/skills/  → symlink to $BUNDLE_DIR/skills

ANTIGRAVITY_GLOBAL_DIR="$HOME/.gemini/antigravity"

setup_antigravity_global() {
  log_section "Antigravity — Global"

  ensure_dir "$ANTIGRAVITY_GLOBAL_DIR/skills"

  # 1. Install skills
  log_info "Installing skills to ~/.gemini/antigravity/skills/..."
  install_skills_as_skillmd "$BUNDLE_DIR/skills" "$ANTIGRAVITY_GLOBAL_DIR/skills"

  log_ok "Antigravity global setup complete"
}

setup_antigravity_project() {
  local project_dir="${1:-$(pwd)}"
  log_section "Antigravity — Project ($(basename "$project_dir"))"

  # 1. Symlink .agents/skills
  local link_path="$project_dir/.agents/skills"
  ensure_dir "$project_dir/.agents"
  safe_symlink "$link_path" "$BUNDLE_DIR/skills"

  log_info "Note: Antigravity reads project skills from .agents/skills/"
  log_ok "Antigravity project setup complete"
}

setup_antigravity() {
  [[ "$SCOPE_GLOBAL"  == "true" ]] && setup_antigravity_global
  [[ "$SCOPE_PROJECT" == "true" ]] && setup_antigravity_project
  return 0
}
