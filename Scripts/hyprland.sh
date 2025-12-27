#!/bin/bash

echo "Initializing hyprland"
sleep 3

echo "Installing hyprland and sddm"
sudo pacman -S --needed --noconfirm hyprland sddm hyprlock dunst pipewire wireplumber xdg-desktop-portal-hyprland qt5-wayland qt6-wayland hyprpolkitagent

echo "Setting sddm"
sleep 1

echo "Moving config files"
mkdir -p ~/.config/hypr/configs/custom
touch ~/.config/hypr/configs/custom/env.conf \
      ~/.config/hypr/configs/custom/gpu.conf \
      ~/.config/hypr/configs/custom/execs.conf \
      ~/.config/hypr/configs/custom/general.conf \
      ~/.config/hypr/configs/custom/rules.conf \
      ~/.config/hypr/configs/custom/keybinds.conf

cp -r $CACHE_DIR/Scripts/Assets/config/* ~/.config/

CONFIG_FILE="$HOME/.config/hypr/configs/custom/general.conf"
XKB_SYMBOLS_DIR="/usr/share/X11/xkb/symbols"

LAYOUT_RAW=$(localectl status | grep "X11 Layout" | awk '{print $3}')

if [ -n "$LAYOUT_RAW" ]; then
    TARGET_LAYOUT="${LAYOUT_RAW:0:2}"
    echo "System layout detected: $LAYOUT_RAW. Using short code: $TARGET_LAYOUT"
else
    echo "No system layout detected. Searching for fallback..."
    TARGET_LAYOUT="tr"
fi

if [ -f "$XKB_SYMBOLS_DIR/$TARGET_LAYOUT" ]; then
    echo "Layout '$TARGET_LAYOUT' verified in X11 symbols."
    FINAL_LAYOUT="$TARGET_LAYOUT"
else
    echo "Layout '$TARGET_LAYOUT' not found in $XKB_SYMBOLS_DIR. Falling back to 'us'."
    FINAL_LAYOUT="us"
fi

if ! grep -q "kb_layout" "$CONFIG_FILE"; then
    echo "No 'kb_layout' found in config. Adding: $FINAL_LAYOUT"
    cat <<EOF >> "$CONFIG_FILE"
input {
    kb_layout = $FINAL_LAYOUT
}
EOF
    echo "Configuration updated successfully."
else
    echo "kb_layout already exists in $CONFIG_FILE. No changes made."
fi

GPU_MODEL=$(lspci -k -d ::0300 | grep -i "VGA.*NVIDIA" | head -n1)

if [ -z "$GPU_MODEL" ]; then
    echo "NVIDIA GPU not found! Skipping Nvidia config for hyprland..."
else
    echo "NVIDIA GPU detected. Checking environment variables..."
        declare -a ENVS=(
            "env = NVD_BACKEND,direct"
            "env = LIBVA_DRIVER_NAME,nvidia"
            "env = XDG_SESSION_TYPE,wayland"
            "env = GBM_BACKEND,nvidia-drm"
            "env = __GLX_VENDOR_LIBRARY_NAME,nvidia"
            "env = WLR_NO_HARDWARE_CURSORS,1"
        )
        for line in "${ENVS[@]}"; do
            var_name=$(echo "$line" | cut -d',' -f1)
            if grep -qF "$var_name" "$HYPR_CONF"; then
                echo "Skipping: '$var_name' already exists in config."
            else
                echo "Adding: '$line'"
                echo "$line" >> "$HYPR_CONF"
            fi
        done
        echo "Nvidia environment variables check complete."
fi

sudo pacman -S --needed --noconfirm sddm
yay -S --needed --noconfirm catppuccin-sddm-theme-frappe

[ -f /etc/sddm.conf ] && sudo rm /etc/sddm.conf

sudo sh -c "cat > /etc/sddm.conf << EOF
[Autologin]
User=$USER
Session=hyprland

[Theme]
Current=catppuccin-frappe-sapphire
EOF"

sudo systemctl enable --now sddm
echo "Hyprland installiation complete"
sleep 2
