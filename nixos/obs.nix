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

  # OBS Virtual Camera requires a v4l2loopback device on Linux.
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"
  '';

  # DroidCam's USB mode uses ADB. On NixOS 26.05 systemd handles USB uaccess
  # rules automatically; installing android-tools is enough to provide adb.
  environment.systemPackages = with pkgs; [
    android-tools
  ];

  # Keep the ADB server alive for DroidCam. adb start-server was hanging on
  # this host, while nodaemon mode is stable, so run that mode under systemd.
  systemd.user.services.adb-server = {
    description = "Android Debug Bridge server";
    wantedBy = ["default.target"];
    environment.ADB_SERVER_SOCKET = "tcp:127.0.0.1:5037";
    serviceConfig = {
      ExecStart = "${pkgs.android-tools}/bin/adb nodaemon server";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
