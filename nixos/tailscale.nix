# Tailscale client with optional declarative authentication through sops-nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  secretFile = ../hosts/nixos-btw/secrets/tailscale.yaml;
  hasSecretFile = builtins.pathExists secretFile;
in {
  # Keep the tools available even before the encrypted auth key is created.
  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  sops = lib.mkIf hasSecretFile {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets.tailscale-auth-key = {
      sopsFile = secretFile;
    };
  };

  # Let Tailscale integrate with the system resolver normally.
  services.resolved.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--hostname=${config.var.hostname}"
      "--accept-dns=true"
    ];
  } // lib.optionalAttrs hasSecretFile {
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };

  # Temporary fallback for a MagicDNS/Quad100 failure on this client:
  # tailscaled knows this peer's DNSName, but Quad100 returns no A record.
  networking.extraHosts = ''
    100.67.19.53 answer-animal.tail75889f.ts.net
  '';

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose";
  };
}
