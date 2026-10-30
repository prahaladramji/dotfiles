# Terminals ($TERM_PROGRAM / $TERMINAL_EMULATOR / $TERM) or environment
# variables that should skip tmux auto-start:
TMUX_SKIP=(
  dumb
  JetBrains-JediTerm
  NVIM
  TMUX
  vscode
  VSCODE_IPC_HOOK_CLI
  zed
)

function tmux_group_session() {
  local grpsc_gid="${1:-main}"
  local grpsc_cid="${grpsc_gid}-$(date +'%H%M%S')"
  if ! tmux has-session -t "${grpsc_gid}" &>/dev/null; then
    tmux new-session -d -s "${grpsc_gid}"
  fi
  tmux new-session -d -t "${grpsc_gid}" -s "${grpsc_cid}" \; set-option destroy-unattached \; attach-session -t "${grpsc_cid}"
}

function _should_autostart_tmux() {
  [[ $- == *i* ]] || return 1
  local item
  for item in "${TMUX_SKIP[@]}"; do
    if [[ "${TERM_PROGRAM:-}" == "$item" || "${TERMINAL_EMULATOR:-}" == "$item" || "${TERM:-}" == "$item" || -n "${(P)item:-}" ]]; then
      return 1
    fi
  done
  return 0
}

if _should_autostart_tmux; then
  tmux_group_session
  exit
fi
