{config, ...}: {
  imports = [
    # Mostly system related configuration
    ../../nixos/nvidia.nix # CHANGEME: Remove this line if you don't have an Nvidia GPU
    ../../nixos/audio.nix
    ../../nixos/bluetooth.nix
    ../../nixos/fonts.nix
    ../../nixos/home-manager.nix
    ../../nixos/nix.nix
    ../../nixos/systemd-boot.nix
    ../../nixos/tuigreet.nix
    ../../nixos/autologin.nix # Skip first TUIGreet login, use LUKS password to unlock the keyring
    ../../nixos/users.nix
    ../../nixos/utils.nix
    ../../nixos/hyprland.nix
    ../../nixos/steam.nix
    ../../nixos/kernel-hardening.nix
    ../../nixos/throne.nix
    ../../nixos/openrgb.nix
    ../../nixos/docker.nix
    ../../nixos/printing.nix
    ../../nixos/tailscale.nix
    ../../nixos/obs.nix
    ../../home/programs/gui/helium/system.nix # I hate browser's configuration..

    # Optional host modules
    #./wireguard.nix
    #./persistence.nix # impermanence: what to keep once "/" is wiped on boot
    #./usbguard.nix
    #./disko.nix
    ./secrets

    ./hardware-configuration.nix
    ./variables.nix
  ];

  # TEMPORARY — Telegram API registration from this host only.
  # TLS verification passed against this endpoint on 2026-10-01.
  # Remove these lines after registering the API application:
  # https://github.com/Flowseal/zapret-discord-youtube/discussions/11494
  # NixOS merges this lines option with the existing Tailscale extraHosts.
  networking.extraHosts = ''
    149.154.167.220 my.telegram.org
  '';

  networking.firewall.enable = false;

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "26.05";
}
