################################################################################
##                                                                            ##
##                      System configuration for Saturne                      ##
##                                                                            ##
################################################################################

{ config, lib, pkgs, ... }:

{
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09";  # Did you read the comment?

  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # Configuration shared between hosts.
    ../common/system/general.nix
    ../common/system/type/physical.nix
    ../common/system/type/laptop.nix
    ../common/system/usage/workstation.nix
    ../common/system/usage/home.nix
    ../common/system/features/zfs.nix
    ../common/system/location/kerguelen.nix

    # Configuration for the users.
    ./users

    # Configuration to make a Pi-Gateway
    # ./pi-gateway.nix
  ];

  ############################################################################
  ##                     Configuration for offline mode                     ##
  ############################################################################

  nix = {
    binaryCaches = lib.mkForce [ "file:///data/Mirroirs/nixpkgs/cache" ];
    gc.automatic = false;
  };

  environment.variables = {
    # Use the local mirrors.
    HEX_MIRROR_URL = "http://hex.saturne/repos/hexpm_mirror";
  };

  ############################################################################
  ##                          Boot & File systems                           ##
  ############################################################################

  boot = {
    # TODO: Remove in NixOS 20.03.
    supportedFilesystems = [ "zfs" ];
    tmpOnTmpfs = true;

    loader = {
      # Use the systemd-boot EFI boot loader.
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot";
      timeout = 1;
    };

    initrd = {
      luks.devices = {
        ssd1 = { device = "/dev/nvme0n1p2"; allowDiscards = true; };
        ssd2 = { device = "/dev/nvme1n1p2"; allowDiscards = true; };
      };
    };

    zfs.requestEncryptionCredentials = false;
  };

  fileSystems = {
    # Set options for the legacy mountpoints.
    "/".options = [ "noatime" ];
    "/boot".options = [ "nosuid" "nodev" "noexec" "noatime" ];
    "/etc".options = [ "nosuid" "nodev" "noatime" ];
    "/root".options = [ "nosuid" "nodev" "noatime" ];
    "/var".options = [ "nosuid" "nodev" "noexec" ];
    "/var/cache".options = [ "nosuid" "nodev" "noexec" ];
    "/var/db".options = [ "nosuid" "nodev" "noexec" ];
    "/var/empty".options = [ "nosuid" "nodev" "noexec" "noatime" ];
    "/var/log".options = [ "nosuid" "nodev" "noexec" ];
    "/var/tmp".options = [ "nosuid" "nodev" ];
  };

  ############################################################################
  ##                                Hardware                                ##
  ############################################################################

  # Tweak to get the touchpad working when waking up from sleep.
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/rmmod i2c_hid
    ${pkgs.kmod}/bin/modprobe i2c_hid
  '';

  ############################################################################
  ##                         General configuration                          ##
  ############################################################################

  networking = {
    hostName = "saturne";
    hostId = "66f21a93";

    firewall = {
      # Share websites and mirrors.
      allowedTCPPorts = [ 80 6543 ];
    };

    hosts = {
      # Local web servers
      "127.0.0.1" = [
        "localhost"
        "saturne"
        "crates.saturne"
        "hex.saturne"
        "nix.saturne"
        "dev.jpc.photos"
        "dev.bark-artwork.com"
      ];
    };
  };

  ############################################################################
  ##                            System packages                             ##
  ############################################################################

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Utilities
    thunderbolt
  ];

  ############################################################################
  ##                                Services                                ##
  ############################################################################

  services = {
    hardware.bolt.enable = true;
    throttled.enable = true;

    printing.drivers = [ pkgs.epson-escpr ];
    udev.packages = [ pkgs.mixxx ];

    httpd = {
      enable = true;
      enablePHP = true;
      adminAddr = "jpc+saturne@ejpcmac.net";

      virtualHosts = [
        {
          hostName = "localhost";
          documentRoot = "/var/lib/www/localhost";
        }

        {
          hostName = "nix.saturne";
          documentRoot = "/data/Mirroirs/nixpkgs";
        }

        {
          hostName = "crates.saturne";
          documentRoot = "/data/Mirroirs/crates.io";
        }

        {
          hostName = "hex.saturne";
          documentRoot = "/data/Mirroirs/hex.pm";
        }

        {
          hostName = "dev.jpc.photos";
          documentRoot = "/var/lib/www/jpc_photos";
          extraConfig = ''
            <Directory "/var/lib/www/jpc_photos">
              DirectoryIndex index.html index.php
              AllowOverride All
            </Directory>
          '';
        }

        {
          hostName = "dev.bark-artwork.com";
          documentRoot = "/var/lib/www/bark-artwork.com";
          extraConfig = ''
            <Directory "/var/lib/www/bark-artwork.com">
              DirectoryIndex index.html index.php
              AllowOverride All
            </Directory>
          '';
        }
      ];
    };

    mpd = {
      enable = true;
      musicDirectory = "/data/Musique";
      extraConfig = builtins.readFile ./res/mpd.conf;
    };

    nix-serve = {
      enable = true;
      port = 6543;
      secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
    };

    xserver = {
      dpi = 141;
      videoDrivers = [ "nvidia" ];
      xrandrHeads = [ { output = "DP-0"; primary = true; } ];
    };
  };

  ############################################################################
  ##                             Virtualisation                             ##
  ############################################################################

  virtualisation = {
    docker.enable = true;
    virtualbox.host = { enable = true; enableExtensionPack = true; };
  };
}
