{ config, pkgs, ... }:

let
  unstable = import <nixpkgs-unstable> {};
in

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
  ];

  networking.hostName = "xps";

  hardware.cpu.intel.updateMicrocode = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."pool" =
    { device = "/dev/disk/by-partlabel/pool";
      allowDiscards = true;
    };

  fileSystems."/" =
    { device = "/dev/mapper/pool";
      fsType = "btrfs";
      options = [ "subvol=/nixfs" ];
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-partlabel/efi";
      fsType = "vfat";
    };
  fileSystems."/home/ben" =
    { device = "/dev/mapper/pool";
      fsType = "btrfs";
      options = [ "subvol=/benfs" ];
    };
  fileSystems."/data" =
    { device = "/dev/mapper/pool";
      fsType = "btrfs";
      options = [ "subvol=/datafs" ];
    };
  fileSystems."/pool" =
    { device = "/dev/mapper/pool";
      fsType = "btrfs";
      options = [ "subvol=/" ];
    };

  services.snapper.configs = {
    "benfs" = {
      subvolume = "/pool/benfs";
      extraConfig = ''
        TIMELINE_CREATE="yes"
        TIMELINE_CLEANUP="yes"
      '';
    };
    "datafs" = {
      subvolume = "/pool/datafs";
      extraConfig = ''
        TIMELINE_CREATE="yes"
        TIMELINE_CLEANUP="yes"
      '';
    };
  };

  services.fstrim.enable = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/London";

  environment.systemPackages = (with pkgs; [
    awscli
    chromium
    file
    firefox
    freerdp
    gitAndTools.git-annex
    gptfdisk
    imagemagick
    jq
    libjpeg # jpegtran
    pass
    poppler_utils # pdfimages
    ranger
    rmlint
    rxvt_unicode
    sxiv
    unzip
    usbutils # lsusb
    vpnc
    watchexec
    xorg.xwininfo
    zathura
  ]) ++ (with unstable.pkgs; [
    img2pdf # not available in stable
    terraform
  ]);

  fonts.fonts = with pkgs; [
    iosevka
    font-awesome_4
  ];

  services.xserver = {
    enable = true;
    autorun = true;

    displayManager.lightdm.enable = true;

    desktopManager.xterm.enable = false;

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        i3lock
        i3status
        jq
        xorg.xbacklight
        xss-lock
      ];
    };
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplip
    ];
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.libinput = {
    enable = true;
    tapping = false;
    clickMethod = "clickfinger";
    naturalScrolling = true;
  };

  services.xserver.config = ''
    # Internal keyboard has a right ctrl but no right win
    # Swap them, because having a right win is more useful for i3
    Section "InputClass"
      Identifier "Internal Keyboard"
      Driver "libinput"
      MatchProduct "AT Translated Set 2 keyboard"
      Option "XkbOptions" "ctrl:swap_rwin_rctl"
    EndSection

    # Workaround for broken middle mouse button
    # Disable middle button 2 and use side button 9 in its place
    Section "InputClass"
      Identifier "Logitech G602"
      Driver "libinput"
      MatchUSBID "046d:c537"
      Option "ButtonMapping" "1 0 3 4 5 6 7 8 2"
    EndSection
  '';

  services.redshift = {
    enable = true;
    provider = "geoclue2";
    temperature = {
      day = 6500;
      night = 3700;
    };
  };

  services.jenkins = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 5365;
    package = unstable.jenkins;
    packages = with pkgs; [
      coreutils
      git
      gnutar
      nix
      xz
    ];
  };

  users.mutableUsers = true;
  users.users.ben = {
    uid = 1000;
    group = "ben";
    createHome = true;
    home = "/home/ben";
    useDefaultShell = true;
    extraGroups = [
      "wheel"
    ];
    hashedPassword = "*";
    openssh.authorizedKeys.keyFiles = [
      ../../keys/tablet-blink.pub
      ../../keys/phone-termux.pub
    ];
  };
  users.groups.ben = {
    gid = 1000;
  };

  security.sudo.wheelNeedsPassword = true;

  programs.ssh = {
    startAgent = true;
    agentTimeout = "1h";
  };

  virtualisation.docker = {
    enable = true;
    storageDriver = "overlay2";
  };
}
