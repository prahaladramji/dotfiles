# Terminals ($TERM_PROGRAM / $TERMINAL_EMULATOR / $TERM) or environment
# variables (exact or prefix match, e.g. vscode -> VSCODE_*) that should
# skip tmux auto-start:
TMUX_SKIP=(
  dumb
  JetBrains-JediTerm
  NVIM
  TMUX
  vscode
  zed
)

function tmux_group_session() {
  local grpsc_gid="${1:-main}"
  local grpsc_cid="${grpsc_gid}-$(date +'%H%M%S')"
  if ! tmux has-session -t "${grpsc_gid}" &>/dev/null; then
    tmux new-session -d -s "${grpsc_gid}"
  fi
  tmux new-session -t "${grpsc_gid}" -s "${grpsc_cid}" \; set-option destroy-unattached
}

function _should_autostart_tmux() {
  [[ -o interactive && -z "${ZSH_EXECUTION_STRING:-}" && $- != *c* && -t 0 && -t 1 ]] || return 1
  command -v tmux &>/dev/null || return 1
  zmodload -F zsh/parameter p:parameters 2>/dev/null
  local item var
  for item in "${TMUX_SKIP[@]}"; do
    if [[ "${TERM_PROGRAM:-}" == "$item" || "${TERMINAL_EMULATOR:-}" == "$item" || "${TERM:-}" == "$item" ]]; then
      return 1
    fi
    for var in ${(k)parameters[(I)(${item:u}|${item:u}_*)]}; do
      if [[ "${parameters[$var]}" == *export* && -n "${(P)var:-}" ]]; then
        return 1
      fi
    done
  done
  return 0
}

if _should_autostart_tmux; then
  tmux_group_session && exit
fi
