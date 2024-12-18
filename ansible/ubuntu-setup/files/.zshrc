# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.oh-my-zsh

# Enable zsh-autosuggestions
source $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# Enable zsh-syntax-highlighting
source $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# Enable you-should-use
source $HOME/.oh-my-zsh/custom/plugins/you-should-use/you-should-use.plugin.zsh
# Enable zsh-bat
source $HOME/.oh-my-zsh/custom/plugins/zsh-bat/zsh-bat.plugin.zsh

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-bat you-should-use)

source $ZSH/oh-my-zsh.sh

# -------------------------------------------------------------------
# make some commands (potentially) less destructive
# -------------------------------------------------------------------
alias 'rm=rm -i'

# -------------------------------------------------------------------
# Git
# -------------------------------------------------------------------
alias ga='git add'
alias gp='git push'
alias gl='git log'
alias gs='git status'
alias gd='git diff'
alias gm='git commit -m'
alias gma='git commit -am'
alias gb='git branch'
alias gc='git checkout'
alias gra='git remote add'
alias grr='git remote rm'
alias gpu='git pull'
alias gcl='git clone'
alias gta='git tag -a -m'
alias gf='git reflog'

# leverage an alias from the ~/.gitconfig
alias gh='git hist'

# -------------------------------------------------------------------
# More aliases
# -------------------------------------------------------------------

alias ls="lsd"
alias ll="lsd -l"
alias la="lsd -la"

# -------------------------------------------------------------------
# nvm
# -------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# -------------------------------------------------------------------
# starship
# -------------------------------------------------------------------
eval "$(starship init zsh)"

