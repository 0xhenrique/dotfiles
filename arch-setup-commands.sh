#!/bin/bash

sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git
# --- Install yay (AUR helper) ---
git clone https://aur.archlinux.org/yay.git
cd yay/
makepkg -si --noconfirm
cd ..
sudo rm -rd yay

# --- Packages ---
sudo pacman -S --noconfirm neofetch emacs vim
yay -S --noconfirm nicotine-plus-git deluge-git feh ttf-aporetic librewolf-bin
