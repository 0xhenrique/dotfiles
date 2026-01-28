{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  environment.pathsToLink = [ "/libexec" ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Lisbon";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT    = "pt_PT.UTF-8";
    LC_MONETARY       = "pt_PT.UTF-8";
    LC_NAME           = "pt_PT.UTF-8";
    LC_NUMERIC        = "pt_PT.UTF-8";
    LC_PAPER          = "pt_PT.UTF-8";
    LC_TELEPHONE      = "pt_PT.UTF-8";
    LC_TIME           = "pt_PT.UTF-8";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-label/DATA";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  fileSystems."/rigel" = {
    device = "/dev/disk/by-label/rigel";
    fsType = "ext4";
    options = ["nofail" "x-systemd.device-timeout=10s"];
  };

  # FUCK YOU NVIDIA!
  nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    open = true;
  };

  services.libinput.enable = true;

  services.xserver = {
    enable = true;

    xkb.layout = "us, br";
    xkb.variant = "";
    xkb.options = "grp:win_space_toggle";

    desktopManager.xterm.enable = false;
    windowManager.exwm.enable = false;

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3blocks
     ];
    };
  };

  services.udisks2.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "none+i3";
  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.wired = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "1234";
  };

  environment.systemPackages = with pkgs; [
    vim git wget curl htop neofetch librewolf kitty emacs flameshot
    fzf ripgrep direnv xfce.thunar nodejs_24 nvitop guix aporetic picom
    unzip zip fd flameshot yt-dlp deluge mpv btop gimp nicotine-plus feh
    rhythmbox xdg-desktop-portal-gtk ffmpeg krita opentabletdriver gcc clang
    pkg-config gnumake cmake clang-tools parted lxappearance hydralauncher heroic
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-serif
    iosevka-comfy.comfy
  ];

  programs.steam = {
    enable = true;
  };

  programs.i3lock.enable = true;
  programs.dconf.enable = true;

  system.stateVersion = "25.11";
}
