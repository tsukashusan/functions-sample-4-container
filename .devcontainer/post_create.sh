#!/usr/bin/env zsh
set -euxo pipefail

mkdir -p /commandhistory
touch /commandhistory/.zsh_history
chown -R ${USER} /commandhistory

echo "autoload -Uz add-zsh-hook; append_history() { fc -W }; add-zsh-hook precmd append_history; export HISTFILE=/commandhistory/.zsh_history" >> /home/${USER}/.zshrc