# set PATH and other variables that need to be appended, and avoid duplicates when in tmux.
if [[ -z "${TMUX}" ]]; then
  if [[ $(uname) == "Darwin" ]]; then
    if [[ $(uname -m) == "arm64" ]]; then
      eval $(/opt/homebrew/bin/brew shellenv)
    else
      eval $(/usr/local/bin/brew shellenv)
    fi
    
    # ruby and ruby gems
    export PATH="${HOMEBREW_PREFIX}/opt/ruby/bin:${HOMEBREW_PREFIX}/lib/ruby/gems/3.1.0/bin:$PATH"

    # openssl
    export PATH="${HOMEBREW_PREFIX}/opt/openssl@1.1/bin:$PATH"

    # enable for gnu coreutils
    export PATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="${HOMEBREW_PREFIX}/opt/grep/libexec/gnubin:$PATH"
    export MANPATH="${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman:$MANPATH"
    export MANPATH="${HOMEBREW_PREFIX}/opt/grep/libexec/gnuman:$MANPATH"

    # groovy
    export GROOVY_HOME=${HOMEBREW_PREFIX}/opt/groovy/libexec

    # set java verson
    export JAVA_HOME=$(/usr/libexec/java_home -v17)
  else
    
  fi
  
  # local user bin
  export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

  # go lang
  export GOPATH="$HOME/go"
  export PATH="$PATH:$HOME/go/bin"

  # pyenv
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  # google-cloud-sdk
  export CLOUDSDK_PYTHON=python3
  export CLOUDSDK_GSUTIL_PYTHON=python3
  export CLOUDSDK_BQ_PYTHON=python3
fi

if [[ $(uname) == "Darwin" ]]; then
  # libraries and headers
  export CPPFLAGS="-I${HOMEBREW_PREFIX}/opt/openssl@1.1/include ${CPPFLAGS}"
  export CPPFLAGS="-I${HOMEBREW_PREFIX}/opt/readline/include ${CPPFLAGS}"
  export CPPFLAGS="-I${HOMEBREW_PREFIX}/opt/ruby/include ${CPPFLAGS}"

  export LDFLAGS="-L${HOMEBREW_PREFIX}/opt/openssl@1.1/lib ${LDFLAGS}"
  export LDFLAGS="-L${HOMEBREW_PREFIX}/opt/ruby/lib ${LDFLAGS}"

  # zsh functions
  fpath+="${HOMEBREW_PREFIX}/share/zsh/site-functions"

  # kube-ps1
  source "${HOMEBREW_PREFIX}/opt/kube-ps1/share/kube-ps1.sh"
  
  # google-cloud-sdk
  source "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
  source "${HOMEBREW_PREFIX}/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"
  complete -o nospace -C ${HOMEBREW_PREFIX}/bin/vault vault

  alias ls="${HOMEBREW_PREFIX}/bin/gls -AFhl --color=auto"
  alias flushdns='sudo dscacheutil -flushcache;sudo killall -HUP mDNSResponder'
  alias sshkill='pkill -fl "ssh(uttle -D| -|:)"'
  
  # Credentials
  export GITHUB_USER=prahaladramji
  export GITHUB_TOKEN="$(security -q find-generic-password -ws github-public)"
  export HOMEBREW_GITHUB_API_TOKEN="${GITHUB_TOKEN}"

  function ssht () {ssh -t $@ "command -v tmux >/dev/null 2>&1 && tmux new -A -s main";}
else
  # kube-ps1
  source "/usr/share/kube-ps1/kube-ps1.sh"

  # google-cloud-sdk
  source '/usr/share/google-cloud-sdk/completion.zsh.inc'

  complete -o nospace -C /usr/local/bin/vault vault
  
  alias ls='ls -AFhl --color=auto'
  alias sshkill='pkill -f "ssh(uttle -D| -|:)"'
fi
