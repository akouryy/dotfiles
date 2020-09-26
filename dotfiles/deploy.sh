#!/bin/sh

set -euxC
shopt -s nullglob

BASE=$(cd $(dirname $0)/.. && pwd)

ln -s $BASE/karabiner ~/.config &&
  launchctl kickstart -k gui/`id -u`/org.pqrs.karabiner.karabiner_console_user_server || :

ln -s $BASE/home/* $BASE/home/.??* ~ || :

shopt -u nullglob
