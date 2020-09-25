autoload -Uz compinit; compinit
autoload -Uz colors; colors

export LANG=ja_JP.UTF-8

NEWLINE=$'\n'
PROMPT="%B%F{ 39 }%n %F{ 136 }%? %F{ 23 }%~${NEWLINE}%F{ 33 }$%b%f "
RPROMPT="| %B%F{ 27 }%D{%H:%M:%S}%b%f"
PROMPT2="%_$ "
SPROMPT="%r is correct? [n,y,a,e]: "

alias ls='ls -hlaG'
alias zshrc='source ~/.zshrc'
