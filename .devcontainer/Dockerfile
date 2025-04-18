FROM mcr.microsoft.com/devcontainers/base:noble

ENV HOME=/home/vscode
ENV USER=vscode

COPY ../.config $HOME/dotfiles/.config
COPY ../.zshrc $HOME/dotfiles/.zshrc
COPY ../bootstrap.sh $HOME/dotfiles/bootstrap.sh

WORKDIR $HOME/dotfiles
RUN chmod +x bootstrap.sh \
    && ./bootstrap.sh