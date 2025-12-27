#!/bin/bash

echo "Initializing theming..."
sleep 2

# Install dependencies if missing (only what's necessary)
packages="starship qt5ct qt6ct kvantum papirus-icon-theme kitty wget unzip git ttf-ubuntu-nerd ttf-cascadia-code-nerd"
for pkg in $packages; do
    if ! pacman -Q $pkg &> /dev/null; then
        echo "Installing $pkg..."
        sudo pacman -S --noconfirm --needed $pkg
    fi
done

aur_packages="papirus-folders-catppuccin-git darkly-git"
for pkg in $aur_packages; do
    if ! pacman -Q $pkg &> /dev/null; then
        echo "Installing AUR package $pkg..."
        yay -S --noconfirm --needed $pkg
    fi
done

# Create config directories
# CLEAN SLATE: Wipe existing configs to prevent conflicts
echo "Wiping existing theme configs for clean install..."
rm -rf ~/.config/gtk-3.0 ~/.config/gtk-4.0 ~/.config/qt5ct ~/.config/qt6ct ~/.config/Kvantum

mkdir -p ~/.config/fuzzel ~/.config/zed ~/.config/Kvantum ~/.config/qt5ct/colors ~/.config/qt6ct/colors ~/.config/fish ~/.config/kitty ~/.themes ~/.local/share/themes ~/.config/gtk-3.0 ~/.config/gtk-4.0

# Apply Papirus folders
sudo papirus-folders -C cat-frappe-sapphire --theme Papirus-Dark

# Fuzzel
cat <<EOF > ~/.config/fuzzel/fuzzel.ini
[main]
font=Ubuntu Nerd Font Propo:style=Medium:size=12
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

# Zed
cat <<EOF > ~/.config/zed/settings.json
{
  "theme": "Catppuccin Frappé",
  "icon_theme": "Catppuccin Frappé",
  "ui_font_size": 16,
  "buffer_font_size": 14,
  "buffer_font_family": "CaskaydiaCove Nerd Font",
  "ui_font_family": "Ubuntu Nerd Font Propo"
}
EOF

# Kvantum
echo "Installing Kvantum theme..."
rm -rf /tmp/catppuccin-kvantum
git clone --depth 1 https://github.com/catppuccin/Kvantum.git /tmp/catppuccin-kvantum
KVANTUM_THEME_DIR=$(find /tmp/catppuccin-kvantum -type d -iname "catppuccin-frappe-sapphire" -print -quit)
if [ -d "$KVANTUM_THEME_DIR" ]; then
    cp -r "$KVANTUM_THEME_DIR" ~/.config/Kvantum/
    echo "theme=catppuccin-frappe-sapphire" > ~/.config/Kvantum/kvantum.kvconfig
else
    echo "Error: Kvantum Sapphire theme not found in clone! (Checked for 'catppuccin-frappe-sapphire')"
fi

# GTK Theme
echo "Installing GTK theme..."
rm -rf /tmp/catppuccin-gtk
git clone --depth 1 https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git /tmp/catppuccin-gtk

# Run GTK theme installer
chmod +x /tmp/catppuccin-gtk/themes/install.sh

# Force clean reset of GTK4 config to avoid stubborn old themes
rm -rf ~/.config/gtk-4.0
mkdir -p ~/.config/gtk-4.0

/tmp/catppuccin-gtk/themes/install.sh -d ~/.themes --tweaks frappe -t all -c dark

# Set the name explicitly as requested/generated
GTK_THEME_NAME="Catppuccin-Sapphire-Dark-Frappe"
    
# Ensure local share exists for some apps
mkdir -p ~/.local/share/themes
cp -r ~/.themes/"$GTK_THEME_NAME" ~/.local/share/themes/

# Copy for GTK4
echo "Copying GTK4 theme assets..."
mkdir -p ~/.config/gtk-4.0
cp -r ~/.themes/"$GTK_THEME_NAME"/gtk-4.0/gtk.css ~/.config/gtk-4.0/
cp -r ~/.themes/"$GTK_THEME_NAME"/gtk-4.0/gtk-dark.css ~/.config/gtk-4.0/
cp -r ~/.themes/"$GTK_THEME_NAME"/gtk-4.0/assets ~/.config/gtk-4.0/

