#
# ~/.bashrc
#

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export HISTTIMEFORMAT="%d/%m/%y %T "

# brew
export PATH="$HOME/bin:/usr/local/bin:$PATH:/opt/X11/bin"

# ruby and ruby gems
export PATH="/usr/local/opt/ruby/bin:/usr/local/lib/ruby/gems/2.6.0/bin:$PATH"

# go lang
export GOPATH=$HOME/go
export PATH="$HOME/go/bin:$PATH"

# enable for gnu coreutils
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

# ssh
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
	ssh-agent > ~/.ssh-agent-thing
fi
if [[ "$SSH_AGENT_PID" == "" ]]; then
	eval "$(<~/.ssh-agent-thing)"
fi

ssh-add -K ~/.ssh/id_rsa &>/dev/null
ssh-add -K ~/.ssh/google_compute_engine &>/dev/null

alias bashconfig="subl ~/.bashrc"
# for nvim
export EDITOR='nvim'
alias vi='nvim'
alias vim='nvim'

alias ls='ls -AFhl'
alias flushdns='sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder'
alias pr='cd $(git rev-parse --show-toplevel)'
alias sshkill='pkill -fl "ssh(uttle|:| -)"'

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

eval "$(direnv hook bash)"
eval "$(pipenv --completion)"

# google-cloud-sdk
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

complete -C /usr/local/bin/vault vault
