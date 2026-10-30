# Helper function to manage both common and work overlay dotfiles via chezmoi
dots() {
  local cmd="${1:-status}"
  local common_dir="$HOME/.local/share/chezmoi"
  local work_dir="$HOME/.local/share/dotfiles-work"
  local work_state="$HOME/.config/chezmoi/chezmoistate-work.boltdb"

  case "$cmd" in
    sync|up|update)
      echo "==> Updating common dotfiles ($common_dir)..."
      chezmoi update
      if [[ -d "$work_dir/.git" ]]; then
        echo "==> Updating work overlay ($work_dir)..."
        git -C "$work_dir" pull --rebase
        chezmoi -S "$work_dir" --persistent-state "$work_state" apply
      fi
      ;;
    apply)
      chezmoi apply
      if [[ -d "$work_dir" ]]; then
        chezmoi -S "$work_dir" --persistent-state "$work_state" apply
      fi
      ;;
    upgrade)
      echo "==> Refreshing external archives (oh-my-zsh, zsh plugins, nvm)..."
      chezmoi apply --refresh-externals
      ;;
    status|st)
      echo "==> Common repo ($common_dir):"
      git -C "$common_dir" status -sb
      chezmoi status
      if [[ -d "$work_dir/.git" ]]; then
        echo ""
        echo "==> Work overlay ($work_dir):"
        git -C "$work_dir" status -sb
        chezmoi -S "$work_dir" --persistent-state "$work_state" status
      fi
      ;;
    diff)
      echo "==> Common dotfiles diff:"
      chezmoi diff
      if [[ -d "$work_dir" ]]; then
        echo ""
        echo "==> Work overlay diff:"
        chezmoi -S "$work_dir" --persistent-state "$work_state" diff
      fi
      ;;
    work)
      if [[ ! -d "$work_dir" ]]; then
        echo "Work overlay not found at $work_dir" >&2
        return 1
      fi
      chezmoi -S "$work_dir" --persistent-state "$work_state" "${@:2}"
      ;;
    cd)
      if [[ "${2:-}" == "work" ]]; then
        if [[ -d "$work_dir" ]]; then
          cd "$work_dir" || return 1
        else
          echo "Work overlay not found at $work_dir" >&2
          return 1
        fi
      else
        cd "$common_dir" || return 1
      fi
      ;;
    *)
      echo "Usage: dots [sync|apply|upgrade|status|diff|work <chezmoi-args>|cd [work]]"
      return 1
      ;;
  esac
}
