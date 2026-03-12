#!/usr/bin/env bash
# lib/menu.sh — Interactive checkbox menus for tool and scope selection.
# Compatible with Bash 3.2+ (macOS default). No namerefs used.
#
# Exports after show_scope_menu():
#   SCOPE_GLOBAL  (true|false)
#   SCOPE_PROJECT (true|false)
#
# Exports after show_tools_menu():
#   SETUP_OPENCODE    (true|false)
#   SETUP_CLAUDE      (true|false)
#   SETUP_KIRO        (true|false)
#   SETUP_COPILOT     (true|false)
#   SETUP_ANTIGRAVITY (true|false)
#   SETUP_CURSOR      (true|false)
#   SETUP_GEMINI      (true|false)

# =============================================================================
# INTERNAL HELPERS
# =============================================================================

# _erase_lines <count>
_erase_lines() {
  local n="$1" i
  for (( i=0; i<n; i++ )); do
    printf "\033[A\033[2K"
  done
}

# _draw_menu <title> <hint>
# Uses global arrays: _MENU_LABELS, _MENU_SELECTED, _MENU_DETECTED
_draw_menu() {
  local title="$1" hint="$2"
  local count="${#_MENU_LABELS[@]}" i mark det_marker

  echo -e "${BOLD}${title}${NC}"
  echo -e "${DIM}${hint}${NC}"
  echo ""

  for (( i=0; i<count; i++ )); do
    if [[ "${_MENU_SELECTED[$i]}" == "true" ]]; then
      mark="${GREEN}[x]${NC}"
    else
      mark="[ ]"
    fi
    det_marker=""
    if [[ "${_MENU_DETECTED[$i]}" == "true" ]]; then
      det_marker=" ${DIM}(detected)${NC}"
    fi
    printf "  %b ${BOLD}%d.${NC} %s%b\n" "$mark" "$((i+1))" "${_MENU_LABELS[$i]}" "$det_marker"
  done

  echo ""
  echo -e "  ${DIM}a${NC} = all   ${DIM}n${NC} = none   ${DIM}1-${count}${NC} = toggle"
}

# _run_menu <title> <hint>
# Modifies global _MENU_SELECTED in place. Bash 3.2 compatible.
_run_menu() {
  local title="$1" hint="$2"
  local count="${#_MENU_LABELS[@]}"
  # header(title+hint+blank) + items + blank + hint line = count+4
  local menu_height=$(( count + 4 ))
  local choice num idx

  _draw_menu "$title" "$hint"

  while true; do
    printf "  Toggle: "
    read -r choice

    # Erase prompt line + full menu
    _erase_lines $(( menu_height + 1 ))

    case "$choice" in
      a|A)
        for (( i=0; i<count; i++ )); do _MENU_SELECTED[$i]=true; done
        ;;
      n|N)
        for (( i=0; i<count; i++ )); do _MENU_SELECTED[$i]=false; done
        ;;
      "")
        break
        ;;
      *)
        for num in $choice; do
          if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= count )); then
            idx=$(( num - 1 ))
            if [[ "${_MENU_SELECTED[$idx]}" == "true" ]]; then
              _MENU_SELECTED[$idx]=false
            else
              _MENU_SELECTED[$idx]=true
            fi
          fi
        done
        ;;
    esac

    _draw_menu "$title" "$hint"
  done
}

# =============================================================================
# SCOPE MENU
# =============================================================================

show_scope_menu() {
  _MENU_LABELS=(
    "Global (applies to all projects)"
    "Project (current directory only)"
  )
  _MENU_SELECTED=(true true)
  _MENU_DETECTED=(false false)

  echo ""
  _run_menu \
    "Where do you want to install?" \
    "Global = tool config dirs (~/.config/opencode, ~/.claude, ~/.kiro, etc.)"

  SCOPE_GLOBAL="${_MENU_SELECTED[0]}"
  SCOPE_PROJECT="${_MENU_SELECTED[1]}"
}

# =============================================================================
# TOOLS MENU
# =============================================================================

