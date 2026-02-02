autoload -Uz compinit && compinit
autoload -Uz colors && colors
# autoload -Uz predict-on; predict-on
autoload -Uz terminfo

setopt auto_cd
setopt auto_pushd
setopt correct
setopt extendedglob
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
export WORDCHARS="_"
bindkey -e
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
predict-toggle() { ((predict_on=1-predict_on)) && predict-on || predict-off }
zle -N predict-toggle
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
bindkey '^Q' kill-word
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^Z' predict-toggle

zstyle ':completion:*' ignored-patterns 'sndfile-*'
zstyle ':completion:*' matcher-list \
  '' \
  '+m:{a-z}={A-Z}' \
  '+r:|[._-]=*' \
  '+m:{A-Z}={a-z}'

export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
chpwd() { ls -hlaFv --color } # =auto --time-style='+%Y-%m-%d %H:%M:%S'
export TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

() { # Languages
    eval "$(anyenv init -)"
}

() { # Other PATHs
  export PATH="$DROPBOX/e/code/bin:$DROPBOX/a/c/bin:$DROPBOX/a/c/bin/public:$PATH"

  zshrc_path=$(readlink $HOME/.zshrc || echo $HOME/.zshrc)
  export PATH="${zshrc_path:a:h}/../bin:$PATH"

  export LIBRARY_PATH="$LIBRARY_PATH:$(brew --prefix zstd)/lib/"
}

hash -d db="$DROPBOX"
hash -d dl="$HOME/Downloads"
source $HOME/.zshrc.local

alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias .zshrc='source ~/.zshrc'
alias aa='g aa'
alias ag='ag --hidden'
alias bd='g bd'
alias bv='g bv'
alias bx='bundle exec'
alias bxc='bundle exec rubocop'
alias bxr='bundle exec rails'
alias c='code .'
alias cal='cal -y'
alias cb='g cb'
alias cdr='git top && cd $(git top)'
alias ch='g ch'
alias cl='cd -P'
alias cm='g cm'
alias co='cargo compete'
alias cp='cp -i'
alias drpbi='xattr -w com.dropbox.ignored 1'
alias fp='g fp --all && g pl'
alias g='git'
alias gp='g p'
alias g++='g++ -std=c++20 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -O2'
alias g++d='g++ -std=c++20 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -DEBUG -DDEBUG'
alias ls=$'ls -hlaFv --color' # =auto --time-style=\'+%Y-%m-%d %H:%M:%S\''
alias mas='g mas'
function md() { mkdir -p "$@" && eval cd "\"\$$#\"" }
alias mm='g mm'
alias mv='mv -i'
alias pl='g pl'
alias pn='pnpm'
alias pna='pnpm add'
alias pnd='pnpm add -D'
alias pni='pnpm i'
alias pnr='pnpm run'
alias pnrb='pnpm run build'
alias pnrd='pnpm run dev'
alias pnrl='pnpm run lint'
alias pnrt='pnpm run test'
alias pnrs='pnpm run start'
alias poff='predict-off'
alias pon='predict-on'
alias rm='rm -i'
alias tf='terraform -chdir=terraform'
alias tfa='tf apply plan~'
alias tfp='tf plan -out plan~'
alias s='stree .'
alias u+x='chmod u+x'
alias wh='command -v'
alias x='chmod u+x'
alias zshrc='code `readlink ~/.zshrc`/../..'

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

zinit light Tarrasch/zsh-autoenv
zinit ice atload'FAST_HIGHLIGHT[chroma-ruby]='
zinit light zdharma-continuum/fast-syntax-highlighting

zinit light zsh-users/zsh-completions

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/.anyenv/envs/pyenv/versions/anaconda3-2022.10/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/.anyenv/envs/pyenv/versions/anaconda3-2022.10/etc/profile.d/conda.sh" ]; then
        . "$HOME/.anyenv/envs/pyenv/versions/anaconda3-2022.10/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/.anyenv/envs/pyenv/versions/anaconda3-2022.10/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export RUST_BACKTRACE=1

[ -f ~/.zshrc.local ] && source ~/.zshrc.local
