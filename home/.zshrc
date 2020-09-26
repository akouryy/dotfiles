autoload -Uz compinit; compinit
autoload -Uz colors; colors
autoload -Uz add-zsh-hook
autoload -Uz terminfo
autoload predict-on; predict-on

export LANG=ja_JP.UTF-8
setopt auto_cd
setopt auto_pushd
setopt correct
setopt notify

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
bindkey -v
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
predict-toggle() { ((predict_on=1-predict_on)) && predict-on || predict-off }
zle -N predict-toggle
bindkey '^P' history-beginning-search-backward-end
bindkey '^N' history-beginning-search-forward-end
bindkey '^K' kill-line
bindkey '^W' backward-kill-word
bindkey '^Z' predict-toggle

export LSCOLORS=exfxcxdxbxegedabagacad
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
chpwd() { ls -hlaFv }

() { # Languages
  () { # Scala
    alias sbt8='sbt -java-home /Library/Java/JavaVirtualMachines/jdk1.8.0_144.jdk/Contents/Home'
  }
  () { # Ruby
    export RBENV_ROOT="$HOME/.rbenv"
    export PATH="$RBENV_ROOT/bin:$PATH"
    export RUBY_CONFIGURE_OPTS="--with-readline-dir=$(brew --prefix readline)"
    export RUBYLIB="$DROPBOX/a/c/lib/ruby:$DROPBOX/a/c/zprb:$RUBYLIB"
    eval "$(rbenv init - --no-rehash)"
    rbenv rehash &
  }
  () { # Node
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    eval "$(nodenv init - --no-rehash)"
    nodenv rehash &
  }
  () { # Go
    export GOPATH=$DROPBOX/b/s/c/go
    export GOENV_DISABLE_GOPATH=1
    export PATH="$HOME/.goenv/bin:$PATH"
    eval "$(goenv init - --no-rehash)"
    goenv rehash &
  }
  () { # Python
    eval "$(pyenv init - --no-rehash)"
    pyenv rehash &
  }
  () { # OCaml
    alias ocaml="rlwrap ocaml"
    export OCAMLRUNPARAM=b
    test -r ~/.opam/opam-init/init.sh && . ~/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true
  }
  () { # Nim
    export PATH="$HOME/.nimble/bin:$PATH"
  }
  () { # bc, dc
    export PATH="/usr/local/opt/bc/bin:$PATH"
  }
}

() { # Completion
  zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
  zstyle ':completion:*:ssh:*' hosts off
  setopt noautoremoveslash

  # https://stackoverflow.com/a/56760494
  local h=()
  for f in ~/.ssh/config ~/.ssh/conf.d/*; do
    [[ -f $f ]] && h=($h ${${${(@M)${(f)"$(cat $f)"}:#Host *}#Host }:#*[*?]*})
  done
  # if [[ -r ~/.ssh/known_hosts ]]; then
  #   h=($h ${${${(f)"$(cat ~/.ssh/known_hosts{,2} || true)"}%%\ *}%%,*}) 2>/dev/null
  # fi
  if [[ $#h -gt 0 ]]; then
    zstyle ':completion:*:ssh:*' hosts $h
    zstyle ':completion:*:slogin:*' hosts $h
  fi
}

() { # Other PATHs
  export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
  export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
  export PATH="~/.local/bin:$PATH"
  # export PATH="$HOME/kwankyag/ghdl-20181129-macosx-mcode/bin:$PATH"
  export PATH="$DROPBOX/a/c/bin:$DROPBOX/a/c/bin/public:$PATH"
}

hash -d db="$DROPBOX"
hash -d e="$DROPBOX/e"

alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias .......='cd ../../../../../..'
alias .zshrc='source ~/.zshrc'
alias bx='bundle exec'
alias cal='cal -y'
alias cd..=$'echo $\'use `..` instead.\' && cd ..'
alias cdr='git top && cd $(git top)'
alias chr=$'ruby -e \'p ARGV.map{|a| a.to_i.chr Encoding::UTF_8 }\' --'
alias cl='cd -P'
alias cp='cp -i'
alias drpbi='xattr -w com.dropbox.ignored 1'
alias g='git'
alias g++='g++ -std=c++17 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -O2'
alias g++d='g++ -std=c++17 -I$DROPBOX/b/codes/comp -Wall -Wno-logical-op-parentheses -fsanitize=address -DEBUG -DDEBUG'
alias hc='history -c'
alias ls=$'ls -hlaFv --color=auto --time-style=\'+%Y-%m-%d %H:%M:%S\''
function md() { mkdir -p "$@" && eval cd "\"\$$#\"" }
alias minisat="$DROPBOX/a/c/env-setup/minisat/core/minisat_release"
alias mv='mv -i'
# ocaml: see above
alias poff='predict-off'
alias pon='predict-on'
alias rm='rm -i'
# sbt8: see above
alias typora='open -a typora'
alias u+x='chmod u+x'
alias vg='vimgolf put'
alias wh='command -v' # alias wh='which -a'
alias ya='yarn add'
alias yd='yarn add --dev'
alias yga='yarn global add'
alias yr='yarn run'
alias yrb='yarn run build'
alias yrd='yarn run dev'
alias yrl='yarn run lint'
alias yrs='yarn run start'
alias yy='yarn'
alias zshrc='sl ~/.zshrc'