show_tools_menu() {
  [[ -z "$OPENCODE_INSTALLED" ]] && detect_tools

  _MENU_LABELS=(
    "OpenCode           (~/.config/opencode/)"
    "Claude Code        (~/.claude/)"
    "Kiro (AWS)         (~/.kiro/)"
    "GitHub Copilot     (VS Code + ~/.config/github-copilot/)"
    "Antigravity        (~/.antigravity/ + ~/.agents/)"
    "Cursor             (~/.cursor/)"
    "Gemini CLI         (~/.gemini/)"
  )
  _MENU_DETECTED=(
    "$OPENCODE_INSTALLED"
    "$CLAUDE_INSTALLED"
    "$KIRO_INSTALLED"
    "$COPILOT_INSTALLED"
    "$ANTIGRAVITY_INSTALLED"
    "$CURSOR_INSTALLED"
    "$GEMINI_INSTALLED"
  )
  # Pre-select detected tools
  _MENU_SELECTED=(
    "$OPENCODE_INSTALLED"
    "$CLAUDE_INSTALLED"
    "$KIRO_INSTALLED"
    "$COPILOT_INSTALLED"
    "$ANTIGRAVITY_INSTALLED"
    "$CURSOR_INSTALLED"
    "$GEMINI_INSTALLED"
  )

  # If nothing detected, default to OpenCode
  local any=false
  local s
  for s in "${_MENU_SELECTED[@]}"; do [[ "$s" == "true" ]] && { any=true; break; }; done
  [[ "$any" == "false" ]] && _MENU_SELECTED[0]=true

  echo ""
  _run_menu \
    "Which AI tools do you want to configure?" \
    "Detected tools are pre-selected. Toggle to customize."

  SETUP_OPENCODE="${_MENU_SELECTED[0]}"
  SETUP_CLAUDE="${_MENU_SELECTED[1]}"
  SETUP_KIRO="${_MENU_SELECTED[2]}"
  SETUP_COPILOT="${_MENU_SELECTED[3]}"
  SETUP_ANTIGRAVITY="${_MENU_SELECTED[4]}"
  SETUP_CURSOR="${_MENU_SELECTED[5]}"
  SETUP_GEMINI="${_MENU_SELECTED[6]}"
}

# =============================================================================
# PLAN SUMMARY & CONFIRMATION
# =============================================================================

print_plan() {
  echo ""
  log_section "Installation plan:"
  echo ""

  local scope_parts=()
  [[ "$SCOPE_GLOBAL"  == "true" ]] && scope_parts+=("global")
  [[ "$SCOPE_PROJECT" == "true" ]] && scope_parts+=("project ($(basename "$(pwd)"))")
  local IFS=', '
  echo -e "  ${BOLD}Scope:${NC} ${scope_parts[*]}"
  unset IFS
  echo ""

  echo -e "  ${BOLD}Tools:${NC}"
  [[ "$SETUP_OPENCODE"    == "true" ]] && echo -e "    ${GREEN}✓${NC} OpenCode"
  [[ "$SETUP_CLAUDE"      == "true" ]] && echo -e "    ${GREEN}✓${NC} Claude Code"
  [[ "$SETUP_KIRO"        == "true" ]] && echo -e "    ${GREEN}✓${NC} Kiro (AWS)"
  [[ "$SETUP_COPILOT"     == "true" ]] && echo -e "    ${GREEN}✓${NC} GitHub Copilot"
  [[ "$SETUP_ANTIGRAVITY" == "true" ]] && echo -e "    ${GREEN}✓${NC} Antigravity"
  [[ "$SETUP_CURSOR"      == "true" ]] && echo -e "    ${GREEN}✓${NC} Cursor"
  [[ "$SETUP_GEMINI"      == "true" ]] && echo -e "    ${GREEN}✓${NC} Gemini CLI"

  echo ""
  echo -e "  ${BOLD}Bundle contents:${NC}"
  if [[ -n "$BUNDLE_DIR" && -d "$BUNDLE_DIR/skills" ]]; then
    local skill_count
    skill_count=$(find "$BUNDLE_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
    echo -e "    ${DIM}${skill_count} SDD skills (sdd-init, sdd-propose, ..., sdd-archive)${NC}"
  fi
  if [[ -n "$BUNDLE_DIR" && -d "$BUNDLE_DIR/agents" ]]; then
    local agent_count
    agent_count=$(find "$BUNDLE_DIR/agents" -name "*.json" | wc -l | tr -d ' ')
    echo -e "    ${DIM}${agent_count} agents (tech-lead, sdd-orchestrator)${NC}"
  fi
  echo ""
}

confirm_plan() {
  print_plan
  printf "  Proceed? [Y/n]: "
  local answer
  read -r answer
  case "$answer" in
    n|N) return 1 ;;
    *)   return 0 ;;
  esac
}
