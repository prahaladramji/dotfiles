#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export HISTTIMEFORMAT="%d/%m/%y %T "

# go lang
export GOPATH=$HOME/go
export PATH="$HOME/bin:$HOME/go/bin:$PATH"

# ssh-agent
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval "$(<~/.ssh-agent-thing)"
fi

ssh-add -K ~/.ssh/id_rsa &>/dev/null
ssh-add -K ~/.ssh/google_compute_engine &>/dev/null

#for nvim
export EDITOR="nvim"
alias vi='nvim'
alias vim='nvim'

alias bashconfig="subl ~/.bashrc"
alias ls='ls -AFhl --color=auto'
alias pr='cd $(git rev-parse --show-toplevel)'

eval "$(direnv hook bash)"
eval "$(pipenv --completion)"

# google-cloud-sdk
source '/usr/lib64/google-cloud-sdk/completion.bash.inc'

complete -cf sudo
complete -o nospace -C /usr/local/bin/vault vault