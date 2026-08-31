{pkgs, ...}: {
  home.packages = [pkgs.hyprsunset];

  wayland.windowManager.hyprland.settings.exec-once = [
    "${pkgs.hyprsunset}/bin/hyprsunset -t 4500"
  ];
}
