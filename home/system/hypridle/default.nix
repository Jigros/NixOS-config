# hypridle only locks the session after inactivity. Automatic DPMS-off and
# suspend are intentionally disabled so the desktop stays awake.
{pkgs, ...}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pidof ${pkgs.hyprlock}/bin/hyprlock || ${pkgs.hyprlock}/bin/hyprlock --grace 5";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 300; # 5 min -> lock only
          on-timeout = "loginctl lock-session";
        }
      ];
    };
  };
}
