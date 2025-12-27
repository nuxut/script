#!/bin/bash

set -e

echo "Initializing Nvidia settings"
sleep 2

GPU_MODEL=$(lspci -k -d ::0300 | grep -i "VGA.*NVIDIA" | head -n1)

if [ -z "$GPU_MODEL" ]; then
    echo "NVIDIA GPU not found!"
    exit 0
fi

echo "Detected GPU: $GPU_MODEL"

if echo "$GPU_MODEL" | grep -Eq "GA1[0-9]{2}|AD1[0-9]{2}|RTX (40|30)"; then
    echo "Ada Lovelace or Ampere (RTX 30/40 series) detected"
    DRIVER="nvidia-open"
elif echo "$GPU_MODEL" | grep -Eq "TU1[0-9]{2}|GTX 16|RTX 20"; then
    echo "Turing (GTX 16/RTX 20 series) detected"
    DRIVER="nvidia-open"
elif echo "$GPU_MODEL" | grep -Eq "GP1[0-9]{2}|GM1[0-9]{2}|GTX (10|9)|RTX|Tesla [PTVK]"; then
    echo "Maxwell/Pascal/Volta/Turing detected"
    DRIVER="nvidia"
elif echo "$GPU_MODEL" | grep -Eq "GK1[0-9]{2}|GTX (6|7)"; then
    echo "Kepler detected - AUR required (nvidia-470xx-dkms)"
    DRIVER="aur-470xx"
elif echo "$GPU_MODEL" | grep -Eq "GF1[0-9]{2}|GTX (4|5)"; then
    echo "Fermi detected - AUR required (nvidia-390xx-dkms)"
    DRIVER="aur-390xx"
else
    echo "Legacy GPU detected - No longer supported"
    exit 1
fi

KERNEL=$(uname -r)
if echo "$KERNEL" | grep -q "lts"; then
    KERNEL_TYPE="lts"
else
    KERNEL_TYPE="standard"
fi

# Installation command
case $DRIVER in
    "nvidia-open")
        if [ "$KERNEL_TYPE" = "lts" ]; then
            PACKAGE="nvidia-open-lts"
        else
            PACKAGE="nvidia-open"
        fi
        echo "Installing package: $PACKAGE"
        sudo pacman -S --needed --noconfirm $PACKAGE nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver nvtop xorg-xwayland wayland-protocols nvtop
        ;;
    "nvidia")
        if [ "$KERNEL_TYPE" = "lts" ]; then
            PACKAGE="nvidia-lts"
        else
            PACKAGE="nvidia"
        fi
        echo "Installing package: $PACKAGE"
        sudo pacman -S --needed --noconfirm $PACKAGE nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver nvtop xorg-xwayland wayland-protocols
        ;;
    "aur-470xx")
        echo "Kepler GPU requires AUR package"
        echo "Installing with yay: nvidia-470xx-dkms"
        yay -S --needed --noconfirm nvidia-470xx-dkms nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver nvtop xorg-xwayland wayland-protocols
        ;;
    "aur-390xx")
        echo "Fermi GPU requires AUR package"
        echo "Installing with yay: nvidia-390xx-dkms"
        yay -S --needed --noconfirm nvidia-390xx-dkms nvidia-utils nvidia-settings lib32-nvidia-utils libva-nvidia-driver nvtop xorg-xwayland wayland-protocols
        ;;
esac

echo "Putting nvidia system modules"
sleep 2
MODULES=("i915" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
FILE="/etc/mkinitcpio.conf"
for MODULE in "${MODULES[@]}"; do
  if ! grep -q "MODULES=.*$MODULE" "$FILE"; then
    sudo sed -i "/^MODULES=/ s/(\(.*\))/(\1 $MODULE)/" "$FILE"
  fi
done
echo "All modules:"
grep "^MODULES=" "$FILE" | sed 's/^MODULES=(//;s/)//'
sleep 2
echo "Enabling changes with initramfs"
sudo mkinitcpio -P

echo "Adding Nvidia module settings"
CONF_FILE="/etc/modprobe.d/nvidia.conf"
LINE="options nvidia_drm modeset=1 fbdev=1"
if [ ! -f "$CONF_FILE" ]; then
  echo "$CONF_FILE module settings empty, creating now"
  sudo touch "$CONF_FILE"
fi
if ! grep -q "$LINE" "$CONF_FILE"; then
  echo "$LINE" | sudo tee -a "$CONF_FILE" > /dev/null
  echo "Added line: $LINE"
else
  echo "Line already exists"
fi
sleep 1

echo "Adding Nvidia environment variables"
ENV_FILE="/etc/environment"
GBM_VAR="GBM_BACKEND=nvidia-drm"
GLX_VAR="__GLX_VENDOR_LIBRARY_NAME=nvidia"
if [ ! -f "$ENV_FILE" ]; then
  sudo touch "$ENV_FILE"
fi
if ! grep -q "$GBM_VAR" "$ENV_FILE"; then
  echo "$GBM_VAR" | sudo tee -a "$ENV_FILE" > /dev/null
fi

if ! grep -q "$GLX_VAR" "$ENV_FILE"; then
  echo "$GLX_VAR" | sudo tee -a "$ENV_FILE" > /dev/null
fi
echo "Added needed Nvidia environment variables"
sleep 1

echo "Configuring Grup settings for Nvidia"
sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ { /nvidia\.NVreg_PreserveVideoMemoryAllocations=1/! s/"$/ nvidia.NVreg_PreserveVideoMemoryAllocations=1"/ }' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sleep 1

echo "Enabling Nvidia suspend settings"
sudo systemctl enable nvidia-suspend.service
sudo systemctl enable nvidia-hibernate.service
sudo systemctl enable nvidia-resume.service

echo "Nvidia system settings set completely!"
sleep 2
