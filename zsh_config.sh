#!/bin/bash

sudo usermod -s /usr/bin/zsh $(whoami)
sudo apt install -y zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/denysdovhan/spaceship-prompt.git ~/.zsh/spaceship-prompt
sudo ln -sf ~/.zsh/spaceship-prompt/spaceship.zsh /usr/local/share/zsh/site-functions/prompt_spaceship_setup

echo "\
# CUSTOM

source $HOME/.profile
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

prompt spaceship
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false
SPACESHIP_BATTERY_SHOW=false
SPACESHIP_EXEC_TIME_SHOW=false
" >> $HOME/.zshrc


source $HOME/.zshrc

echo "Done. You should log out and then log back in."
