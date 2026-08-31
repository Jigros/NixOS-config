{
  config,
  lib,
  ...
}: {
  imports = [
    # Choose your theme here:
    ../../themes/nixy.nix
  ];

  config.var = {
    hostname = "nixos-btw";
    username = "the_cet";
    configDirectory = "/home/" + config.var.username + "/.config/nixos"; # The path of the nixos configuration directory

    # English + Russian, switch with Alt+Shift in Hyprland.
    keyboardLayout = "us,ru";

    timeZone = "Asia/Vladivostok";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "ru_RU.UTF-8";

    git = {
      username = "Jigros";
      email = "209211492+Jigros@users.noreply.github.com";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
    impermanenceEnabled = false;
  };

  # DON'T TOUCH THIS
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
}
