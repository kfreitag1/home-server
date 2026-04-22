
{
  description = "Home server flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, agenix }:
    let
      configuration = { pkgs, ... }: {

        # VSCode compatibility
        programs.nix-ld.enable = true;

        # Boot
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        # File system
        fileSystems = {
          # Adding new drive
          # Drive infos:  $ lsblk -f
          # Format drive: $ sudo mkfs.ext4 -L dataX /dev/XXX

          "/mnt/disk1" = {
            device = "/dev/disk/by-uuid/f2061751-479b-4703-a93e-13db54ff5713";
            fsType = "ext4";
            options = [ "defaults" "nofail" ];
          };

          "/mnt/backup" = {
            device = "/dev/disk/by-uuid/9f22ca6a-7bd5-478f-90f2-cfbd123bdc75";
            fsType = "ext4";
            options = [ "defaults" "nofail" ];
          };

          "/mnt/cache" = {
            device = "/dev/disk/by-uuid/ed80a085-8429-43e2-ad5e-1e0ccdbfa508";
            fsType = "xfs";
            options = [ "defaults" "nofail" ];
          };

          "/mnt/storage" = {
            device = "/mnt/disk*";
            fsType = "fuse.mergerfs";
            options = [
              "defaults"
              "allow_other"
              "use_ino"
              "cache.files=partial"
              "dropcacheonclose=true"
              "category.create=mfs"
              "fsname=mergerfs"
              "nofail"
            ];
          };
        };
        # TODO: Get a parity drive and set up SnapRAID

        # Network storage
        services.samba = {
          enable = true;
          openFirewall = true;

          settings = {
            global = {
              "workgroup" = "WORKGROUP";
              "server string" = "rhodhouse-server";
              "netbios name" = "rhodhouse-server";
              "security" = "user";

              "vfs objects" = "fruit streams_xattr";
              "fruit:metadata" = "stream";
              "fruit:model" = "MacSamba";
              "fruit:posix_rename" = "yes";
              "fruit:veto_appledouble" = "no";
              "fruit:wipe_intentionally_left_blank_rfork" = "yes";
              "fruit:delete_empty_adfiles" = "yes";
            };

            all = {
              "path" = "/mnt/storage";
              "browseable" = "yes";
              "read only" = "no";
              "guest ok" = "no";
              "valid users" = "kieran";
              "create mask" = "0644";
              "directory mask" = "0755";
            };

            storage = {
              "path" = "/mnt/storage/storage";
              "browseable" = "yes";
              "read only" = "no";
              "guest ok" = "no";
              "valid users" = "kieran";
              "create mask" = "0644";
              "directory mask" = "0755";
            };

            timemachine = {
              "path" = "/mnt/storage/timemachine";
              "browseable" = "yes";
              "read only" = "no";
              "guest ok" = "no";
              "valid users" = "kieran";
              "fruit:time machine" = "yes";
              "vfs objects" = "catia fruit streams_xattr";
            };
          };
        };

        services.samba-wsdd = {
          enable = true;
          openFirewall = true;
        };

        services.avahi = {
          enable = true;
          nssmdns4 = true;
          publish = {
            enable = true;
            userServices = true;
          };
        };

        # Tailscale
        services.tailscale = {
          enable = true;
          openFirewall = true;
        };

        # Networking
        networking.hostName = "homeserver";
        networking.networkmanager.enable = true;

        # Locale + TZ
        time.timeZone = "America/Vancouver";
        i18n.defaultLocale = "en_CA.UTF-8";

        # Users
        users.users.kieran = {
          isNormalUser = true;
          description = "Kieran Freitag";
          extraGroups = [ "networkmanager" "wheel" "docker" ];
        };

        # Allow unfree packages
        nixpkgs.config.allowUnfree = true;

        # Sys packages
        environment.systemPackages = with pkgs; [
          xfsprogs
          mergerfs
          mergerfs-tools
          git
          sqlite
          tmux
          radeontop
          opencode
          gemini-cli
          claude-code
          wget
          postgresql
          vim
          agenix.packages.${system}.default
          (pkgs.writeShellScriptBin "caddy-reload" ''
            caddy_container_id=$(${pkgs.docker}/bin/docker ps | ${pkgs.gnugrep}/bin/grep caddy | ${pkgs.gawk}/bin/awk '{print $1;}')
            ${pkgs.docker}/bin/docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
          '')
        ];

        # Nix garbage collection
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 3";
        };

        # Keep only last 3 generations
        boot.loader.systemd-boot.configurationLimit = 3;

        # Aliases
        environment.shellAliases = {
          rebuild = "sudo nixos-rebuild switch --impure --flake ~/config";
          update = "nix flake --extra-experimental-features \"nix-command flakes\" update --flake ~/config/flake.nix";
        };

        # Services
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            Macs = [
              "hmac-sha2-512-etm@openssh.com"
              "hmac-sha2-256-etm@openssh.com"
              "umac-128-etm@openssh.com"
              "hmac-sha2-512"
              "hmac-sha2-256"
            ];
          };
        };

        services.home-assistant = {
          enable = true;
          extraComponents = [
            "analytics"
            "met"
            "radio_browser"
            "isal"
            "matter"
            "mobile_app"
            "thread"
            "otbr"
            "homekit"
          ];
          config = {
            default_config = {};
            http = {
              use_x_forwarded_for = true;
              trusted_proxies = [ "172.16.0.0/12" ];
            };
            "automation ui" = "!include automations.yaml";
            "script ui" = "!include scripts.yaml";
            "scene ui" = "!include scenes.yaml";
          };
        };

        services.matter-server = {
          enable = true;
        };

        systemd.tmpfiles.rules = [
          "f /var/lib/hass/automations.yaml 0644 hass hass"
          "f /var/lib/hass/scripts.yaml 0644 hass hass"
          "f /var/lib/hass/scenes.yaml 0644 hass hass"
        ];

        # Firewall
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 80 443 8123 21063 21064 ];
        networking.firewall.allowedUDPPorts = [ 443 1212 5353 5540 49191 ];

        system.stateVersion = "25.05";
      };
    in
    {
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = "x86_64_linux";
        modules = [
          ./hardware-configuration.nix
          ./homeserver-hardware.nix
          ./docker.nix
          ./agenix-import.nix
          ./backup.nix
          configuration
          agenix.nixosModules.default
        ];
      };
    };
}
