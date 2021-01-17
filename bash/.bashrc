#
# ~/.bashrc
#

export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export HISTTIMEFORMAT="%d/%m/%y %T "

# brew
export PATH="$HOME/bin:/usr/local/sbin:$PATH"

# language settings
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ruby and ruby gems
export PATH="/usr/local/opt/ruby/bin:/usr/local/lib/ruby/gems/3.0.0/bin:$PATH"

# go lang
export GOPATH="$HOME/golib:$HOME/git/go"
export PATH="$PATH:$HOME/golib/bin:$HOME/git/go/bin"

# python 3.8
export PATH="/usr/local/opt/python@3.8/bin:$PATH"

# openssl
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"

# enable for gnu coreutils
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

alias bashconfig="subl ~/.bashrc"

# for nvim
export EDITOR='nvim'
alias vi='nvim'
alias vim='nvim'

alias ls='ls -AFhl --color=auto'
alias flushdns='sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder'
alias pr='cd $(git rev-parse --show-toplevel)'
alias sshkill='pkill -fl "ssh(uttle|:| -)"'

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

eval "$(direnv hook bash)"
eval "$(pipenv --completion)"

# google-cloud-sdk
export CLOUDSDK_PYTHON=python3
export CLOUDSDK_GSUTIL_PYTHON=python3
export CLOUDSDK_BQ_PYTHON=python3
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc'
source '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc'

complete -C /usr/local/bin/vault vault
