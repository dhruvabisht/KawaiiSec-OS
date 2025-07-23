#!/bin/bash

echo -e "\033[1;35m✨ Detecting your ZSH environment...\033[0m"

# Check if ZSH is installed
if ! command -v zsh &> /dev/null; then
  echo "❌ ZSH is not installed. Please install ZSH first."
  exit 1
fi

# Check if .zshrc exists
if [ -f "$HOME/.zshrc" ]; then
  echo "✅ Found ~/.zshrc"
else
  echo "⚠️  ~/.zshrc not found. You may need to create one manually."
fi

# Check if Oh My Zsh is installed
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "✅ Oh My Zsh is installed!"
  echo -e "\n💡 To activate the uwu.zsh-theme:"
  echo "1. Move 'uwu.zsh-theme' to ~/.oh-my-zsh/custom/themes/"
  echo "2. Edit ~/.zshrc and set: ZSH_THEME=\"uwu\""
else
  echo "❌ Oh My Zsh not found."
  echo -e "\n💡 You are using raw ZSH."
  echo "To activate the uwu.zsh-theme:"
  echo "1. Add this to your ~/.zshrc:"
  echo '   source /full/path/to/uwu.zsh-theme'
fi

echo -e "\n🌸 KawaiiSec terminal check complete." 