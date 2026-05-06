# oh-my-zsh (installed system-wide in /opt/oh-my-zsh)
export ZSH=/opt/oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Go
export PATH="/usr/local/go/bin:$PATH"

# npm global installs — user-local prefix (no sudo needed)
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"

source /opt/safehouse/tmux-picker.sh
