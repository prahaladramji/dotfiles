# tmux session wrangling
function tmux_group_session() {
  GRPSC_GID=${1:=main}
  GRPSC_CID=${GRPSC_GID}-$(date +'%H%M%S')
  if ! tmux has-session -t ${GRPSC_GID} &>/dev/null; then
    tmux new-session -d -s ${GRPSC_GID}
  fi
  tmux new-session -d -t ${GRPSC_GID} -s ${GRPSC_CID} \; set-option destroy-unattached \; attach-session -t ${GRPSC_CID}
}


# Disabled tmux until fixing the $TERM to support 256 colors
if [[ $- == *i* ]] && ! [[ -n "${TMUX}" || "${TERM_PROGRAM}" == "vscode" || "${TERMINAL_EMULATOR}" == "JetBrains.*" ]]; then
  # we are (probably) not in a tmux session or in an IDE
  tmux_group_session
  sleep 0.5
  exit
fi

