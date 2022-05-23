# NixOS Configuration for <latitude.yhi.moe>.

{ pkgs, ... }:
let
  pathImpermanence = builtins.fetchGit {
    url = "https://github.com/nix-community/impermanence";
    ref = "master";
    rev = "2f39baeb7d039fda5fc8225111bb79474138e6f4";
  };
in {
  imports = [ "${pathImpermanence}/nixos.nix" ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      timeout = 3;
      efi.canTouchEfiVariables = true;
      generationsDir.copyKernels = true;
    };
    supportedFilesystems = [ "f2fs" ];
    tmpOnTmpfs = true;
    initrd.luks.devices = {
      "nixos" = {
        device = "/dev/disk/by-partlabel/linux-system";
        allowDiscards = true;
        bypassWorkqueues = true;
      };
    };
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "rw" "noatime" "nodev" "nosuid" "mode=755" ];
    };

    "/nix" = {
      device = "/dev/mapper/nixos";
      fsType = "f2fs";
      # NOTE: format this partition with:
      #   -O extra_attr,inode_checksum,sb_checksum,compression
      options = [
        "rw"
        "noatime"
        "nodev"
        # https://wiki.archlinux.org/title/F2FS#Recommended_mount_options
        # whint_mode has been deprecated!
        "compress_algorithm=zstd:6"
        "compress_chksum"
        "atgc"
        "gc_merge"
      ];
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
    localBinInPath = true;
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.dash;
    users = {
      "jyhi" = {
        uid = 1001;
        description = "Junde Yhi";
        isNormalUser = true;
        initialHashedPassword =
          "$5$qJVeybe.0P7E9CQu$wvN4gJWLVY2U1V.sACa4.KeDw0muEY0yKW/Ez6YQaZB";
        extraGroups = [ "wheel" "video" "networkmanager" ];
      };
    };
  };

  documentation.info.enable = false;

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
      slurp # screen region selector
      grim # screenshot
      mako # notification daemon
      wofi # menu
    ];

    # https://github.com/swaywm/sway/wiki/Running-programs-natively-under-wayland
    extraSessionCommands = ''
      export QT_QPA_PLATFORM=wayland-egl
      export QT_WAYLAND_FORCE_DPI=physical
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SDL_VIDEODRIVER=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  environment.persistence."/nix/pers" = {
    hideMounts = true;
    directories = [ "/var/log" ];
    files = [ "/etc/machine-id" ];
    users."jyhi" = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".gnupg";
          mode = "0700";
        }
        ".config/sway"
        ".config/swaylock"
        ".config/waybar"
        "Applications"
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Videos"
      ];
      files = [ ".vimrc" ];
    };
  };

  environment.systemPackages = with pkgs; [ vim gnupg git ];
}
