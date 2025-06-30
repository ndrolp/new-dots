
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# If you come from bash you might have to change your $PATH.
PATH="/opt/flutter/bin:$PATH"
PATH="$HOME/Android/Sdk/platform-tools:$PATH"
PATH="$HOME/.local/share/bob/nvim-bin:$PATH"
PATH="$HOME/go/bin:$PATH"
PATH="$HOME/.cargo/bin:$PATH"
PATH="/usr/bin/flutter/bin:$PATH"
export PATH
export VISUAL=nvim
export EDITOR=nvim
export FZF_TMUX_OPTS='-p80%,60%'
export FZF_DEFAULT_OPTS="--color=bg+:-1,bg:-1"  # Both bg and bg+ set to -1 for transparency
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh_custom"
export CHROME_EXECUTABLE=/bin/google-chrome-stable
export CHROME_EXECUTABLE


ZSH_THEME="spaceship"
SPACESHIP_PROMPT_ORDER=(
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  exec_time     # Execution time
  line_sep      # Line break
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)
SPACESHIP_RPROMPT_ORDER=(
  node
  package
  venv 
  python
)

SPACESHIP_VENV_GENERIC_NAMES=(virtualenv env venv .venv generic-name)
SPACESHIP_PYTHON_SYMBOL=" "
SPACESHIP_TIME_PREFIX=""
SPACESHIP_PYTHON_SHOW=true
SPACESHIP_PYTHON_COLOR="green"
# SPACESHIP_TIME_SHOW=true
SPACESHIP_USER_SHOW=always
SPACESHIP_TIME_FORMAT="%t"
SPACESHIP_BATTERY_SHOW=always
SPACESHIP_VENV_SHOW=true
SPACESHIP_DIR_PREFIX="󰉋 "
SPACESHIP_USER_PREFIX=" "
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_CHAR_SYMBOL="❯"
SPACESHIP_CHAR_SUFFIX=" "

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions history fzf zsh-syntax-highlighting pip)

source $ZSH/oh-my-zsh.sh

# User configuration
export FZF_DEFAULT_OPTS=" \
--color=bg+:-1 \
--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
--layout reverse --height 40%"
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias zr="source ~/.zshrc"
alias zc="nvim ~/.zshrc"
alias nvimconfig="cd ~/.dotfiles/.config/nvim;nvim"
alias dotfiles="cd ~/.dotfiles;nvim"
alias home="cd ~/"
alias fv="fd --type f --hidden --exclude .git | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}' | xargs nvim"
alias lg="lazygit"
alias ff="fastfetch"
alias p="source ~/.dotfiles/scripts/tmux/projects.sh"
alias snvim="sudo -E nvim"
alias pns="cd ~/Vaults/personal;nvim"
alias open="xdg-open"
# alias colors='for i in {0..255}; do printf "\e[48;5;%sm %3d \e[0m" "$i" "$i"; (( (i+1) % 16 == 0 )) && echo ""; done'
alias cdp='~/.dotfiles/scripts/tmux/projects.sh'
alias zj="zellij"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# bun completions
[ -s "/home/ndrolp/.bun/_bun" ] && source "/home/ndrolp/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export ZELLIJ_CONFIG_DIR="$HOME/.config/zellij"

# eval "$(zellij setup --generate-auto-start zsh)"
# eval "$(starship init zsh)"

# if [ "$TMUX" = "" ]; then
# if tmux has-session -t "Main" 2>/dev/null; then
#     tmux;
# else
#     tmux new-session -s "Main"
# fi
# fi
#
unalias pip

export PATH=$PATH:/home/ndro/.spicetify
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias pvim='XDG_CONFIG_HOME="$HOME/.dotfiles/.config/nvim_new" nvim'
# alias pv="XDG_CONFIG_HOME='$HOME/Documentos/nvim_new' nvim -u '$HOME/Documentos/new_nvim/nvim/init.lua'"
# alias pv="nvim -u '$HOME/Documentos/new_nvim/nvim/init.lua'"
alias pv="NVIM_APPNAME=nvim_new nvim"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

#source "$HOME/.zsh/spaceship/spaceship.zsh"
