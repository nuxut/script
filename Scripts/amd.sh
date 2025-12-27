#!/bin/bash

set -e

echo "Initializing AMD settings"
sleep 3

if ! sudo lspci -k | grep -i "VGA\|3D\|Display" | grep -iq "AMD\|ATI"; then
    echo "AMD GPU not found"
    exit 0
fi

GPU_INFO=$(sudo lspci -k | grep -i "VGA\|3D\|Display" | grep -i "AMD\|ATI")
echo "Found AMD GPU:"
echo "$GPU_INFO"

sleep 1

GPU_PRODUCT=$(sudo lspci -nn | grep -i "VGA\|3D\|Display" | grep -i "AMD\|ATI")
NEEDS_SI_CIK=false

if echo "$GPU_PRODUCT" | grep -iq "Oland\|Cape Verde\|Pitcairn\|Tahiti\|Hainan"; then
    echo "Detected Southern Islands (SI) GPU - GCN 1"
    NEEDS_SI_CIK=true
    GPU_TYPE="SI"
elif echo "$GPU_PRODUCT" | grep -iq "Bonaire\|Hawaii\|Kabini\|Kaveri\|Mullins"; then
    echo "Detected Sea Islands (CIK) GPU - GCN 2"
    NEEDS_SI_CIK=true
    GPU_TYPE="CIK"
else
    echo "Detected newer AMD GPU (GCN 3 or later)"
fi

echo "Installing required packages"
sudo pacman -S --needed --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
echo "Packages installed"

if [ "$NEEDS_SI_CIK" = true ]; then
    echo "Configuring $GPU_TYPE support"

    sudo mkdir -p /etc/modprobe.d

    if [ "$GPU_TYPE" = "SI" ]; then
        echo "options amdgpu si_support=1" | sudo tee /etc/modprobe.d/amdgpu.conf > /dev/null
        echo "options radeon si_support=0" | sudo tee /etc/modprobe.d/radeon.conf > /dev/null
        KERNEL_PARAMS="radeon.si_support=0 amdgpu.si_support=1"
    else
        echo "options amdgpu cik_support=1" | sudo tee /etc/modprobe.d/amdgpu.conf > /dev/null
        echo "options radeon cik_support=0" | sudo tee /etc/modprobe.d/radeon.conf > /dev/null
        KERNEL_PARAMS="radeon.cik_support=0 amdgpu.cik_support=1"
    fi

    echo "Modprobe configuration created"

    echo "Updating mkinitcpio configuration"
    if ! grep -q "^MODULES=(.*amdgpu" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(amdgpu radeon \1)/' /etc/mkinitcpio.conf
    fi

    if ! grep -q "modconf" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^HOOKS=(\(.*\)base/HOOKS=(\1base modconf/' /etc/mkinitcpio.conf
    fi

    echo "Regenerating initramfs"
    sudo mkinitcpio -P
else
    echo "Enabling early KMS"
    if ! grep -q "^MODULES=(.*amdgpu" /etc/mkinitcpio.conf; then
        sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(amdgpu \1)/' /etc/mkinitcpio.conf
        echo "Regenerating initramfs"
        sudo mkinitcpio -P
    fi
fi

sleep 1
echo "AMD configuration completed!"
sleep 2
