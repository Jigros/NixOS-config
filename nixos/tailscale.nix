# Tailscale is a VPN service that makes it easy to connect your devices between each other.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: let
  username = config.var.username;
  secretsFile = ../hosts/nixos/secrets/secrets.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
in {
  environment.systemPackages = with pkgs; [
    age
    sops
  ];

  security.sudo.extraRules = [
    {
      users = [username];
      # Allow running Tailscale commands without a password
      commands = [
        {
          command = "/etc/profiles/per-user/${username}/bin/tailscale";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/tailscale";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  sops = lib.mkIf hasSecretsFile {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = secretsFile;
    secrets.tailscale-auth-key = {};
  };

  services.tailscale = {
    enable = true;
    package = inputs.nixpkgs-stable.legacyPackages.x86_64-linux.tailscale;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = ["--hostname=${config.var.hostname}"];
  } // lib.optionalAttrs hasSecretsFile {
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    # required to connect to Tailscale exit nodes
    checkReversePath = "loose";
  };
}
