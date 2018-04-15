# hedgehog1029's theme

# Color shortcuts
R=$fg_no_bold[red]
B=$fg_no_bold[blue]
Y=$fg[yellow]
M=$fg_no_bold[magenta]
RESET=$reset_color

local return_side="%(?..%{$R%}%?   %{$RESET%})"

function gitStatusF() {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    user=$(git remote -v | grep "fetch" | cut -d'/' -f 4) || return
    repo=$(git remote -v | grep "fetch" | cut -d'/' -f 5 | cut -d'.' -f 1) || return
    echo "($(git_prompt_info)%{$RESET%})"
    # echo "(%B${ref#refs/heads/}@${user}/${repo}%b%{$RESET%}) "
}

# Prompt
# PROMPT='%B%~%b $(gitStatusF)%{$M%}$ %{$RESET%}'
PROMPT='%B%{$Y%}%~%b%{$RESET%} $(git_prompt_info)%{$M%}$ %{$RESET%}'
RPS1="${return_side}"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$R%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
