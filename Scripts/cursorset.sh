#!/bin/bash

echo "Initializing cursor settings..."
CURSOR_THEME="Vimix-cursors"
CURSOR_SIZE=24

sudo pacman -S --noconfirm --needed vimix-cursors

# This fixes apps that don't respect GTK or Xresources
echo "Creating icon theme fallback..."
mkdir -p ~/.icons/default
cat <<EOF > ~/.icons/default/index.theme
[Icon Theme]
Inherits=$CURSOR_THEME
EOF

echo "Configuring GTK 2, 3, and 4..."
echo "gtk-cursor-theme-name=\"$CURSOR_THEME\"" > ~/.gtkrc-2.0

mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
cat <<EOF > ~/.config/gtk-3.0/settings.ini
[Settings]
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
EOF
cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

echo "Updating Xresources..."
touch ~/.Xresources
sed -i '/Xcursor.theme/d' ~/.Xresources
sed -i '/Xcursor.size/d' ~/.Xresources
echo "Xcursor.theme: $CURSOR_THEME" >> ~/.Xresources
echo "Xcursor.size: $CURSOR_SIZE" >> ~/.Xresources
xrdb -merge ~/.Xresources

gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"

if command -v hyprctl &> /dev/null; then
    hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE"
    echo "Hyprctl cursor updated."
fi

if command -v flatpak &> /dev/null; then
    echo "Applying Flatpak overrides..."
    flatpak override --user --filesystem=/usr/share/icons:ro
    flatpak override --user --env=XCURSOR_THEME="$CURSOR_THEME"
    flatpak override --user --env=XCURSOR_SIZE="$CURSOR_SIZE"
fi

echo "Cursor set completed."
sleep 2
