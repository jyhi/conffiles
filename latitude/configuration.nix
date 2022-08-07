# NixOS Configuration for <latitude.yhi.moe>.

{ lib, pkgs, ... }: 
let
  pathImpermanence = builtins.fetchGit {
    url = "https://github.com/nix-community/impermanence";
    ref = "master";
    rev = "2f39baeb7d039fda5fc8225111bb79474138e6f4";
  };
in {
  imports = [ "${pathImpermanence}/nixos.nix" ];

  system.stateVersion = "22.05";

  boot = {
    loader = {
      systemd-boot.enable = true;
      timeout = 3;
      efi.canTouchEfiVariables = true;
      generationsDir.copyKernels = true;
    };

    initrd = {
      availableKernelModules = [ "nvme" ];
      luks.devices = {
        "nixos" = {
          device = "/dev/disk/by-partlabel/linux-system";
          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };
    };

    supportedFilesystems = [ "f2fs" ];
    tmpOnTmpfs = true;

    # Enable Intel IOMMU to enable iGVT-g
    # https://wiki.archlinux.org/title/Intel_GVT-g
    kernelParams = [ "intel_iommu=on" ];

    # - Enable nested virtualisation
    # - Enable iGVT-g and HuC firmware load
    extraModprobeConfig = ''
      options kvm_intel nested=1
      options i915 enable_gvt=1 enable_guc=2
    '';

    # Enable S3 sleep
    postBootCommands = "echo deep > /sys/power/mem_sleep";
  };

  fileSystems = {
    "/" = {
      fsType = "tmpfs";
      options = [ "rw" "noatime" "nodev" "nosuid" "noexec" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/esp";
      fsType = "vfat";
      options = [ "rw" "noatime" "nodev" "nosuid" "noexec" ];
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

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  networking = {
    hostName = "latitude";
    domain = "yhi.moe";
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  environment = {
    # This breaks Firefox
    # memoryAllocator.provider = "mimalloc";

    localBinInPath = true;
    sessionVariables = {
      # Configure Electron apps to run on Wayland
      # https://nixos.org/manual/nixos/stable/release-notes.html#sec-release-22.05-notable-changes
      NIXOS_OZONE_WL = "1";
    };
  };

  users = {
    mutableUsers = false;
    users = {
      "jyhi" = {
        uid = 1001;
        description = "Junde Yhi";
        isNormalUser = true;
        initialHashedPassword =
          "$5$qJVeybe.0P7E9CQu$wvN4gJWLVY2U1V.sACa4.KeDw0muEY0yKW/Ez6YQaZB";
        extraGroups = [ "wheel" "networkmanager" "libvirtd" ];
      };
    };
  };

  documentation.info.enable = false;

  networking = {
    firewall.enable = false;
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority filter; policy drop;

            iifname lo accept
            iifname virbr0 accept
            ct state {established, related} accept
            ct state invalid drop

            ip protocol icmp accept
            ip6 nexthdr icmpv6 accept

            tcp dport 50022 accept
          }

          chain forward {
            type filter hook forward priority filter; policy accept;
          }

          chain output {
            type filter hook output priority filter; policy accept;
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
    openssh = {
      enable = false;
      ports = [ 50022 ];
    };

    tlp = {
      enable = true;
      settings = {
        TLP_DEFAULT_MODE = "BAT";
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

  # Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.05/nixos/modules/services/networking/mullvad-vpn.nix
  # Switch from mullvad-vpn to mullvad
  # pkgs.mullvad is installed in environment.systemPackages
  systemd.services.mullvad-daemon = {
    description = "Mullvad VPN daemon";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network.target" ];
    after = [
      "network-online.target"
      "NetworkManager.service"
      "systemd-resolved.service"
    ];
    path = [
      pkgs.iproute2
      # Needed for ping
      "/run/wrappers"
    ];
    startLimitBurst = 5;
    startLimitIntervalSec = 20;
    serviceConfig = {
      ExecStart = "${pkgs.mullvad}/bin/mullvad-daemon -v --disable-stdout-timestamps";
      Restart = "always";
      RestartSec = 1;
    };
  };

  programs = {
    vim.defaultEditor = true;

    git = {
      enable = true;
      lfs.enable = true;
    };

    gnupg = {
      agent = {
        enable = true;
        pinentryFlavor = "gnome3";
      };
      dirmngr.enable = true;
    };

    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        swaylock
        swayidle
        waybar
        brightnessctl
        wl-clipboard
        bluez # bluetooth
        libayatana-appindicator # tray
        slurp # screen region selector
        grim # screenshot
        mako # notification daemon
        rofi-wayland # menu
      ];

      # https://github.com/swaywm/sway/wiki/Running-programs-natively-under-wayland
      extraSessionCommands = ''
        export QT_QPA_PLATFORM=wayland-egl
        export QT_WAYLAND_FORCE_DPI=physical
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export SDL_VIDEODRIVER=wayland
        export _JAVA_AWT_WM_NONREPARENTING=1

        export GRIM_DEFAULT_DIR=$HOME/Pictures/Screenshots
      '';
    };
  };

  virtualisation = {
    kvmgt = {
      enable = true;
      vgpus = {
        "i915-GVTg_V5_4" = {
          uuid = [ "49d1a7d1-3b31-45f1-a2a1-5d37bd646a85" ];
        };
      };
    };

    libvirtd = {
      enable = true;
      onBoot = "ignore";
      qemu = {
        swtpm.enable = true;
        runAsRoot = false;
      };
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk

      # This crashes for it cannot load qt.qpa.xcb, but it should load wayland-egl
      # xdg-desktop-portal-kde
    ];
  };

  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      fira-code
      font-awesome
    ];

    fontconfig = {
      allowBitmaps = false;
      defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "Fira Code" ];
      };
    };
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-rime ];
      enableRimeData = true;
    };
  };

  # Get rid of this small set of "recommended" packages
  environment.defaultPackages = lib.mkForce [ ];

  environment.systemPackages = with pkgs; [
    dash
    htop
    mullvad
    neofetch
    numix-cursor-theme
    numix-gtk-theme
    numix-icon-theme
    numix-icon-theme-square
    pcmanfm-qt
    rclone
    unzip
    virt-manager
    virtiofsd
    xdg-utils
    zip
  ];

  users.users."jyhi".packages = with pkgs; [
    alacritty
    firefox-wayland
    keepassxc
    libreoffice-fresh
    tdesktop
    thunderbird-wayland
    vlc
    vscodium
  ];

  environment.persistence."/nix/pers" = {
    hideMounts = true;

    directories = [
      "/etc/nixos"
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      "/var/lib"
      "/var/log"
    ];

    files = [ "/etc/machine-id" ];

    users."jyhi" = {
      directories = [
        { directory = ".cache/rclone"; mode = "0700"; }
        { directory = ".config/dconf"; mode = "0700"; }
        { directory = ".config/fcitx5"; mode = "0700"; }
        { directory = ".config/htop"; mode = "0700"; }
        { directory = ".config/keepassxc"; mode = "0700"; }
        { directory = ".config/libreoffice"; mode = "0700"; }
        { directory = ".config/pcmanfm-qt"; mode = "0700"; }
        { directory = ".config/rclone"; mode = "0700"; }
        { directory = ".config/sway"; mode = "0700"; }
        { directory = ".config/swayidle"; mode = "0700"; }
        { directory = ".config/swaylock"; mode = "0700"; }
        { directory = ".config/waybar"; mode = "0700"; }
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".local/state/wireplumber"; mode = "0700"; }
        { directory = ".local/share/fcitx5/rime"; mode = "0700"; }
        { directory = ".local/share/TelegramDesktop"; mode = "0700"; }
        { directory = ".mozilla"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".thunderbird"; mode = "0700"; }
        "Documents"
        "Downloads"
        "Music"
        "Pictures"
        "Repositories"
        "Videos"
      ];

      files = [
        ".vimrc"
      ];
    };
  };
}
