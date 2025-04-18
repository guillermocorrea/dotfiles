#!/bin/bash

set -e

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking and installing dependencies...${NC}"

# Install curl and software-properties-common if missing
sudo apt update
sudo apt install -y curl software-properties-common gnupg2 ca-certificates lsb-release

# Install NVM
if ! command -v node &> /dev/null; then
  echo -e "${YELLOW}📥 Node.js not found. Installing NVM...${NC}"
  if ! command -v nvm &> /dev/null; then
    echo -e "${YELLOW}📥 Installing NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  else
    echo -e "${GREEN}✔ NVM already installed. Installing Node.js...${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
  fi
else
  echo -e "${GREEN}✔ NVM already installed.${NC}"
fi

# Install Neovim
if ! command -v nvim &> /dev/null; then
  echo -e "${YELLOW}📥 Installing Neovim...${NC}"
  sudo apt install -y neovim
else
  echo -e "${GREEN}✔ Neovim already installed.${NC}"
fi

if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null && ! command -v pyenv &> /dev/null; then
  echo -e "${YELLOW}📥 Installing pyenv...${NC}"
  curl https://pyenv.run | bash
else
  echo -e "${GREEN}✔ pyenv already installed.${NC}"
fi

# Install GitHub CLI (gh)
if ! command -v gh &> /dev/null; then
  echo -e "${YELLOW}📥 Installing GitHub CLI...${NC}"
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
  echo -e "${GREEN}✔ GitHub CLI already installed.${NC}"
fi

# Installing Github Copilot CLI
if ! command -v gh copilot &> /dev/null; then
  echo -e "${YELLOW}📥 Installing GitHub Copilot CLI...${NC}"
  gh extension install github/gh-copilot
else
  echo -e "${GREEN}✔ GitHub Copilot CLI already installed.${NC}"
fi

# Installing oh-my-zsh and plugins...

echo -e "${BLUE}🐚 Installing Zsh...${NC}"
if ! command -v zsh &> /dev/null; then
  echo -e "${YELLOW}📥 Installing Zsh...${NC}"
  sudo apt install -y zsh
else
  echo -e "${GREEN}✔ Zsh already installed.${NC}"
fi

echo -e "${BLUE}🔄 Setting Zsh as default shell...${NC}"
if [ "$SHELL" != "$(which zsh)" ]; then
  echo -e "${YELLOW}📥 Changing default shell to Zsh...${NC}"
  sudo chsh -s "$(which zsh)" "$USER"
  echo -e "${GREEN}✔ Default shell changed to Zsh.${NC}"
else
  echo -e "${GREEN}✔ Zsh is already the default shell.${NC}"
fi

echo -e "${BLUE}🔧 Installing Oh My Zsh...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh
else
  echo -e "${GREEN}✔ Oh My Zsh already installed.${NC}"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo -e "${BLUE}🔌 Installing plugins...${NC}"

plugins=(
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
)

for plugin in "${plugins[@]}"; do
  name=$(basename "$plugin")
  dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    git clone https://github.com/$plugin "$dest"
    echo -e "${GREEN}✔ Installed $name${NC}"
  else
    echo -e "${GREEN}✔ $name already installed${NC}"
  fi
done

echo -e "${BLUE}📦 Installing Oh My Zsh plugin snippets...${NC}"

declare -A ohmyzsh_plugins=(
  [web-search]="web-search"
  [azure]="azure"
  [copyfile]="copyfile"
  [docker]="docker"
  [docker-compose]="docker-compose"
  [gh]="gh"
  # [kubectl]="kubectl"
  # [zsh-shift-select]="zsh-shift-select"
)

for plugin in "${!ohmyzsh_plugins[@]}"; do
  file="$ZSH_CUSTOM/plugins/$plugin/${plugin}.plugin.zsh"
  if [ ! -f "$file" ]; then
    mkdir -p "$ZSH_CUSTOM/plugins/$plugin"
    curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/${plugin}/${plugin}.plugin.zsh" -o "$file"
    echo -e "${GREEN}✔ Downloaded $plugin${NC}"
  else
    echo -e "${GREEN}✔ $plugin already present${NC}"
  fi
done

echo "🔧 Setting up Neovim (LazyVim) config..."

mkdir -p "$HOME/.config"
ln -sf "$PWD/.config/nvim" "$HOME/.config/nvim"

echo "🔍 Installing Neovim CLI dependencies..."

sudo apt install -y fzf ripgrep fd-find gcc g++ make unzip tree-sitter

# Fix fd binary name (Ubuntu/Debian uses `fdfind`)
if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
  echo "🔗 Symlinking fd -> fdfind"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "📦 Bootstrapping LazyVim..."
nvim --headless "+Lazy! sync" +qa

echo "✅ Neovim and LazyVim setup complete!"


echo "🔗 Symlinking .zshrc"
ln -sf "$PWD/.zshrc" "$HOME/.zshrc"

echo -e "${GREEN}✅ Setup complete! Launch a new terminal or run: source ~/.zshrc${NC}"
