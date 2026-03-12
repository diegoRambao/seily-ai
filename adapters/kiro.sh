#!/usr/bin/env bash
# adapters/kiro.sh — Adapter for Kiro (AWS IDE)
#
# Global:
#   ~/.kiro/agents/<name>.md      (Kiro agent markdown format)
#   ~/.kiro/skills/<name>/SKILL.md
#   ~/.kiro/steering/sdd.md       (Steering document with SDD overview)
#
# Project:
#   .kiro/agents/<name>.md  → agent markdown files
#   .kiro/skills/           → symlink to $BUNDLE_DIR/skills
#   .kiro/steering/         → generated SDD steering doc

KIRO_DIR="$HOME/.kiro"

setup_kiro_global() {
  log_section "Kiro (AWS) — Global"

  ensure_dir "$KIRO_DIR"

  # 1. Install skills
  log_info "Installing skills to ~/.kiro/skills/..."
  install_skills_as_skillmd "$BUNDLE_DIR/skills" "$KIRO_DIR/skills"

  # 2. Install agents (converted to Kiro format)
  log_info "Creating agent configs in ~/.kiro/agents/..."
  install_agents_kiro "$BUNDLE_DIR/agents" "$KIRO_DIR/agents"

  # 3. Create a steering document
  log_info "Generating steering document ~/.kiro/steering/sdd.md..."
  _generate_kiro_steering "$KIRO_DIR/steering/sdd.md"

  log_ok "Kiro global setup complete"
}

setup_kiro_project() {
  local project_dir="${1:-$(pwd)}"
  log_section "Kiro (AWS) — Project ($(basename "$project_dir"))"

  # 1. Symlink .kiro/skills
  local link_path="$project_dir/.kiro/skills"
  ensure_dir "$project_dir/.kiro"
  safe_symlink "$link_path" "$BUNDLE_DIR/skills"

  # 2. Install agents (converted to Kiro format)
  log_info "Creating agent configs in .kiro/agents/..."
  install_agents_kiro "$BUNDLE_DIR/agents" "$project_dir/.kiro/agents"

  # 3. Generate steering document
  log_info "Generating .kiro/steering/sdd.md..."
  _generate_kiro_steering "$project_dir/.kiro/steering/sdd.md"

  # 4. Generate kiro-instructions.md
  log_info "Generating .kiro/kiro-instructions.md..."
  generate_instructions_md \
    "$BUNDLE_DIR/skills" \
    "$BUNDLE_DIR/agents" \
    "$project_dir/.kiro/kiro-instructions.md" \
    "Kiro"

  log_ok "Kiro project setup complete"
}

_generate_kiro_steering() {
  local output="$1"
  ensure_dir "$(dirname "$output")"

  if [[ "$DRY_RUN" == "true" ]]; then
    log_dim "[dry-run] Would generate $output"
    return 0
  fi

  cat > "$output" <<'STEERING'
# SDD Workflow — Steering Document

> Installed by ai-env-setup. This document is always included in Kiro context.

## Spec-Driven Development (SDD)

Use SDD for multi-file changes. Use the `sdd-orchestrator` agent to coordinate.

## Quick Reference

| Command        | Action                                     |
|----------------|--------------------------------------------|
| `/sdd-new <name>`     | Start a new change (proposal phase)  |
| `/sdd-ff <name>`      | Fast-forward: propose → spec + design → tasks |
| `/sdd-apply <name>`   | Implement tasks in batches            |
| `/sdd-verify <name>`  | Verify implementation                 |
| `/sdd-archive <name>` | Archive completed change              |

## Artifact Store

All SDD artifacts are stored in `openspec/changes/<name>/`:

```
openspec/changes/<name>/
├── proposal.md    # Change intent and approach
├── spec.md        # Business rules and scenarios
├── design.md      # Technical architecture
├── tasks.md       # Step-by-step task breakdown
└── prd.md         # Original input document (if provided)
```

## Available Skills

Skills are located in `.kiro/skills/`. Each skill is a `SKILL.md` file
with YAML frontmatter and Markdown instructions.

Load a skill explicitly when starting a relevant task:
- `sdd-init` — Initialize SDD environment
- `sdd-propose` — Create change proposal
- `sdd-spec` — Write specifications
- `sdd-design` — Technical design
- `sdd-task` — Task breakdown
- `sdd-explore` — Research and exploration
- `sdd-apply` — Code implementation
- `sdd-verify` — Verification
- `sdd-archive` — Archive completed change
STEERING

  log_ok "Generated steering: $output"
}

setup_kiro() {
  [[ "$SCOPE_GLOBAL"  == "true" ]] && setup_kiro_global
  [[ "$SCOPE_PROJECT" == "true" ]] && setup_kiro_project
  return 0
}
