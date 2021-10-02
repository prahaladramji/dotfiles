# set PATH and other variables that need to be appended, and avoid duplicates when in tmux.
if [[ -z "${TMUX}" ]]; then
  # If you come from bash you might have to change your $PATH.
  export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

  # go lang
  export GOPATH="$HOME/go"
  export PATH="$PATH:$HOME/go/bin"

  # pyenv
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"

  # google-cloud-sdk
  export CLOUDSDK_PYTHON=python3
  export CLOUDSDK_GSUTIL_PYTHON=python3
  export CLOUDSDK_BQ_PYTHON=python3
  source '/usr/share/google-cloud-sdk/completion.zsh.inc'
fi

# nvm
export NVM_LAZY_LOAD=true

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="maia"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"
setopt SHARE_HISTORY

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  direnv
  git
  history
  history-substring-search
  kubectl
  pyenv
  timer
  zsh-autosuggestions
  zsh-nvm
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# auto suggest configs
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Timer configs
TIMER_FORMAT='[%d]'
TIMER_PRECISION=2

# User configuration
# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="vi ~/.zshrc"
alias tmuxconfig="vi ~/.tmux.conf"

# for nvim
export EDITOR='nvim'
alias vi='nvim'
alias vim='nvim'

alias ls='ls -AFhl --color=auto'
alias pr='cd $(git rev-parse --show-toplevel)'
alias sshkill='pkill -f "ssh(uttle -D| -)"'

autoload -U +X bashcompinit && bashcompinit

complete -o nospace -C /usr/local/bin/vault vault

# tmux session wrangling
function tmux_group_session() {
  GRPSC_GID=${1:=grpsc}
  GRPSC_CID=${GRPSC_GID}-$(date +'%H%M%S')
  if ! tmux has-session -t main &>/dev/null; then
    tmux new-session -d -s main
  fi
  tmux new-session -A -t main -s ${GRPSC_CID} \; set-option destroy-unattached
}

if ! [[ -n "${TMUX}" || "${TERM}" =~ "tmux.*" || "${TERM}" =~ "screen.*" || "${TERMINAL_EMULATOR}" =~ "JetBrains.*" ]]; then
  # we are (probably) not in a tmux session or in intellij
  tmux_group_session
  sleep 0.5
  exit
fi
