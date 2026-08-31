{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    # Programs

    ## GUI
    #../../home/programs/gui/proton
    ../../home/programs/gui/helium
    ../../home/programs/gui/pkgs.nix

    ## TUI
    inputs.nvf-config.homeManagerModules.default
    ../../home/programs/tui/ghostty
    ../../home/programs/tui/ilovetui
    ../../home/programs/tui/shell
    ../../home/programs/tui/git
    ../../home/programs/tui/git/lazygit.nix
    #../../home/programs/tui/git/signing.nix # CHANGEME: Change the key or remove this file
    ../../home/programs/tui/nixy
    ../../home/programs/tui/nix-utils
    ../../home/programs/tui/spotatui
    ../../home/programs/tui/elio
    ../../home/programs/tui/wikiman
    ../../home/programs/tui/navi
    ../../home/programs/tui/pkgs.nix

    ## GROUPS
    ../../home/programs/group/cybersecurity.nix
    ../../home/programs/group/dev.nix

    # System (Desktop environment like stuff)
    ../../home/system/hyprlock
    ../../home/system/hyprland
    ../../home/system/waybar
    ../../home/system/swaync
    ../../home/system/tofi
    ../../home/system/mime
    ../../home/system/udiskie
    #../../home/system/termfilechooser
    ../../home/system/clipboard
    ../../home/system/hypridle

    ./variables.nix # Mostly user-specific configuration
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    persistence."/persist" = lib.mkIf (config.var.impermanenceEnabled or false) {
      directories = [
        ".config/nixos" # this repo itself (nixy manages it here)
        ".local/share"
        ".local/state"
        ".cache"
        ".steam"
        "Notes"
        "Projects"
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
      ];

      files = [
        ".ssh/known_hosts"
        ".config/sops/age/keys.txt"
      ];
    };

    sessionVariables = {
      AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1"; # CHANGEME: Related to the GPU
    };

    # Don't touch this
    stateVersion = "26.05";
  };

  wayland.windowManager.hyprland.settings.monitor = [
    "DP-3,1920x1080@143.99Hz,0x0,1"
    "DP-1,preferred,auto-left,1"
  ];

  programs = {
    home-manager.enable = true;
    nixy = {
      enable = true;
      configDirectory = config.var.configDirectory;
    };
  };
}
