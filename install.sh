#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# All optional packages (merged from required and optional)
packages=(
  xorg-server
  xorg-xinit
  xorg-xrandr
  xorg-xsetroot
  awesome-git
  pulsemixer
  playerctl
  xdg-utils
  xclip
  alacritty
  feh
  luarocks
  dkjson
  xdotool
  slop
  sct
  rofi
  picom
)

# Packages that need to be installed via yay
yay_packages=(
  nerd-fonts-complete
)

# Check if yay is installed
if ! command -v yay &> /dev/null; then
  echo -e "${RED}yay is not installed. Please install yay first.${NC}"
  exit 1
fi

# Check if curl or wget is installed
if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
  echo -e "${RED}Neither curl nor wget is installed. Please install one of them first.${NC}"
  exit 1
fi

# Update package list
echo -e "${YELLOW}Updating package list...${NC}"
sudo pacman -Syu --noconfirm

# Prompt user for each package installation
for package in "${packages[@]}"; do
  read -p "Do you want to install $package? (y/n): " install_package
  if [[ $install_package == "y" || $install_package == "Y" ]]; then
    if yay -Qi $package &> /dev/null; then
      yay -S --noconfirm $package
    else
      sudo pacman -S --noconfirm $package
    fi
  else
    echo -e "${RED}Skipping $package installation.${NC}"
  fi
done

# Ask the user if they want to install yay-specific packages
read -p "Do you want to install yay-specific packages (e.g., nerd-fonts-complete)? (y/n): " install_yay_packages

if [[ $install_yay_packages == "y" || $install_yay_packages == "Y" ]]; then
  echo -e "${YELLOW}Installing yay-specific packages...${NC}"
  for package in "${yay_packages[@]}"; do
    yay -S --noconfirm $package
  done
else
  echo -e "${RED}Skipping yay-specific packages installation.${NC}"
fi

# Ask if the user wants to install the rofi and picom rice
read -p "Do you want to install the rofi and picom rice? (y/n): " install_rice

if [[ $install_rice == "y" || $install_rice == "Y" ]]; then
  echo -e "${YELLOW}Installing rofi and picom rice...${NC}"
  sudo pacman -S --noconfirm rofi picom

  # Create config directories if they don't exist
  mkdir -p ~/.config/picom
  mkdir -p ~/.config/rofi

  # Download and place the configuration files
  if command -v curl &> /dev/null; then
    curl -o ~/.config/picom/picom.conf https://gist.githubusercontent.com/kosorin/a1a7690f6e2ad44baf67f99617b6799f/raw/cc582dca06dce52a90ab3fd9fbb96adb2fbc9b92/picom.conf
    curl -o ~/.config/rofi/config.rasi https://gist.githubusercontent.com/kosorin/2e613eb2e09f4f619b3f9f6c3c688c6b/raw/ff55bb3d6710e091da29e87197b2f6f0cc1e3e89/config.rasi
    curl -o ~/.config/rofi/theme.rasi https://gist.githubusercontent.com/kosorin/2e613eb2e09f4f619b3f9f6c3c688c6b/raw/ff55bb3d6710e091da29e87197b2f6f0cc1e3e89/theme.rasi
  elif command -v wget &> /dev/null; then
    wget -O ~/.config/picom/picom.conf https://gist.githubusercontent.com/kosorin/a1a7690f6e2ad44baf67f99617b6799f/raw/cc582dca06dce52a90ab3fd9fbb96adb2fbc9b92/picom.conf
    wget -O ~/.config/rofi/config.rasi https://gist.githubusercontent.com/kosorin/2e613eb2e09f4f619b3f9f6c3c688c6b/raw/ff55bb3d6710e091da29e87197b2f6f0cc1e3e89/config.rasi
    wget -O ~/.config/rofi/theme.rasi https://gist.githubusercontent.com/kosorin/2e613eb2e09f4f619b3f9f6c3c688c6b/raw/ff55bb3d6710e091da29e87197b2f6f0cc1e3e89/theme.rasi
  fi
else
  echo -e "${RED}Skipping rofi and picom rice installation.${NC}"
fi

# Copy all files from ~/arise to ~/.config/awesome and create the directory if it doesn't exist
echo -e "${YELLOW}Copying files from ~/arise to ~/.config/awesome...${NC}"
mkdir -p ~/.config/awesome
cp -r ~/arise/* ~/.config/awesome

echo -e "${GREEN}Installation complete!${NC}"
