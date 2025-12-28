#!/bin/bash

set -e

echo "Installing necessary apps"
sleep 3

yay -S --needed --noconfirm brave-bin
sudo pacman -S --needed --noconfirm kitty nautilus fuzzel zed gnome-text-editor gnome-keyring kwallet blueman grim slurp libreoffice-still profile-sync-daemon

sudo mkdir -p /usr/share/psd/browsers
echo 'DIRArr[0]="$XDG_CONFIG_HOME/BraveSoftware/Brave-Browser"' | sudo tee /usr/share/psd/browsers/brave
echo 'PSNAME="brave"' | sudo tee -a /usr/share/psd/browsers/brave
psd
sed -i 's/^BROWSERS=.*/BROWSERS="brave"/' ~/.config/psd/psd.conf
systemctl --user enable psd
systemctl --user start psd

echo "Installing windows compatibility tools"

sudo pacman -S --needed --noconfirm wine winetricks wine-mono wine-gecko docker docker-compose
sudo systemctl enable --now docker
sudo usermod -aG docker $(echo $USER)
yay -S --needed --noconfirm bottles winboat

echo "Installed necessary apps"
sleep 3
