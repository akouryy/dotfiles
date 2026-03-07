#!/bin/sh

set -euC

BASE=$(cd "$(dirname "$0")/.." && pwd)

# Create a symlink. Report as confirmed if already correct, warn if conflict.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    if [ "$dst" -ef "$src" ]; then
      echo "confirmed: $dst"
    else
      echo "warn:      $dst -> $(readlink "$dst") (expected $src, skipping)"
    fi
  elif [ -e "$dst" ]; then
    echo "warn:      $dst exists as a regular file (skipping)"
  else
    ln -s "$src" "$dst"
    echo "linked:    $dst -> $src"
  fi
}

# ~/
link "$BASE/home/.gitignore_global" "$HOME/.gitignore_global"
link "$BASE/home/.ripgreprc"        "$HOME/.ripgreprc"
link "$BASE/home/.vimrc"            "$HOME/.vimrc"

# ~/.config/
mkdir -p "$HOME/.config"
link "$BASE/karabiner"                  "$HOME/.config/karabiner"
link "$BASE/home/.config/starship.toml" "$HOME/.config/starship.toml"

# Reload karabiner
launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server" || true

# ~/.zshrc: source-based (not symlink)
ZSHRC_SRC="$BASE/home/.zshrc"
if [ -e "$HOME/.zshrc" ]; then
  if grep -q "dotfiles/home/.zshrc" "$HOME/.zshrc"; then
    echo "confirmed: ~/.zshrc"
  else
    echo "warn:      ~/.zshrc exists but does not source dotfiles"
    echo "           Add manually: source \"$ZSHRC_SRC\""
  fi
else
  printf 'source "%s"\n' "$ZSHRC_SRC" > "$HOME/.zshrc"
  echo "created:   ~/.zshrc"
fi
