#!/usr/bin/env bash
# install.sh — Seily: AI Environment Setup
#
# Installs the SDD agent bundle (skills + agents) and Seily Memory (sailymem)
# for multiple AI coding tools.
#
# Supported tools:
#   OpenCode, Claude Code, Kiro (AWS), GitHub Copilot, Antigravity
#
# Usage:
#   ./install.sh                    # Interactive mode
#   ./install.sh --all              # All detected tools, global + project
#   ./install.sh --global           # Only global level
#   ./install.sh --project          # Only project level (current directory)
#   ./install.sh --opencode --claude # Specific tools
#   ./install.sh --dry-run          # Preview without making changes
#   ./install.sh --uninstall        # Remove installed files
#
# One-liner install:
#   curl -fsSL https://raw.githubusercontent.com/diegoRambao/ai-env-setup/main/install.sh | bash

set -euo pipefail

VERSION="1.0.0"
REPO_URL="https://github.com/diegoRambao/ai-env-setup"

# =============================================================================
# BOOTSTRAP: Resolve script dir (works when piped from curl too)
# =============================================================================

_bootstrap() {
  # When piped from curl, $BASH_SOURCE[0] is empty or "/dev/stdin".
  # In that case, we clone the repo to a temp dir.
  local script_path="${BASH_SOURCE[0]:-}"

  if [[ -z "$script_path" || "$script_path" == "/dev/stdin" || "$script_path" == "bash" ]]; then
    _install_from_remote
    exit 0
  fi

  SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"
  BUNDLE_DIR="$SCRIPT_DIR/bundle"
  LIB_DIR="$SCRIPT_DIR/lib"
  ADAPTERS_DIR="$SCRIPT_DIR/adapters"
}

_install_from_remote() {
  echo ""
  echo "Downloading ai-env-setup from GitHub..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  # NOTE: No trap here — we exec into the downloaded script, which becomes
  # this process. A cleanup trap on EXIT would fire before exec finishes.
  # The OS reclaims the temp dir on process exit naturally.

  # Resolve the latest commit SHA via GitHub API to bypass CDN cache on
  # raw.githubusercontent.com and /archive/refs/heads/main.tar.gz.
  # The per-commit tarball URL is never cached.
  local sha=""
  if command -v curl &>/dev/null; then
    sha=$(curl -fsSL "https://api.github.com/repos/diegoRambao/ai-env-setup/commits/main" \
      2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin)['sha'][:7])" 2>/dev/null || true)
  fi

  # Prefer curl tarball (works without auth on public repos).
  # Fall back to git clone only if curl is unavailable.
  if command -v curl &>/dev/null; then
    local tarball_url
    if [[ -n "$sha" ]]; then
      tarball_url="$REPO_URL/archive/${sha}.tar.gz"
    else
      tarball_url="$REPO_URL/archive/refs/heads/main.tar.gz"
    fi
    curl -fsSL "$tarball_url" | tar xz -C "$tmp_dir"
    # GitHub names the extracted dir as "<repo>-<sha_or_branch>"
    local extracted
    extracted=$(ls "$tmp_dir" | head -1)
    mv "$tmp_dir/$extracted" "$tmp_dir/ai-env-setup"
  elif command -v git &>/dev/null; then
    git clone --depth=1 --quiet "$REPO_URL.git" "$tmp_dir/ai-env-setup"
  else
    echo "Error: curl or git is required to download ai-env-setup."
    exit 1
  fi

  # exec replaces the current process — the temp dir stays alive until
  # the new process exits, then the OS reclaims it.
  # Re-attach stdin to the terminal if it's piped (e.g. via curl), to allow interactive prompts.
  if [[ ! -t 0 && -c /dev/tty ]]; then
    exec bash "$tmp_dir/ai-env-setup/install.sh" "$@" < /dev/tty
  else
    exec bash "$tmp_dir/ai-env-setup/install.sh" "$@"
  fi
}

_bootstrap

# =============================================================================
# SOURCE LIBRARIES
# =============================================================================

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/menu.sh
source "$LIB_DIR/menu.sh"
# shellcheck source=lib/transform.sh
source "$LIB_DIR/transform.sh"

