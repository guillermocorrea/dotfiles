FROM mcr.microsoft.com/devcontainers/base:noble

ENV HOME=/home/vscode
ENV USER=vscode

RUN git clone https://github.com/guillermocorrea/dotfiles.git $HOME/dotfiles
WORKDIR $HOME/dotfiles
RUN chmod +x bootstrap.sh \
    && ./bootstrap.sh