 #!/bin/bash

set -e

echo "Enabling parallel downloads for pacman"
sudo sed -i '/ParallelDownloads/c\ParallelDownloads = 24' /etc/pacman.conf

echo "Updating system"
sudo pacman -Syu --noconfirm

echo "Installing important packages..."

sudo pacman -S --needed --noconfirm htop nano networkmanager
sudo systemctl enable --now NetworkManager

echo "Installing dependencies for AUR wrapper"
sudo pacman -S --needed --noconfirm git curl linux-headers base-devel go

if command -v yay >/dev/null 2>&1; then
    echo "yay is already installed, skipping..."
else
    echo "Installing yay"
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi


echo "Installing pamac and paru"
sudo pacman -S --needed --noconfirm rustup cargo
rustup default stable
yay -S --needed --noconfirm pamac-all pamac-tray-plasma-git paru

echo "Installing reflector"
sudo pacman -S --needed --noconfirm reflector rsync

sudo reflector -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "Added fastest mirror lists: "
cat /etc/pacman.d/mirrorlist

sudo sh -c 'rm -f /etc/xdg/reflector/reflector.conf 2>/dev/null; cat > /etc/xdg/reflector/reflector.conf << EOF
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 6
--sort rate
EOF'

sudo systemctl enable --now reflector.timer


echo "Adding sdd trims to fstab"
echo sed -i '/\bssd\b/ {/discard/! s/\(ssd[^,]*\)/\1,discard=async/}' /etc/fstab

echo "Initialization is completed..."
sleep 3