# Apply Settings
echo "Applying GTK settings for $GTK_THEME_NAME..."
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface font-name "Ubuntu Nerd Font Propo Medium 11"
gsettings set org.gnome.desktop.interface monospace-font-name "CaskaydiaCove Nerd Font 11"

# Write settings.ini files
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Ubuntu Nerd Font Propo Medium 11
gtk-application-prefer-dark-theme=1
EOF

cat <<EOF > ~/.config/gtk-4.0/settings.ini
[Settings]
gtk-theme-name=$GTK_THEME_NAME
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Ubuntu Nerd Font Propo Medium 11
gtk-application-prefer-dark-theme=1
EOF

# Qt
echo "Configuring Qt..."
wget -O ~/.config/qt5ct/colors/catppuccin-frappe-sapphire.conf https://raw.githubusercontent.com/catppuccin/qt5ct/main/themes/catppuccin-frappe-sapphire.conf
cp ~/.config/qt5ct/colors/catppuccin-frappe-sapphire.conf ~/.config/qt6ct/colors/

# Force configuration
for conf in ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf; do
    mkdir -p "$(dirname "$conf")"
    cat <<CONF_EOF > "$conf"
[Appearance]
style=Darkly
custom_palette=true
standard_dialogs=default
color_scheme_path=$HOME/.config/$(basename $(dirname "$conf"))/colors/catppuccin-frappe-sapphire.conf
font="Ubuntu Nerd Font Propo,11,-1,5,50,0,0,0,0,0,Medium"
fixed_font="CaskaydiaCove Nerd Font,11,-1,5,50,0,0,0,0,0"
CONF_EOF
done

# Ensure environment variables are set
for rc in ~/.bashrc ~/.profile; do
    # Switch from qt5ct to qt6ct if present
    if grep -q "QT_QPA_PLATFORMTHEME=qt5ct" "$rc"; then
         sed -i 's/QT_QPA_PLATFORMTHEME=qt5ct/QT_QPA_PLATFORMTHEME=qt6ct/' "$rc"
    fi
    if ! grep -q "QT_QPA_PLATFORMTHEME" "$rc"; then
        echo 'export QT_QPA_PLATFORMTHEME=qt6ct' >> "$rc"
    fi
    
    if ! grep -q "GTK_THEME=" "$rc"; then
        echo "export GTK_THEME=$GTK_THEME_NAME" >> "$rc"
    else
        sed -i "s/GTK_THEME=.*/GTK_THEME=$GTK_THEME_NAME/" "$rc"
    fi
done

if command -v fish &> /dev/null; then
    mkdir -p ~/.config/fish
    if grep -q "QT_QPA_PLATFORMTHEME qt5ct" ~/.config/fish/config.fish; then
         sed -i 's/QT_QPA_PLATFORMTHEME qt5ct/QT_QPA_PLATFORMTHEME qt6ct/' ~/.config/fish/config.fish
    fi

    if ! grep -q "QT_QPA_PLATFORMTHEME" ~/.config/fish/config.fish 2>/dev/null; then
        echo 'set -gx QT_QPA_PLATFORMTHEME qt6ct' >> ~/.config/fish/config.fish
    fi
    
    if ! grep -q "GTK_THEME" ~/.config/fish/config.fish 2>/dev/null; then
        echo "set -gx GTK_THEME $GTK_THEME_NAME" >> ~/.config/fish/config.fish
    else
         sed -i "s/set -gx GTK_THEME .*/set -gx GTK_THEME $GTK_THEME_NAME/" ~/.config/fish/config.fish
    fi
fi

# Kitty
cat <<EOF > ~/.config/kitty/kitty.conf
font_family      CaskaydiaCove Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        12

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

mark1_foreground #303446
mark1_background #babbf1
mark2_foreground #303446
mark2_background #ca9ee6
mark3_foreground #303446
mark3_background #81c8be

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

cursor_trail 1
cursor_trail_duration 0.1
cursor_trail_start_threshold 2
EOF

# Starship
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
    echo 'eval "$(starship init bash)"' >> ~/.bashrc
fi

echo "Themes configured."