# Source all adapters
for _adapter in "$ADAPTERS_DIR"/*.sh; do
  # shellcheck source=/dev/null
  source "$_adapter"
done

# =============================================================================
# DEFAULTS
# =============================================================================

SCOPE_GLOBAL=false
SCOPE_PROJECT=false

SETUP_OPENCODE=false
SETUP_CLAUDE=false
SETUP_KIRO=false
SETUP_COPILOT=false
SETUP_ANTIGRAVITY=false

FLAG_ALL=false
FLAG_INTERACTIVE=true
FLAG_UNINSTALL=false

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

_parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        FLAG_ALL=true
        FLAG_INTERACTIVE=false
        shift ;;
      --global)
        SCOPE_GLOBAL=true
        FLAG_INTERACTIVE=false
        shift ;;
      --project)
        SCOPE_PROJECT=true
        FLAG_INTERACTIVE=false
        shift ;;
      --opencode)
        SETUP_OPENCODE=true
        FLAG_INTERACTIVE=false
        shift ;;
      --claude)
        SETUP_CLAUDE=true
        FLAG_INTERACTIVE=false
        shift ;;
      --kiro)
        SETUP_KIRO=true
        FLAG_INTERACTIVE=false
        shift ;;
      --copilot)
        SETUP_COPILOT=true
        FLAG_INTERACTIVE=false
        shift ;;
      --antigravity)
        SETUP_ANTIGRAVITY=true
        FLAG_INTERACTIVE=false
        shift ;;
      --dry-run)
        DRY_RUN=true
        shift ;;
      --uninstall)
        FLAG_UNINSTALL=true
        FLAG_INTERACTIVE=false
        shift ;;
      --version|-v)
        echo "ai-env-setup $VERSION"
        exit 0 ;;
      --help|-h)
        _show_help
        exit 0 ;;
      *)
        log_error "Unknown option: $1"
        echo "Run with --help for usage."
        exit 1 ;;
    esac
  done

  # --all: enable everything
  if [[ "$FLAG_ALL" == "true" ]]; then
    SCOPE_GLOBAL=true
    SCOPE_PROJECT=true
    SETUP_OPENCODE=true
    SETUP_CLAUDE=true
    SETUP_KIRO=true
    SETUP_COPILOT=true
    SETUP_ANTIGRAVITY=true
  fi

  # Default scope when tool flags given but no scope flags
  if [[ "$FLAG_INTERACTIVE" == "false" && "$SCOPE_GLOBAL" == "false" && "$SCOPE_PROJECT" == "false" ]]; then
    SCOPE_GLOBAL=true
    SCOPE_PROJECT=true
  fi
}

_show_help() {
  cat <<HELP

  ai-env-setup v${VERSION}
  Install the SDD agent bundle for your AI coding tools.

  USAGE
    ./install.sh [OPTIONS]

  SCOPE FLAGS
    --global        Configure global tool directories (~/.config/opencode, ~/.claude, etc.)
    --project       Configure current project directory (.opencode/, .claude/, etc.)
                    (default: both global and project when tool flags are used)

  TOOL FLAGS
    --opencode      Configure OpenCode
    --claude        Configure Claude Code
    --kiro          Configure Kiro (AWS)
    --copilot       Configure GitHub Copilot (VS Code)
    --antigravity   Configure Antigravity
    --all           Configure all detected tools at all scopes

  OTHER FLAGS
    --dry-run       Preview what would be installed without making changes
    --uninstall     Remove installed files (coming soon)
    --version       Print version
    --help          Show this help message

  EXAMPLES
    ./install.sh                      # Interactive mode (recommended)
    ./install.sh --all                # Everything
    ./install.sh --global --opencode --claude
    ./install.sh --project --antigravity
    ./install.sh --dry-run --all      # Preview

  ONE-LINER
    curl -fsSL ${REPO_URL}/raw/main/install.sh | bash

HELP
}

# =============================================================================
# INTERACTIVE MODE
# =============================================================================

_run_interactive() {
  # Detect installed tools first
  detect_tools

  # Show header
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║       AI Environment Setup v${VERSION}        ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${DIM}Installs SDD skills + agents for your AI coding tools.${NC}"
  echo -e "  ${DIM}Bundle: 9 SDD skills (sdd-init … sdd-archive) + 2 agents${NC}"
  echo ""

  # Print detected tools
  print_detection

  # Show scope menu
  show_scope_menu

  # Show tools menu
  show_tools_menu

  # Confirm
  confirm_plan || { echo ""; log_warn "Aborted."; exit 0; }
}

# =============================================================================
# VALIDATION
# =============================================================================

_validate() {
  local any_tool=false
  for flag in SETUP_OPENCODE SETUP_CLAUDE SETUP_KIRO SETUP_COPILOT SETUP_ANTIGRAVITY; do
    [[ "${!flag}" == "true" ]] && { any_tool=true; break; }
  done

  if [[ "$any_tool" == "false" ]]; then
    log_warn "No tools selected. Nothing to do."
    echo "  Run with --help for usage, or without arguments for interactive mode."
    exit 0
  fi

  local any_scope=false
  [[ "$SCOPE_GLOBAL" == "true" || "$SCOPE_PROJECT" == "true" ]] && any_scope=true

  if [[ "$any_scope" == "false" ]]; then
    log_warn "No scope selected. Nothing to do."
    exit 0
  fi

  # Validate bundle dir
  if [[ ! -d "$BUNDLE_DIR/skills" ]]; then
    log_error "Bundle not found at $BUNDLE_DIR/skills"
    log_error "The repository may be incomplete. Please re-clone from $REPO_URL"
    exit 1
  fi
}

# =============================================================================
# UNINSTALL
# =============================================================================

_uninstall() {
  log_section "Uninstall"
  log_warn "Uninstall support is planned for v1.1."
  log_warn "For now, manually remove:"
  echo ""
  echo "  Global:"
  echo "    rm -rf ~/.config/opencode/skills/sdd-*"
  echo "    rm -rf ~/.claude/skills/sdd-*  ~/.claude/CLAUDE.md"
  echo "    rm -rf ~/.kiro/skills/sdd-*    ~/.kiro/agents/sdd-orchestrator.json ~/.kiro/agents/tech-lead.json"
  echo "    rm -rf ~/.gemini/antigravity/skills/sdd-*"
  echo ""
  echo "  Memory CLI:"
  echo "    rm -f /usr/local/bin/sailymem"
  echo "    rm -rf ~/Library/Application\\ Support/seily/  # macOS"
  echo "    rm -rf ~/.config/seily/                        # Linux"
  echo ""
  echo "  Project:"
  echo "    rm -rf .opencode/skills .claude/skills .kiro/skills .github/skills .agents/skills"
  echo "    rm -f CLAUDE.md .github/copilot-instructions.md .kiro/kiro-instructions.md"
  echo ""
}

# =============================================================================
# RUN ADAPTERS
# =============================================================================

_run_adapters() {
  local step=1
  local total=0

  # Count selected tools
  for flag in SETUP_OPENCODE SETUP_CLAUDE SETUP_KIRO SETUP_COPILOT SETUP_ANTIGRAVITY; do
    [[ "${!flag}" == "true" ]] && total=$(( total + 1 ))
  done

  echo ""
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}${BOLD}DRY RUN — no files will be created or modified.${NC}"
    echo ""
  fi

  [[ "$SETUP_OPENCODE"    == "true" ]] && { log_step $step $total "OpenCode";       setup_opencode;    echo ""; step=$(( step+1 )); }
  [[ "$SETUP_CLAUDE"      == "true" ]] && { log_step $step $total "Claude Code";    setup_claude;      echo ""; step=$(( step+1 )); }
  [[ "$SETUP_KIRO"        == "true" ]] && { log_step $step $total "Kiro (AWS)";     setup_kiro;        echo ""; step=$(( step+1 )); }
  [[ "$SETUP_COPILOT"     == "true" ]] && { log_step $step $total "GitHub Copilot"; setup_copilot;     echo ""; step=$(( step+1 )); }
  [[ "$SETUP_ANTIGRAVITY" == "true" ]] && { log_step $step $total "Antigravity";    setup_antigravity; echo ""; step=$(( step+1 )); }
}

# =============================================================================
# SUMMARY
# =============================================================================

_print_summary() {
  local skill_count
  skill_count=$(find "$BUNDLE_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')

  echo ""
  echo -e "${GREEN}${BOLD}Setup complete!${NC}"
  echo ""
  echo -e "  Installed ${BOLD}${skill_count} SDD skills${NC} and ${BOLD}2 agents${NC} for:"
  [[ "$SETUP_OPENCODE"    == "true" ]] && echo -e "    ${GREEN}✓${NC} OpenCode"
  [[ "$SETUP_CLAUDE"      == "true" ]] && echo -e "    ${GREEN}✓${NC} Claude Code"
  [[ "$SETUP_KIRO"        == "true" ]] && echo -e "    ${GREEN}✓${NC} Kiro (AWS)"
  [[ "$SETUP_COPILOT"     == "true" ]] && echo -e "    ${GREEN}✓${NC} GitHub Copilot"
  [[ "$SETUP_ANTIGRAVITY" == "true" ]] && echo -e "    ${GREEN}✓${NC} Antigravity"
  command -v sailymem &>/dev/null && echo -e "    ${GREEN}✓${NC} Seily Memory (sailymem)"
  echo ""
  echo -e "  ${DIM}Restart your AI tools to load the new configuration.${NC}"
  echo -e "  ${DIM}Run with --dry-run to preview changes before applying.${NC}"
  echo ""
}

# =============================================================================
# SAILYMEM: Build & install the `sailymem` binary
# =============================================================================

_install_sailymem() {
  log_section "Seily Memory (sailymem)"

  # Check if already installed and up to date
  if command -v sailymem &>/dev/null; then
    log_ok "sailymem already installed at $(command -v sailymem)"
    return 0
  fi

  # Require Rust toolchain
  if ! command -v cargo &>/dev/null; then
    if [[ -f "$HOME/.cargo/env" ]]; then
      source "$HOME/.cargo/env"
    fi
    if ! command -v cargo &>/dev/null; then
      log_warn "Rust not found. Installing via rustup..."
      if [[ "$DRY_RUN" == "true" ]]; then
        log_dim "[dry-run] Would install Rust via rustup"
      else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
        source "$HOME/.cargo/env"
      fi
    fi
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    log_dim "[dry-run] Would build sailymem and install to /usr/local/bin/sailymem"
    return 0
  fi

  local mem_src="$SCRIPT_DIR/memory-cli"
  if [[ ! -f "$mem_src/Cargo.toml" ]]; then
    log_error "sailymem source not found at $mem_src"
    return 1
  fi

  log_info "Building sailymem (release)... this may take a minute on first run"
  if cargo build --release --manifest-path "$mem_src/Cargo.toml"; then
    local bin_path="$mem_src/target/release/sailymem"
    local install_dir="/usr/local/bin"

    if [[ -w "$install_dir" ]]; then
      cp "$bin_path" "$install_dir/sailymem"
    else
      log_info "Requires sudo to install to $install_dir"
      sudo cp "$bin_path" "$install_dir/sailymem"
    fi
    chmod +x "$install_dir/sailymem"
    log_ok "sailymem installed to $install_dir/sailymem"
  else
    log_error "Failed to build sailymem. Skipping."
    log_dim "You can build manually: cd $mem_src && cargo build --release"
    return 1
  fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
  _parse_args "$@"

  if [[ "$FLAG_UNINSTALL" == "true" ]]; then
    _uninstall
    exit 0
  fi

  if [[ "$FLAG_INTERACTIVE" == "true" ]]; then
    _run_interactive
  fi

  _validate
  resolve_bundle_dir

  _install_sailymem
  _run_adapters
  _print_summary
}

main "$@"
