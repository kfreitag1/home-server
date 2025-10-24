let
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEG2TpITPEazCINcPbeY6zndBWAoZRNSfRD9rhWI96iu kieran@nixos";
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQzXCHZhk/rHUSLI8+E5lNM3O1ZoZWUjyOPZG7Ivb5u kieran@Mac-2.lan";
  allKeys = [ server laptop ];
in
{
  "cloudflare-api-key.age".publicKeys = allKeys;
  "maxmind-license-key.age".publicKeys = allKeys;
  "actual-budget-oidc-secret.age".publicKeys = allKeys;
}
