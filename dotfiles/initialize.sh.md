```sh
#!/bin/sh

set -euxC

# Homebrew
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

# # zplug
# curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

# icdiff: 人間向け差分ツール https://github.com/jeffkaufman/icdiff
brew install icdiff

# tag: Macのタグ管理 https://github.com/jdberry/tag
brew install tag
```
