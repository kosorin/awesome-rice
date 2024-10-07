#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Required packages
required_packages=(
  xorg-server
  xorg-xinit
  xorg-xrandr
  xorg-xsetroot
  awesome-git
  pulsemixer
  playerctl
  xdg-utils
  xclip
  nerd-fonts-complete
  alacritty
)

# Optional packages
optional_packages=(
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

# Ask if the user uses an NVIDIA GPU
read -p "Do you use an NVIDIA GPU? (y/n): " use_nvidia

if [[ $use_nvidia == "y" || $use_nvidia == "Y" ]]; then
  # Ask if the user wants proprietary or open-source NVIDIA packages
  read -p "Do you want to install proprietary or open-source NVIDIA packages? (proprietary/open-source): " nvidia_choice

  if [[ $nvidia_choice == "proprietary" ]]; then
    echo -e "${YELLOW}Installing proprietary NVIDIA packages...${NC}"
    sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings
  elif [[ $nvidia_choice == "open-source" ]]; then
    echo -e "${YELLOW}Installing open-source NVIDIA packages...${NC}"
    sudo pacman -S --noconfirm xf86-video-nouveau
  else
    echo -e "${RED}Invalid choice. Skipping NVIDIA packages installation.${NC}"
  fi
fi

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
for package in "${required_packages[@]}"; do
  if yay -Qi $package &> /dev/null; then
    yay -S --noconfirm $package
  else
    sudo pacman -S --noconfirm $package
  fi
done

# Prompt user for optional packages
read -p "Do you want to install optional packages for extra features? (y/n): " install_optional

if [[ $install_optional == "y" || $install_optional == "Y" ]]; then
  echo -e "${YELLOW}Installing optional packages...${NC}"
  for package in "${optional_packages[@]}"; do
    if [[ $package == "luarocks" ]]; then
      sudo pacman -S --noconfirm luarocks
    elif [[ $package == "dkjson" ]]; then
      if ! command -v luarocks &> /dev/null; then
        echo -e "${RED}luarocks is not installed. Skipping dkjson installation.${NC}"
      else
        sudo luarocks install dkjson
      fi
    elif yay -Qi $package &> /dev/null; then
      yay -S --noconfirm $package
    else
      sudo pacman -S --noconfirm $package
    fi
  done
else
  echo -e "${RED}Skipping optional packages installation.${NC}"
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