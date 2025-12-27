#!/bin/bash

set -e

echo "Initializing system cosmetics"
sleep 2

echo "Setting up Grub"
line=$(sudo grep "^GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub)
quiet_present=$(echo "$line" | grep -o 'quiet' || true)
splash_present=$(echo "$line" | grep -o 'splash' || true)
if [[ -z "$quiet_present" && -z "$splash_present" ]]; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
elif [[ -z "$quiet_present" && -n "$splash_present" ]]; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)splash"/GRUB_CMDLINE_LINUX_DEFAULT="\1quiet splash"/' /etc/default/grub
elif [[ -n "$quiet_present" && -z "$splash_present" ]]; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)quiet"/GRUB_CMDLINE_LINUX_DEFAULT="\1quiet splash"/' /etc/default/grub
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing Plymouth"
sudo pacman -S --noconfirm --needed plymouth


config_file="/etc/mkinitcpio.conf"
hooks_line=$(sudo grep '^HOOKS=' "$config_file")
if [[ "$hooks_line" == *"plymouth"* ]]; then
    echo "Plymouth is already present in HOOKS."
else
    if [[ "$hooks_line" == *"block"* ]]; then
        sudo sed -i '/^HOOKS=/s/\(.*\)block\(.*\)/\1plymouth block\2/' "$config_file"
    elif [[ "$hooks_line" == *"encrypt"* ]]; then
        sudo sed -i '/^HOOKS=/s/\(.*\)encrypt\(.*\)/\1plymouth encrypt\2/' "$config_file"
    elif [[ "$hooks_line" == *"filesystems"* ]]; then
        sudo sed -i '/^HOOKS=/s/\(.*\)filesystems\(.*\)/\1plymouth filesystems\2/' "$config_file"
    elif [[ "$hooks_line" == *"fsck"* ]]; then
        sudo sed -i '/^HOOKS=/s/\(.*\)fsck\(.*\)/\1plymouth fsck\2/' "$config_file"
    else
        sudo sed -i '/^HOOKS=/s/\(.*\)/\1 plymouth/' "$config_file"
    fi
fi

echo "Checking and installing sddm"
sudo pacman -S --noconfirm sddm

echo "Installing themes"
yay -S --needed --noconfirm plymouth-theme-catppuccin-frappe-git

cd /tmp && git clone https://github.com/catppuccin/grub.git && sudo cp -r grub/src/catppuccin-frappe-grub-theme /boot/grub/themes/ && sudo chown -R root:root /boot/grub/themes/catppuccin-frappe-grub-theme && sudo chmod -R 755 /boot/grub/themes/catppuccin-frappe-grub-theme && rm -rf grub

sudo sed -i 's|^[[:space:]]*GRUB_THEME.*|GRUB_THEME="/boot/grub/themes/catppuccin-frappe-grub-theme/theme.txt"|' /etc/default/grub &&
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo mkinitcpio -P

echo "System cosmetics set!"
sleep 2
