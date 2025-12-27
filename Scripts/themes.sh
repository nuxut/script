#!/bin/bash

set -e

echo "Initializing theming..."
sleep 3

echo "Installing core packages and AUR dependencies..."
sudo pacman -S --needed --noconfirm starship qt5ct qt6ct kvantum papirus-icon-theme kitty wget unzip

yay -S --needed --noconfirm dracula-gtk-theme-full papirus-folders-catppuccin-git

mkdir -p ~/.config/fuzzel ~/.config/zed ~/.config/Kvantum ~/.config/qt5ct ~/.config/qt6ct ~/.config/fish ~/.config/kitty

echo "Setting Papirus folders to Catppuccin Sapphire..."
sudo papirus-folders -C cat-frappe-sapphire --theme Papirus-Dark

echo "Configuring Fuzzel..."
cat <<EOF > ~/.config/fuzzel/fuzzel.ini
[main]
font=sans:size=12
prompt="❯ "
layer=overlay

[colors]
background=303446ff
text=c6d0f5ff
match=85c1dcff
selection=414559ff
selection-match=85c1dcff
selection-text=c6d0f5ff
border=85c1dcff
EOF

echo "Configuring Zed Editor and Icons..."
cat <<EOF > ~/.config/zed/settings.json
{
  "theme": "Catppuccin Frappé",
  "icon_theme": "Catppuccin Frappé",
  "ui_font_size": 16,
  "buffer_font_size": 14
}
EOF

echo "Installing Kvantum Frappé Sapphire theme files..."
rm -rf /tmp/catppuccin-kvantum
git clone https://github.com/catppuccin/Kvantum.git /tmp/catppuccin-kvantum
mkdir -p ~/.config/Kvantum
cp -r /tmp/catppuccin-kvantum/themes/catppuccin-frappe-sapphire ~/.config/Kvantum/

echo "Applying Kvantum Sapphire config..."
echo "theme=Catppuccin-Frappe-Sapphire" > ~/.config/Kvantum/kvantum.kvconfig

echo "Configuring Qt5 and Qt6 to use Kvantum engine..."
for conf in ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf; do
    if [ -f "$conf" ]; then
        sed -i '/^style=/d' "$conf"
        sed -i '/\[Appearance\]/a style=kvantum' "$conf"
    else
        echo -e "[Appearance]\nstyle=kvantum" > "$conf"
    fi
done

echo "Configuring Kitty with Frappé Sapphire and Cursor Trail..."
cat <<EOF > ~/.config/kitty/kitty.conf
# Catppuccin-Frappe-Sapphire
foreground              #c6d0f5
background              #303446
selection_foreground    #303446
selection_background    #f2d5cf
cursor                  #85c1dc
cursor_text_color       #303446
url_color               #f2d5cf
active_border_color     #babbf1
inactive_border_color   #737994
bell_border_color       #e5c890
wayland_titlebar_color  system
macos_titlebar_color    system

active_tab_foreground   #232634
active_tab_background   #ca9ee6
inactive_tab_foreground #c6d0f5
inactive_tab_background #292c3c
tab_bar_background      #232634

# Colors for marks (marked text in the terminal)
mark1_foreground #303446
mark1_background #babbf1
mark2_foreground #303446
mark2_background #ca9ee6
mark3_foreground #303446
mark3_background #81c8be

# The 16 terminal colors
color0 #51576d
color8 #626880
color1 #e78284
color9 #e78284
color2 #a6d189
color10 #a6d189
color3 #e5c890
color11 #e5c890
color4 #8caaee
color12 #8caaee
color5 #f4b8e4
color13 #f4b8e4
color6 #81c8be
color14 #81c8be
color7 #b5bfe2
color15 #a5adce

# --- Cursor Trail Configuration ---
cursor_trail 1
cursor_trail_duration 0.1
cursor_trail_start_threshold 2
EOF

echo "Configuring Starship with Sapphire palette..."
cat <<EOF > ~/.config/starship.toml
palette = "catppuccin_frappe"

[character]
success_symbol = "[❯](bold sapphire)"
error_symbol = "[❯](bold red)"
vicmd_symbol = "[❮](bold sapphire)"

[directory]
style = "bold sapphire"

[git_branch]
symbol = " "
style = "bold sapphire"

[palettes.catppuccin_frappe]
rosewater = "#f2d5cf"
flamingo = "#eebebe"
pink = "#f4b8e4"
mauve = "#ca9ee6"
red = "#e78284"
maroon = "#ea999c"
peach = "#ef9f76"
yellow = "#e5c890"
green = "#a6d189"
teal = "#81c8be"
sky = "#99d1db"
sapphire = "#85c1dc"
blue = "#8caaee"
lavender = "#babbf1"
text = "#c6d0f5"
subtext1 = "#b5bfe2"
subtext0 = "#a5adce"
overlay2 = "#949cbb"
overlay1 = "#838ba7"
overlay0 = "#737994"
surface2 = "#626880"
surface1 = "#51576d"
surface0 = "#414559"
base = "#303446"
mantle = "#292c3c"
crust = "#232634"
EOF

if ! grep -q "starship init bash" ~/.bashrc; then
    echo "Integrating Starship with Bash..."
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
fi

if command -v fish &> /dev/null; then
    echo "Fish shell detected. Integrating Starship..."
    mkdir -p ~/.config/fish
    if ! grep -q "starship init fish" ~/.config/fish/config.fish 2>/dev/null; then
        echo 'starship init fish | source' >> ~/.config/fish/config.fish
    fi
fi

echo "Themes applied!"
sleep 2
