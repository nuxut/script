 #!/bin/bash

set -e

echo "Enabling parallel downloads for pacman"
sudo sed -i '/ParallelDownloads/c\ParallelDownloads = 12' /etc/pacman.conf

echo "Installing reflector"
sudo pacman -S --needed --noconfirm reflector rsync

if sudo reflector -l 6 --sort rate --save /etc/pacman.d/mirrorlist; then
    echo "Added fastest mirror lists: "
else
    echo "Connection is not stable! Reflector will work periodically later on..."
    echo "Current mirror lists: "
fi
cat /etc/pacman.d/mirrorlist
sleep 2

sudo sh -c 'rm -f /etc/xdg/reflector/reflector.conf 2>/dev/null; cat > /etc/xdg/reflector/reflector.conf << EOF
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 6
--sort rate
EOF'

sudo systemctl enable --now reflector.timer

echo "Mirror list will be updated periodically..."
sleep 1

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

echo "Configuring pamac..."
if [ -f /etc/pamac.conf ]; then
    echo "pamac.conf found, updating settings..."
    sudo sed -i '/#EnableAUR/s/^#//' /etc/pamac.conf || true
    sudo sed -i '/#KeepBuiltPkgs/s/^#//' /etc/pamac.conf || true
    sudo sed -i '/#CheckAURUpdates/s/^#//' /etc/pamac.conf || true
    sudo sed -i '/#CheckAURVCSUpdates/s/^#//' /etc/pamac.conf || true
    sudo sed -i '/#CheckFlatpakUpdates/s/^#//' /etc/pamac.conf || true
    sudo sed -i '/#EnableFlatpak/s/^#//' /etc/pamac.conf || true
else
    echo "pamac.conf not found, creating with default settings..."
    sudo sh -c 'cat > /etc/pamac.conf << EOF
### Pamac configuration file

## When removing a package, also remove those dependencies
## that are not required by other packages (recurse option):
#RemoveUnrequiredDeps

## How often to check for updates, value in hours (0 to disable):
RefreshPeriod = 6

## When no update is available, hide the tray icon:
#NoUpdateHideIcon

## When applying updates, enable packages downgrade:
#EnableDowngrade

## When installing packages, do not check for updates:
#SimpleInstall

## Allow Pamac to search and install packages from AUR:
EnableAUR

## Keep built packages from AUR in cache after installation:
KeepBuiltPkgs

## When AUR support is enabled check for updates from AUR:
CheckAURUpdates

## When check updates from AUR support is enabled check for vcs updates:
CheckAURVCSUpdates

## AUR build directory:
BuildDirectory = /var/tmp

## Number of versions of each package to keep when cleaning the packages cache:
KeepNumPackages = 3

## Remove only the versions of uninstalled packages when cleaning the packages cache:
#OnlyRmUninstalled

## Download updates in background:
#DownloadUpdates

## Offline upgrade:
#OfflineUpgrade

## Maximum Parallel Downloads:
MaxParallelDownloads = 4

CheckFlatpakUpdates

#EnableSnap

EnableFlatpak
EOF'
fi

# Ensure correct permissions
echo "Setting permissions for /etc/pamac.conf..."
sudo chmod 644 /etc/pamac.conf
sudo chown root:root /etc/pamac.conf
ls -l /etc/pamac.conf



echo "Adding sdd trims to fstab"
echo sed -i '/\bssd\b/ {/discard/! s/\(ssd[^,]*\)/\1,discard=async/}' /etc/fstab

echo "Initialization is completed..."
sleep 3
