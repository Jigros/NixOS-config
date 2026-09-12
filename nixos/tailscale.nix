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

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--hostname=${config.var.hostname}"
    ];
  } // lib.optionalAttrs hasSecretFile {
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose";
  };
}
