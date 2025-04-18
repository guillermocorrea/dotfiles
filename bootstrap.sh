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
    echo -e "${GREEN}✔ NVM installed successfully!${NC}"
  else
    echo -e "${GREEN}✔ NVM already installed. Installing Node.js...${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
  fi
else
  echo -e "${GREEN}✔ NVM already installed.${NC}"
fi

# Install .NET SDK
if ! command -v dotnet &> /dev/null; then
  echo -e "${YELLOW}📥 Installing .NET SDK...${NC}"
  wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
  chmod +x dotnet-install.sh
  ./dotnet-install.sh --channel STS
  rm dotnet-install.sh
else
  echo -e "${GREEN}✔ .NET SDK already installed.${NC}"
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
if [ "$SHELL" != "$(which zsh)" ] && [ -n "$USER" ]; then
  echo -e "${YELLOW}📥 Changing default shell to Zsh...${NC}"
  sudo chsh -s "$(which zsh)" "$USER"
  echo -e "${GREEN}✔ Default shell changed to Zsh.${NC}"
elif [ -z "$USER" ]; then
  echo -e "${YELLOW}⚠️ USER variable not set, skipping shell change${NC}"
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

# Add ~/.local/bin to PATH if not already
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
  export PATH="$HOME/.local/bin:$PATH"
  echo "➕ Added ~/.local/bin to PATH"
fi

# Neovim (LazyVim) setup

echo "🔧 Setting up Neovim (LazyVim) config..."

echo "🔍 Installing Neovim CLI dependencies..."

sudo apt install -y fzf ripgrep fd-find gcc g++ make unzip

# Fix fd binary name (Ubuntu/Debian uses `fdfind`)
if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
  echo "🔗 Symlinking fd -> fdfind"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
  export PATH="$HOME/.local/bin:$PATH"
fi

if [ ! -d "$HOME/.config/nvim" ]; then
  echo "📥 No existing Neovim config. Cloning LazyVim starter..."
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
else
  echo "🔗 Linking Neovim config from dotfiles..."
  mkdir -p "$HOME/.config"
  ln -sf "$PWD/.config/nvim" "$HOME/.config/nvim"
fi

echo "📦 Bootstrapping LazyVim..."
#vim --headless "+Lazy! sync" +qa

echo "✅ Neovim and LazyVim setup complete!"

echo "🔗 Symlinking .zshrc"
ln -sf "$PWD/.zshrc" "$HOME/.zshrc"

# Add Nerd Font installation
echo -e "${BLUE}🔤 Installing Nerd Font...${NC}"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Choose your preferred font - JetBrains Mono is popular for coding
FONT_NAME="JetBrainsMono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/$FONT_NAME.zip"

if [ ! -f "$FONT_DIR/${FONT_NAME}NerdFont-Regular.ttf" ]; then
  echo -e "${YELLOW}📥 Downloading $FONT_NAME Nerd Font...${NC}"
  TEMP_DIR=$(mktemp -d)
  wget -q --show-progress -O "$TEMP_DIR/$FONT_NAME.zip" "$FONT_URL"
  unzip -q "$TEMP_DIR/$FONT_NAME.zip" -d "$FONT_DIR"
  rm -rf "$TEMP_DIR"
  
  # Update font cache
  if command -v fc-cache &> /dev/null; then
    echo -e "${YELLOW}🔄 Updating font cache...${NC}"
    fc-cache -f "$FONT_DIR"
  fi
  
  echo -e "${GREEN}✅ Nerd Font installed successfully!${NC}"
  echo -e "${YELLOW}ℹ️ You may need to configure your terminal to use the new font.${NC}"
else
  echo -e "${GREEN}✔ $FONT_NAME Nerd Font already installed${NC}"
fi

# Attempt to configure GNOME Terminal font
if command -v gsettings &> /dev/null && command -v gnome-terminal &> /dev/null; then
  echo -e "${BLUE}🔧 Attempting to set GNOME Terminal font...${NC}"
  # Get default profile UUID (remove single quotes)
  PROFILE_UUID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
  if [ -n "$PROFILE_UUID" ]; then
    PROFILE_PATH="/org/gnome/terminal/legacy/profiles:/:$PROFILE_UUID/"
    # Check if the profile path is valid
    if gsettings list-keys "org.gnome.Terminal.Legacy.Profile:$PROFILE_PATH" &> /dev/null; then
      echo -e "${YELLOW}⚙️ Setting font for profile: $PROFILE_UUID${NC}"
      # Set font (adjust size '11' if needed)
      FONT_SETTING="'${FONT_NAME} Nerd Font 11'"
      gsettings set "org.gnome.Terminal.Legacy.Profile:$PROFILE_PATH" use-system-font false
      gsettings set "org.gnome.Terminal.Legacy.Profile:$PROFILE_PATH" font "$FONT_SETTING"
      echo -e "${GREEN}✅ GNOME Terminal font set to $FONT_SETTING (may require terminal restart)${NC}"
    else
       echo -e "${YELLOW}⚠️ Could not find GNOME Terminal profile path: $PROFILE_PATH${NC}"
    fi
  else
    echo -e "${YELLOW}⚠️ Could not get default GNOME Terminal profile UUID.${NC}"
  fi
else
  echo -e "${YELLOW}ℹ️ Skipping GNOME Terminal font configuration (gsettings/gnome-terminal not found).${NC}"
fi

echo -e "${GREEN}✅ Setup complete! Launch a new terminal or run: source ~/.zshrc${NC}"

# launch zsh
if [ -n "$ZSH_VERSION" ]; then
  echo -e "${GREEN}🔄 Launching Zsh...${NC}"
  exec zsh
else
  echo -e "${YELLOW}⚠️ Zsh is not the current shell. Please restart your terminal.${NC}"
fi
echo -e "${GREEN}🚀 Enjoy your new development environment!${NC}"

# install nodejs lts
if ! command -v node &> /dev/null; then
  echo -e "${YELLOW}📥 Installing Node.js LTS...${NC}"
  nvm install --lts
else
  echo -e "${GREEN}✔ Node.js LTS already installed.${NC}"
fi