# Dotfiles for Zsh + Oh My Zsh + Plugins

This repo sets up a Zsh environment with:
- Oh My Zsh
- Popular Zsh plugins (autosuggestions, syntax highlighting, docker, git, etc.)
- Bootstrap script for easy installation

## 🚀 Setup Instructions

```bash
git clone https://github.com/guillermocorrea/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

## 📦 Included Apps

- NVM (Node version manager) https://github.com/nvm-sh/nvm
- Neovim (Text editor)
- Pyenv (Python env manager)
- Github CLI + Copilot extension
- Zsh (set as default shell) + Oh My Zsh

## 🔌 Included Plugins

- git
- zsh-autosuggestions
- zsh-syntax-highlighting
- web-search
- azure
- copyfile
- docker
- docker-compose
- gh
- kubectl
- zsh-shift-select

## 🔤 Aliases

- `alias copilot="gh copilot"`
- `alias gcs="gh copilot suggest"`
- `alias gce="gh copilot explain"`
- `alias vim="nvim"`

## 🖌️ Themes

- Zsh: robbyrussell

## 🧼 Customize

Feel free to add more plugins or modify `.zshrc` to your taste.
