#!/usr/bin/env bash
# adapters/claude.sh — Adapter for Claude Code
#
# Global:
#   ~/.claude/skills/<name>/SKILL.md  (skills in global ~/.claude/skills)
#   ~/.claude/CLAUDE.md               (global instructions file)
#
# Project:
#   .claude/skills/ → symlink to $BUNDLE_DIR/skills
#   CLAUDE.md       (generated instructions at project root)

CLAUDE_DIR="$HOME/.claude"
CLAUDE_GLOBAL_SKILLS_DIR="$CLAUDE_DIR/skills"

setup_claude_global() {
  log_section "Claude Code — Global"

  ensure_dir "$CLAUDE_GLOBAL_SKILLS_DIR"

  # 1. Install skills
  log_info "Installing skills to ~/.claude/skills/..."
  install_skills_as_skillmd "$BUNDLE_DIR/skills" "$CLAUDE_GLOBAL_SKILLS_DIR"

  # 2. Generate global CLAUDE.md
  log_info "Generating ~/.claude/CLAUDE.md..."
  generate_instructions_md \
    "$BUNDLE_DIR/skills" \
    "$BUNDLE_DIR/agents" \
    "$CLAUDE_DIR/CLAUDE.md" \
    "Claude Code"

  # 3. Install agents
  log_info "Creating agent configs in ~/.claude/agents/..."
  install_agents_claude "$BUNDLE_DIR/agents" "$CLAUDE_DIR/agents"

  log_ok "Claude Code global setup complete"
}

setup_claude_project() {
  local project_dir="${1:-$(pwd)}"
  log_section "Claude Code — Project ($(basename "$project_dir"))"

  # 1. Symlink .claude/skills → bundle
  local link_path="$project_dir/.claude/skills"
  ensure_dir "$project_dir/.claude"
  safe_symlink "$link_path" "$BUNDLE_DIR/skills"

  # 2. Generate CLAUDE.md at project root
  log_info "Generating CLAUDE.md..."
  generate_instructions_md \
    "$BUNDLE_DIR/skills" \
    "$BUNDLE_DIR/agents" \
    "$project_dir/CLAUDE.md" \
    "Claude Code"

  # 3. Install agents
  log_info "Creating agent configs in .claude/agents/..."
  install_agents_claude "$BUNDLE_DIR/agents" "$project_dir/.claude/agents"

  log_ok "Claude Code project setup complete"
}

setup_claude() {
  [[ "$SCOPE_GLOBAL"  == "true" ]] && setup_claude_global
  [[ "$SCOPE_PROJECT" == "true" ]] && setup_claude_project
  return 0
}
