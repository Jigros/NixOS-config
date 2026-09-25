{config, pkgs, ...}: {
  # OBS with Android phone camera support, background removal and a virtual
  # V4L2 camera that applications such as Zoom can select.
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
      obs-backgroundremoval
    ];
  };

  # DroidCam's USB mode uses ADB. Enabling the NixOS ADB module also installs
  # the required udev rules; the user must be in adbusers for unprivileged USB
  # access.
  programs.adb.enable = true;
  users.users.${config.var.username}.extraGroups = [
    "adbusers"
  ];
}
