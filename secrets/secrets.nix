let
  server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcM3fGjT0HJ2ApA0m/6oyFJV9HBJk/9JzhB3P0IVdOu root@homeserver";
  laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICQzXCHZhk/rHUSLI8+E5lNM3O1ZoZWUjyOPZG7Ivb5u kieran@Mac-2.lan";
  allKeys = [ server laptop ];
in
{
  "cloudflare-api-key.age".publicKeys = allKeys;
  "maxmind-license-key.age".publicKeys = allKeys;
  "actual-budget-oidc-client-secret.age".publicKeys = allKeys;
  "admin-apps-oidc-client-secret.age".publicKeys = allKeys;
  "booklore-db-password.age".publicKeys = allKeys;
  "obsidian-livesync-db-pass.age".publicKeys = allKeys;
}
