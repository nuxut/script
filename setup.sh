#!/bin/bash
set -e

export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

export NC='\033[0m'  

echo -e "${CYAN}:: Initializing Nuxut Script Installation...${NC}"
sleep 3

# Getting sudo privilages once
echo -e "${RED}:: This process requires sudo privileges. Please enter your password:${NC}"

set +e
sudo -v
SUDO_STATUS=$?
set -e

if [ $SUDO_STATUS -ne 0 ]; then
    echo -e "${RED}Authentication failed after maximum attempts! Installation aborted.${NC}"
    exit 1
fi

(while true; do sudo -v; sleep 60; done) &
SUDO_PID=$!

trap 'kill $SUDO_PID 2>/dev/null' EXIT

echo -e "${GREEN}:: Privileges granted, proceeding with installation...${NC}"
sleep 1



echo -e "${GREEN}:: Starting Nuxut installation!${NC}"
for i in {5..1}; do
    echo "$i..."
    sleep 1
done
echo -e "${GREEN}:: Installation started...${NC}"
sleep 1


# Define Cache Directory
export CACHE_DIR="$HOME/.cache/nuxut-script"

# Install Git if missing
if ! command -v git &> /dev/null; then
    echo -e "${CYAN} Installing git...${NC}"
    if [ -f /etc/arch-release ]; then
        sudo pacman -S --noconfirm git
    else
        echo "Error: Git is missing and this is not Arch Linux. Please install git manually."
        exit 1
    fi
fi

# Prepare Cache Directory
echo -e "${CYAN}:: Preparing cache directory: ${CACHE_DIR}${NC}"
mkdir -p "$CACHE_DIR"

# Clone or Update Repository
if [ -d "$CACHE_DIR/.git" ]; then
    echo -e "${CYAN}::Updating repository....${NC}"
    cd "$CACHE_DIR"
    git fetch --all
    git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)
    git clean -fd
else
    echo -e "${CYAN}:: Installing repository...${NC}"
    rm -rf "$CACHE_DIR"
    git clone https://github.com/nuxut/script "$CACHE_DIR"
    cd "$CACHE_DIR"
fi

# Make scripts executable
echo -e "${CYAN}:: Setting permissions...${NC}"
find . -type f -name "*.sh" -exec chmod +x {} \;

# Execute Scripts
echo -e "${CYAN}:: Starting installation sequence...${NC}"

./Scripts/initial.sh
./Scripts/nvidia.sh
./Scripts/amd.sh
./Scripts/firewall.sh

./Scripts/hyprland.sh
./Scripts/appinstalls.sh

./Scripts/fastfetch.sh
./Scripts/systemcosmetics.sh
./Scripts/cursorset.sh
./Scripts/themes.sh

echo "Installing nuxut-shell..."
sleep 3
curl -s https://raw.githubusercontent.com/nuxut/shell/main/setup.sh | bash


echo -e "${GREEN}:: Installation finished! Starting Hyprland!${NC}"
for i in {5..1}; do
    echo "$i..."
    sleep 1
done
echo "Good luck!"
sleep 1

if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    echo "You are already in a graphical session. Please log out and select Hyprland."
else
    exec Hyprland
fi
