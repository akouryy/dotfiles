autoload -Uz compinit; compinit
autoload -Uz colors; colors
autoload -Uz add-zsh-hook
autoload -Uz terminfo

export LANG=ja_JP.UTF-8
setopt auto_cd
setopt auto_pushd
setopt correct

left_down_prompt_preexec() {
    print -rn -- $terminfo[el]
}
add-zsh-hook preexec left_down_prompt_preexec
function zle-keymap-select zle-line-init zle-line-finish
{
  case $KEYMAP in
    main|viins)  MODE_PROMPT='$' ;;
    vicmd)       MODE_PROMPT='-' ;;
    vivis|vivli) MODE_PROMPT="@" ;;
  esac
  zle reset-prompt
}
NEWLINE=$'\n'
setopt PROMPT_SUBST
PROMPT='%B%F{ 39 }%n@$(hostname) %F{ 136 }%? %F{ 23 }%~$NEWLINE%F{ 33 }$MODE_PROMPT%b%f '
RPROMPT="| %B%F{ 27 }%D{%H:%M:%S}%b%f"
PROMPT2="%_$ "
SPROMPT="もしかして %r [yNae]: "
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
zle -N edit-command-line

HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_all_dups
setopt share_history

export EDITOR=vim
bindkey -v
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

alias ls='ls -hlaG'
alias zshrc='source ~/.zshrc'
