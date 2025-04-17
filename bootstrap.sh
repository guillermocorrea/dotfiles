#!/bin/bash

set -e

echo "🔍 Checking and installing dependencies..."

# Install curl and software-properties-common if missing
sudo apt update
sudo apt install -y curl software-properties-common gnupg2 ca-certificates lsb-release

# Install NVM
if ! command -v nvm &> /dev/null; then
  echo "📥 Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  echo "✔ NVM already installed."
fi

# Install Neovim
if ! command -v nvim &> /dev/null; then
  echo "📥 Installing Neovim..."
  sudo apt install -y neovim
else
  echo "✔ Neovim already installed."
fi

# Install pyenv
if ! command -v pyenv &> /dev/null; then
  echo "📥 Installing pyenv..."
  curl https://pyenv.run | bash
else
  echo "✔ pyenv already installed."
fi

# Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
  echo "📥 Installing GitHub CLI..."
  type -p curl >/dev/null || sudo apt install curl -y
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" | \
    sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install gh -y
else
  echo "✔ GitHub CLI already installed."
fi

# Installing oh-my-zsh and plugins...

echo "🔧 Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
else
  echo "✔ Oh My Zsh already installed."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "🔌 Installing plugins..."

plugins=(
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
)

for plugin in "${plugins[@]}"; do
  name=$(basename "$plugin")
  dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    git clone https://github.com/$plugin "$dest"
    echo "✔ Installed $name"
  else
    echo "✔ $name already installed"
  fi
done

echo "📦 Installing Oh My Zsh plugin snippets..."

declare -A ohmyzsh_plugins=(
  [web-search]="web-search"
  [azure]="azure"
  [copyfile]="copyfile"
  [docker]="docker"
  [docker-compose]="docker-compose"
  [gh]="gh"
  [kubectl]="kubectl"
  [zsh-shift-select]="zsh-shift-select"
)

for plugin in "${!ohmyzsh_plugins[@]}"; do
  file="$ZSH_CUSTOM/plugins/$plugin/${plugin}.plugin.zsh"
  if [ ! -f "$file" ]; then
    mkdir -p "$ZSH_CUSTOM/plugins/$plugin"
    curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/${plugin}/${plugin}.plugin.zsh" -o "$file"
    echo "✔ Downloaded $plugin"
  else
    echo "✔ $plugin already present"
  fi
done

echo "🔗 Symlinking .zshrc"
ln -sf "$PWD/.zshrc" "$HOME/.zshrc"

echo "✅ Setup complete! Launch a new terminal or run: source ~/.zshrc"
