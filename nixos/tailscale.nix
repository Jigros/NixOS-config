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

  # Tailscale integrates best with systemd-resolved on Linux. This lets
  # MagicDNS and split-DNS domains such as *.ts.net be handled without
  # hardcoding Tailscale IPs in /etc/hosts.
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

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose";
  };
}
