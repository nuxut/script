#!/bin/bash
set -e 

echo "Initializing firewall"
sleep 2

echo "Installing ufw"
sudo pacman -S --noconfirm --needed ufw

echo "Configuring ufw firewall"
echo y | sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow http
sudo ufw allow https
sudo ufw reload
sudo ufw enable
sudo systemctl enable --now ufw

echo "Firewall initialization completed..."
sleep 2
