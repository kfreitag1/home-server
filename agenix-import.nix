{ config, pkgs, lib, ... }:

let
  secretsConfig = import ./secrets/secrets.nix;
  
  secretNames = lib.mapAttrsToList (name: _: 
    lib.removeSuffix ".age" name
  ) secretsConfig;
  
  mkSecret = name: {
    file = ./secrets/${name}.age;
    mode = "444";
    owner = "root";
    group = "docker";
  };
in
{
  age.secrets = lib.genAttrs secretNames mkSecret;
}