{config, pkgs, ...}: {
  imports = [
    # Mostly system related configuration
    ../../nixos/nvidia.nix # CHANGEME: Remove this line if you don't have an Nvidia GPU
    ../../nixos/audio.nix
    ../../nixos/bluetooth.nix
    ../../nixos/fonts.nix
    ../../nixos/home-manager.nix
    ../../nixos/nix.nix
    ../../nixos/systemd-boot.nix
    ../../nixos/sddm.nix
    ../../nixos/users.nix
    ../../nixos/utils.nix
    ../../nixos/tailscale.nix
    ../../nixos/hyprland.nix
    ../../nixos/docker.nix

    ../../nixos/omen.nix # For my laptop only

    # You should let those lines as is
    ./hardware-configuration.nix
    ./variables.nix
  ];

  stylix.enableReleaseChecks = false;

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Add this block to enable OpenRGB udev rules
  services.udev.packages = [ pkgs.openrgb ];

  # MySQL service (use mariadb as the package)
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    # Optional: set a root password (not recommended for production)
    # initialRootPassword = "yourpassword";
  };

  programs.throne = {
    enable = true;
    tunMode.enable = true;
    # tunMode.setuid = true; # если хочешь suid
  };
  # Don't touch this
  system.stateVersion = "24.05";
}
