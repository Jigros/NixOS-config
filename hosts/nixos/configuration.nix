{
  config,
  lib,
  pkgs,
  ...
}: {
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
    ../../nixos/hyprland.nix
    #../../nixos/usbguard.nix
    ../../home/programs/brave/system.nix # I hate browser's configuration..

    # You should let those lines as is
    ./hardware-configuration.nix
    ./variables.nix
  ];

  # USBGuard:
  # Allow all USB devices until a proper policy is configured.
  # Run `sudo usbguard generate-policy` with your devices plugged in,
  # then set rules = "<output>" and switch implicitPolicyTarget to "block".
  services.usbguard.implicitPolicyTarget = lib.mkForce "allow";

  programs.throne = {
    enable = true;
    tunMode.enable = true;
  };

  # The in-tree r8169 driver intermittently drops carrier on this RTL8168/8111
  # adapter. Use Realtek's r8168 driver instead.
  boot.blacklistedKernelModules = ["r8169"];
  boot.kernelModules = ["r8168"];
  boot.extraModulePackages = [config.boot.kernelPackages.r8168];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };

  programs.gamescope.enable = true;

  services.printing = {
  enable = true;
  browsed.enable = false;
};

services.avahi = {
  enable = true;
  nssmdns4 = true;
  openFirewall = true;
};

#hardware.printers = {
 # ensureDefaultPrinter = "HP_M401dn";
#
 # ensurePrinters = [
  #  {
   #   name = "HP_M401dn";
    #  description = "HP LaserJet Pro 400 M401dn";
     # deviceUri = "ipp://192.168.1.130/ipp/printer";
      #model = "everywhere";
    #}
  #];
#};
  
  services.usbguard.rules = ''
    allow id 1d6b:0002 serial "0000:01:00.0" name "xHCI Host Controller" hash "WLLK8WnDcOZsmC13ldzWRmahoyPD7Y+TLn1uJ4TB2GU=" parent-hash "7OE2Fzt+IQAZC3n0rY3/1vrm6oK7CajO9gYjXNzT7/g=" with-interface 09:00:00 with-connect-type ""
allow id 1d6b:0003 serial "0000:01:00.0" name "xHCI Host Controller" hash "e5LeVTjr6vscbo9CNt0wPTQEavctpnE3O77LtitBtK4=" parent-hash "7OE2Fzt+IQAZC3n0rY3/1vrm6oK7CajO9gYjXNzT7/g=" with-interface 09:00:00 with-connect-type ""
allow id 1d6b:0002 serial "0000:0c:00.3" name "xHCI Host Controller" hash "UR8uMoLf9KIBU81v0aFX2IrEQbLfaQOXHo9vHEgVp0s=" parent-hash "FfhFSlvppBY6SDw9Iszl6WrS3YVvKI0NPgVoUQeE4Sw=" with-interface 09:00:00 with-connect-type ""
allow id 1d6b:0003 serial "0000:0c:00.3" name "xHCI Host Controller" hash "FjDHAz2RMehiFOkafp2Dmrbqr06BX8U9NcNsUZuCEAs=" parent-hash "FfhFSlvppBY6SDw9Iszl6WrS3YVvKI0NPgVoUQeE4Sw=" with-interface 09:00:00 with-connect-type ""
allow id 05e3:0608 serial "" name "USB2.0 Hub" hash "W6l+xvpLKIN6p2T3tTOGGy7Qm+zPESG43Fox/qV9OCE=" parent-hash "WLLK8WnDcOZsmC13ldzWRmahoyPD7Y+TLn1uJ4TB2GU=" via-port "1-2" with-interface 09:00:00 with-connect-type "not used"
allow id 8087:0029 serial "" name "" hash "ATK8pCmQtUYaUnwqUVuYssrOMkW8pdCSdZO4OC6zEtg=" parent-hash "WLLK8WnDcOZsmC13ldzWRmahoyPD7Y+TLn1uJ4TB2GU=" via-port "1-5" with-interface { e0:01:01 e0:01:01 e0:01:01 e0:01:01 e0:01:01 e0:01:01 e0:01:01 e0:01:01 } with-connect-type "hardwired"
allow id 0b05:19af serial "9876543210" name "AURA LED Controller" hash "ivD4BdPa74ISz19OCKpiZy4RrkpyARqnN3oBXm49dnA=" parent-hash "WLLK8WnDcOZsmC13ldzWRmahoyPD7Y+TLn1uJ4TB2GU=" with-interface { ff:ff:ff 03:00:00 } with-connect-type "hardwired"
allow id 05e3:0608 serial "" name "USB2.0 Hub" hash "5uYwceHbvuBGAzUuLBS+ZQi9HzXT0tA6gPM3aE6l+PU=" parent-hash "UR8uMoLf9KIBU81v0aFX2IrEQbLfaQOXHo9vHEgVp0s=" via-port "3-1" with-interface 09:00:00 with-connect-type "hotplug"
allow id 0d8c:0012 serial "" name "USB Audio Device" hash "Wi/fR1vJuq3PcLkMY4ICEDtjUIJ4SjoO3LkFP3DrTlU=" parent-hash "UR8uMoLf9KIBU81v0aFX2IrEQbLfaQOXHo9vHEgVp0s=" via-port "3-2" with-interface { 01:01:00 01:02:00 01:02:00 01:02:00 01:02:00 03:00:00 } with-connect-type "hotplug"
allow id 373b:11d9 serial "541505796617" name "Wireless mouse 8k dongle-L" hash "3zJx5uzpsz8TYrb1g0eygMa03vk2Bzr0zx1BdS8z4eo=" parent-hash "UR8uMoLf9KIBU81v0aFX2IrEQbLfaQOXHo9vHEgVp0s=" with-interface { 03:01:02 03:00:00 03:01:01 } with-connect-type "hotplug"
allow id 0416:7372 serial "" name "" hash "QRDsQt7HibsDzKuWBmY4p4zgtNbgynFCH2AjRBlEjLE=" parent-hash "5uYwceHbvuBGAzUuLBS+ZQi9HzXT0tA6gPM3aE6l+PU=" via-port "3-1.1" with-interface { 03:00:02 03:01:01 03:00:00 } with-connect-type "unknown"
  '';

  networking.firewall.enable = false;

  # Enable Docker
  virtualisation.docker.enable = true;

  home-manager.users."${config.var.username}" = import ./home.nix;

  # Don't touch this
  system.stateVersion = "24.05";
}
