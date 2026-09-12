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
    hostname = "nixos";
    username = "the_cet";
    configDirectory =
      "/home/"
      + config.var.username
      + "/NixOS-config/"; # The path of the nixos configuration directory

    keyboardLayout = "us";
    #keyboardVariant = "ruchey_ru";

    location = "Vladivostok  ";
    timeZone = "Asia/Vladivostok";
    defaultLocale = "en_US.UTF-8";
    extraLocale = "ru_RU.UTF-8";

    git = {
      username = "Jigros";
      email = "209211492+Jigros@users.noreply.github.com";
    };

    autoUpgrade = false;
    autoGarbageCollector = true;
  };

  # Let this here
  options = {
    var = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };
}
