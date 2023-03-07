autoload -Uz compinit && compinit
autoload -Uz colors && colors
autoload -Uz terminfo

setopt auto_cd
setopt auto_pushd
setopt correct
setopt ignoreeof
setopt list_packed
setopt notify

eval "$(starship init zsh)"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

export DROPBOX="$HOME/Dropbox"

export EDITOR=vim
bindkey -e
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
predict-toggle() { ((predict_on=1-predict_on)) && predict-on || predict-off }
zle -N predict-toggle
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^Z' predict-toggle

export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
chpwd() { ls -hlaFv --color=auto } # --time-style='+%Y-%m-%d %H:%M:%S'
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

() { # Languages
    eval "$(anyenv init -)"
}

() { # Completion
    echo 'TODO: Completion'
}

() { # Other PATHs
    # export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    # export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
    # export PATH="~/.local/bin:$PATH"
    # export PATH="$DROPBOX/e/code/bin:$DROPBOX/a/c/bin:$DROPBOX/a/c/bin/public:$PATH"
}

hash -d db="$DROPBOX"
source $HOME/.zshrc.local

alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias bx='bundle exec'
alias cal='cal -y'
alias cdr='git top && cd $(git top)'
alias chr=$'ruby -e \'p ARGV.map{|a| a.to_i.chr Encoding::UTF_8 }\' --'
alias cl='cd -P'
alias co='cargo compete'
alias cp='cp -i'
alias drpbi='xattr -w com.dropbox.ignored 1'
alias g='git'
alias g++='g++ -std=c++20 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -O2'
alias g++d='g++ -std=c++20 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -DEBUG -DDEBUG'
alias ls=$'ls -hlaFv --color=auto --time-style=\'+%Y-%m-%d %H:%M:%S\''
function md() { mkdir -p "$@" && eval cd "\"\$$#\"" }
alias mv='mv -i'
alias pn='pnpm'
alias pna='pnpm add'
alias pnd='pnpm add -D'
alias pnr='pnpm run'
alias pnrb='pnpm run build'
alias pnrd='pnpm run dev'
alias pnrl='pnpm run lint'
alias pnrt='pnpm run test'
alias pnrs='pnpm run start'
alias poff='predict-off'
alias pon='predict-on'
alias rm='rm -i'
alias u+x='chmod u+x'
alias wh='command -v'
alias zshrc='code `readlink ~/.zshrc`'
