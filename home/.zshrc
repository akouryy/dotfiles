autoload -Uz compinit; compinit
autoload -Uz colors; colors
autoload -Uz add-zsh-hook
autoload -Uz terminfo
autoload predict-on; predict-on

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
    vivis|vivli) MODE_PROMPT='@' ;;
  esac
  zle reset-prompt
}
NEWLINE=$'\n'
setopt PROMPT_SUBST
PROMPT='%B%F{ 39 }%n@$(hostname) %F{ 136 }%? %F{ 23 }%~$NEWLINE%F{ 33 }$MODE_PROMPT%b%f '
RPROMPT='| %B%F{ 27 }%D{%H:%M:%S}%b%f'
PROMPT2='%_$ '
SPROMPT='もしかして %r [yNae]: '
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select
zle -N edit-command-line

HISTFILE=${HOME}/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

export EDITOR=vim
bindkey -v
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
bindkey '^K' kill-line
bindkey '^W' backward-kill-word

export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
zstyle ':completion:*:ssh:*' hosts off
setopt noautoremoveslash

export DROPBOX="$HOME/Dropbox"
hash -d db="$DROPBOX"
hash -d e="$DROPBOX/e"

alias ls='ls -hlaG'
alias poff='predict-off'
alias pon='predict-on'
alias wh='command -v' # alias wh='which -a'
alias zshrc='source ~/.zshrc'
