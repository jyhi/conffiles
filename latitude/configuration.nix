# NixOS Configuration for <latitude.yhi.moe>.

{ pkgs, ... }: {
  boot.loader = {
    systemd-boot.enable = true;
    timeout = 3;
    efi.canTouchEfiVariables = true;
    generationsDir.copyKernels = true;
  };

  boot.tmpOnTmpfs = true;

  boot.initrd.luks.devices = {
    "nixos" = {
      device = "/dev/disk/by-partlabel/linux-system";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "rw" "size=10%" "mode=755" ];
    };

    "/nix" = {
      device = "/dev/mapper/nixos";
      fsType = "f2fs";
      options = [ "rw" "nodev" "noatime" ];
    };
  };

  swapDevices = [{
    device = "/dev/disk/by-partlabel/linux-swap";
    discardPolicy = "both";
    randomEncryption = {
      enable = true;
      allowDiscards = true;
    };
  }];

  zramSwap.enable = true;

  networking = {
    hostName = "latitude";
    domain = "yhi.moe";
  };

  time.timeZone = "Europe/London";

  environment = {
    memoryAllocator.provider = "mimalloc";
    noXlibs = true; # Wayland go brrr
    localBinInPath = true;
  };

  users.mutableUsers = false;
  users.users = {
    "jyhi" = {
      uid = 1001;
      description = "Junde Yhi";
      isNormalUser = true;
      initialHashedPassword =
        "$y$j9T$W5lCwVeck9cPRQHIDZKTq/$Xm3K0x.yY7LDE9K30bc.J.1sCV76e/gzbszLEBWSbR4";
      group = "users";
      extraGroups = [ "wheel" "video" "networkmanager" "kvm" ];
      home = "/home/jyhi";
      createHome = true;
    };
  };

  documentation = {
    info.enable = false;
    nixos.enable = false;
  };

  networking = {
    # Until NixOS fully switches to nftables...
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = ''
        flush ruleset

        table inet filter {
          chain input {
            type filter hook input priority filter; policy drop

            ct state invalid drop
            ct state { established, related } accept

            iifname lo accept

            ip protocol icmp accept
            ip6 nexthdr icmpv6 accept
          }

          chain forward {
            type filter hook forward priority filter; policy drop
          }

          chain output {
            type filter hook output priority filter; policy accept
          }
        }
      '';
    };

    networkmanager = {
      enable = true;
      firewallBackend = "nftables";
      wifi.macAddress = "random";
      ethernet.macAddress = "random";
    };
  };

  services = {
    tlp = {
      enable = true;
      settings = {
        TLP_DEFAULT_MODE = "AC";
        TLP_PERSISTENT_DEFAULT = 1;
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        DISK_DEVICES = "nvme0n1";
        DISK_IOSCHED = "none";
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    gtkUsePortal = true;
    wlr.enable = true;
  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      waybar
      brightnessctl
      wl-clipboard
      mako # notification daemon
      wofi # menu
    ];
    extraSessionCommands = "";
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    git
    alacritty
    firefox-wayland
    thunderbird-wayland
  ];
}
