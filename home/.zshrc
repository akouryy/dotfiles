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

() { # Languages
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
}

() { # Completion
  zstyle ':completion:*' list-colors 'di=34' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'
  zstyle ':completion:*:ssh:*' hosts off
  setopt noautoremoveslash

  # https://stackoverflow.com/a/56760494
  h=()
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

export DROPBOX="$HOME/Dropbox"
hash -d db="$DROPBOX"
hash -d e="$DROPBOX/e"

alias bx='bundle exec'
alias cal='cal -y'
alias cl='cd -P'
alias cp='cp -i'
alias drpbi='xattr -w com.dropbox.ignored 1'
alias g='git'
alias ls='ls -hlaG'
alias mv='mv -i'
# ocaml: see above
alias poff='predict-off'
alias pon='predict-on'
alias rm='rm -i'
alias typora='open -a typora'
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
alias zshrc='source ~/.zshrc'
