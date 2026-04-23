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

  fileSystems."/sirius" = {
    device = "/dev/disk/by-uuid/FE6E7F996E7F4A03";
    fsType = "ntfs";
    options = ["nofail" "x-systemd.device-timeout=10s" "uid=1000" "gid=100" "dmask=022" "fmask=133"];
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

    displayManager.lightdm.enable = true;

    desktopManager = {
      xterm.enable = true;
      xfce.enable = true;
    };
  };

  services.udisks2.enable = true;
  services.displayManager.defaultSession = "xfce";
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
    git wget curl htop btop neofetch librewolf emacs flameshot
    ripgrep direnv xfce.thunar nvitop aporetic picom
    unzip zip fd flameshot yt-dlp deluge mpv gimp nicotine-plus feh
    rhythmbox xdg-desktop-portal-gtk ffmpeg krita opentabletdriver gcc clang
    pkg-config gnumake cmake clang-tools lxappearance claude-code
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-serif
   ];

  programs.steam = {
    enable = true;
  };

  programs.i3lock.enable = true;
  programs.dconf.enable = true;

  system.stateVersion = "25.11";
}
