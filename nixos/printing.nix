{...}: {
  services.printing = {
    enable = true;
    browsed.enable = false;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
