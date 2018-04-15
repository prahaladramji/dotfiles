#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -Fhla --color=auto'
PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export HISTTIMEFORMAT="%d/%m/%y %T "

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
    eval "$(<~/.ssh-agent-thing)"
fi

export GOPATH="$HOME/go"
export PATH="$PATH:$HOME/bin:$GOPATH/bin"
export EDITOR="nvim"

complete -cf sudo
