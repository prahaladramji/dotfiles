# enable substitution for prompt
setopt prompt_subst

local git_branch='$(git_prompt_info)%{$reset_color%}'

# Maia prompt
PROMPT="%B%{$fg[cyan]%}%(4~|%-1~/.../%3~|%~)%u%b ${git_branch}>%{$fg[cyan]%}>%B%(?.%{$fg[cyan]%}.%{$fg[red]%})>%{$reset_color%}%b "
RPROMPT="%{$fg[red]%} %(?..[%?])" 

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
