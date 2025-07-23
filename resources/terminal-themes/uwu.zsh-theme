# ~/.oh-my-zsh/custom/themes/uwu.zsh-theme
# 🌸 KawaiiSec OS Terminal Theme - Enhanced v0.2 🌸
# Cute. Dangerous. UwU-powered.

# Kawaii Color Palette (256-color codes)
local kawaii_pink="%F{213}"      # Bright pink
local kawaii_purple="%F{177}"    # Lavender purple  
local kawaii_blue="%F{117}"      # Baby blue
local kawaii_mint="%F{158}"      # Mint green
local kawaii_peach="%F{223}"     # Peach
local kawaii_gray="%F{250}"      # Light gray
local kawaii_white="%F{255}"     # Pure white
local reset="%f"

# Kawaii Icons
local sakura="🌸"
local sparkles="✨"
local cat="🐱"
local heart="💖"
local lightning="⚡"
local folder="📁"
local git_branch="🌿"

# Git status function with kawaii indicators
function git_prompt_info() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    local status=""
    
    # Check for changes
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      status="${kawaii_peach}${sparkles}${reset}" # Uncommitted changes
    else
      status="${kawaii_mint}${heart}${reset}"     # Clean repo
    fi
    
    echo " ${kawaii_purple}${git_branch} ${branch}${reset} ${status}"
  fi
}

# User status with kawaii face
function user_status() {
  if [[ $UID -eq 0 ]]; then
    echo "${kawaii_pink}${cat}root${reset}"  # Root user gets cat emoji
  else
    echo "${kawaii_blue}${sakura}%n${reset}" # Regular user gets sakura
  fi
}

# Exit status indicator
function exit_status() {
  if [[ $? -eq 0 ]]; then
    echo "${kawaii_mint}(◕‿◕)${reset}"  # Happy face for success
  else
    echo "${kawaii_pink}(╥﹏╥)${reset}"  # Sad face for errors
  fi
}

# Main prompt
PROMPT='$(user_status) ${kawaii_gray}@${reset} ${kawaii_purple}%m${reset} ${kawaii_blue}${folder} %~${reset}$(git_prompt_info)
$(exit_status) ${kawaii_peach}${lightning}${reset} '

# Right prompt with cute time display
RPROMPT='${kawaii_gray}${sparkles} %D{%H:%M:%S} ${sparkles}${reset}'

# Additional ZSH options for better UX
setopt PROMPT_SUBST

# Source KawaiiSec audio system if available
KAWAII_AUDIO_PATH="${ZDOTDIR:-$HOME}/.kawaiisec/kawaii-audio.sh"
if [[ -f "$KAWAII_AUDIO_PATH" ]]; then
    source "$KAWAII_AUDIO_PATH"
    KAWAII_AUDIO_AVAILABLE=true
elif [[ -f "$(dirname "$0")/../../resources/scripts/kawaii-audio.sh" ]]; then
    source "$(dirname "$0")/../../resources/scripts/kawaii-audio.sh"
    KAWAII_AUDIO_AVAILABLE=true
else
    KAWAII_AUDIO_AVAILABLE=false
fi

# Command execution hook with audio feedback
preexec_kawaii() {
    # Store command for post-execution feedback
    KAWAII_LAST_COMMAND="$1"
}

precmd_kawaii() {
    local exit_code=$?
    
    # Only play audio for interactive commands (not just pressing enter)
    if [[ -n "$KAWAII_LAST_COMMAND" && "$KAWAII_AUDIO_AVAILABLE" == true ]]; then
        if [[ $exit_code -eq 0 ]]; then
            kawaii_did_it >/dev/null 2>&1
        else
            kawaii_nani >/dev/null 2>&1
        fi
    fi
    
    # Clear the command
    unset KAWAII_LAST_COMMAND
}

# Register hooks
if [[ "$KAWAII_AUDIO_AVAILABLE" == true ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook preexec preexec_kawaii
    add-zsh-hook precmd precmd_kawaii
fi

# Kawaii aliases (optional - can be sourced separately)
alias uwu='echo "🌸 Stay cute, stay root! 💖"'
alias nyan='echo "ฅ(＾◡＾)ฅ"'
alias kawaii-help='echo "🌸 KawaiiSec Commands:\n  uwu - Show kawaii message\n  nyan - Cat face\n  kawaii-help - This help\n  kawaii_audio_status - Show audio system status"'

# Audio system aliases
if [[ "$KAWAII_AUDIO_AVAILABLE" == true ]]; then
    alias kawaii-audio-status='kawaii_audio_status'
    alias kawaii-test-denied='kawaii_denied'
    alias kawaii-test-welcome='kawaii_welcome'
    alias kawaii-test-success='kawaii_did_it'
    alias kawaii-test-error='kawaii_nani'
fi
