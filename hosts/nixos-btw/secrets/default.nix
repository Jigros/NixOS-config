# Secrets for nixos-btw, encrypted with sops.
{
  pkgs,
  config,
  ...
}: let
  username = config.var.username;
  home = "/home/${username}";
in {
  sops = {
    age.keyFile = "${home}/.config/sops/age/keys.txt";

    secrets.omniroute-opencode-key = {
      sopsFile = ./ai.yaml;
      owner = username;
      mode = "0400";
    };
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}
