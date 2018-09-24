#
# ~/.bashrc
#

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export HISTTIMEFORMAT="%d/%m/%y %T "

# go lang
export GOPATH=$HOME/go
export PATH="$HOME/go/bin:$PATH"

# enable for gnu coreutils
# export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# google-cloud-sdk
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

# for nvim
export EDITOR='nvim'
alias vi='nvim'
alias vim='nvim'

alias ls='ls -GFhla'
alias flushdns='sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder'

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# Virtualenv python
export WORKON_HOME=$HOME/git/.virtualenvs
export PROJECT_HOME=$HOME/git
source /usr/local/bin/virtualenvwrapper.sh

# direnv
eval "$(direnv hook bash)"

# nvm for node
export NVM_DIR="$HOME/.nvm"
source /usr/local/opt/nvm/nvm.sh
