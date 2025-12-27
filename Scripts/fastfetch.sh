#!/bin/bash

set -e

echo "Initializing fastfetch"
sleep 3

sudo pacman -S --noconfirm --needed fastfetch
if command -v bash &> /dev/null; then
	echo "Bash found!"
    if [ ! -f ~/.bashrc ]; then
        touch ~/.bashrc
        echo ".bashrc file created."
    fi
    if ! grep -q "fastfetch" ~/.bashrc; then
        echo "fastfetch" >> ~/.bashrc
        echo "fastfetch successfully added to .bashrc."
    else
        echo "fastfetch already exists in .bashrc file."
    fi
fi
if command -v fish &> /dev/null; then
	echo "Fish found!"
    if [ ! -f ~/.config/fish/config.fish ]; then
        mkdir -p ~/.config/fish
        touch ~/.config/fish/config.fish
        echo "config.fish file created."
    fi
    if ! grep -q "fastfetch" ~/.config/fish/config.fish; then
        echo "fastfetch" >> ~/.config/fish/config.fish
        echo "fastfetch successfully added to config.fish."
    else
        echo "fastfetch already exists in config.fish file."
    fi
fi

echo "Fastfetch initialized..."
sleep 2
