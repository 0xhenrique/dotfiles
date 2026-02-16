#!/bin/bash

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git
# --- Install yay (AUR helper) ---
git clone https://aur.archlinux.org/yay.git
cd yay/
makepkg -si --noconfirm
cd ..
sudo rm -rd yay

sudo sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf

# --- Packages ---
sudo pacman -S --noconfirm neofetch emacs vim ripgrep noto-fonts noto-fonts-extra noto-fonts-emoji noto-fonts-cjk gimp imagemagick orage

yay -S --noconfirm nicotine-plus-git deluge-git feh ttf-aporetic librewolf-bin btop htop nicotine picom mpv nvitop steam ttf-unifontex-mono

