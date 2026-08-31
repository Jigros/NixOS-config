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
    ../../home/programs/gui/discord
    ../../home/programs/gui/pkgs.nix

    ## TUI
    inputs.nvf-config.homeManagerModules.default
    ../../home/programs/tui/ghostty
    ../../home/programs/tui/ilovetui
    ../../home/programs/tui/shell
    ../../home/programs/tui/git
    ../../home/programs/tui/git/lazygit.nix
    #../../home/programs/tui/git/signing.nix
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

    # Desktop
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
    ../../home/system/nightlight

    ./variables.nix
  ];

  home = {
    inherit (config.var) username;
    homeDirectory = "/home/" + config.var.username;

    persistence."/persist" = lib.mkIf (config.var.impermanenceEnabled or false) {
      directories = [
        ".config/nixos"
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

    sessionVariables.AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card1";
    stateVersion = "26.05";
  };

  # DP-1 is physically left; DP-3 is the 1080p 144 Hz monitor on the right.
  wayland.windowManager.hyprland.settings.monitor = [
    "DP-1,preferred,0x0,1"
    "DP-3,1920x1080@143.99Hz,auto-right,1"
  ];

  programs = {
    home-manager.enable = true;
    nixy = {
      enable = true;
      configDirectory = config.var.configDirectory;
    };
  };
}
