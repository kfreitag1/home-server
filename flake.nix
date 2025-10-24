
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
          packages = with pkgs; [
            claude-code
          ];
        };

        # Allow unfree packages
        nixpkgs.config.allowUnfree = true;

        # Sys packages
        environment.systemPackages = with pkgs; [
          git
          agenix.packages.${system}.default
          (pkgs.writeShellScriptBin "caddy-reload" ''
            caddy_container_id=$(${pkgs.docker}/bin/docker ps | ${pkgs.gnugrep}/bin/grep caddy | ${pkgs.gawk}/bin/awk '{print $1;}')
            ${pkgs.docker}/bin/docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
          '')
        ];

        # Aliases
        environment.shellAliases = {
          rebuild = "sudo nixos-rebuild switch --impure --flake ~/config";
        };

        # Services
        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
        };

        # Firewall
        networking.firewall.enable = true;
        networking.firewall.allowedTCPPorts = [ 22 80 443 ];
        networking.firewall.allowedUDPPorts = [ 443 ];

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
          configuration
          agenix.nixosModules.default
        ];
      };
    };
}
