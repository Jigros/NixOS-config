{config, pkgs, ...}: let
  # RemoteCam serves MJPEG on the phone. This helper exposes its port over the
  # existing USB ADB connection, so OBS can use a stable localhost URL.
  remoteCamUsb = pkgs.writeShellScriptBin "remotecam-usb" ''
    set -eu
    case "''${1:-start}" in
      start)
        ${pkgs.android-tools}/bin/adb -d wait-for-device
        ${pkgs.android-tools}/bin/adb -d forward --remove tcp:18080 >/dev/null 2>&1 || true
        ${pkgs.android-tools}/bin/adb -d forward tcp:18080 tcp:8080 >/dev/null
        echo "RemoteCam USB: http://127.0.0.1:18080/cam.mjpeg"
        ;;
      stop)
        ${pkgs.android-tools}/bin/adb -d forward --remove tcp:18080 >/dev/null 2>&1 || true
        ;;
      status)
        ${pkgs.android-tools}/bin/adb -d forward --list | ${pkgs.gnugrep}/bin/grep 'tcp:18080 tcp:8080' || true
        ;;
      *)
        echo "usage: remotecam-usb [start|stop|status]" >&2
        exit 2
        ;;
    esac
  '';
in {
  # Keep DroidCam as a fallback while RemoteCam is being evaluated.
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = false;
    plugins = with pkgs.obs-studio-plugins; [
      droidcam-obs
      obs-backgroundremoval
    ];
  };

  # OBS Virtual Camera requires a single v4l2loopback device on Linux.
  # It is configured explicitly to avoid duplicate modprobe options.
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];
  boot.kernelModules = ["v4l2loopback"];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 exclusive_caps=1 card_label="OBS Virtual Camera"
  '';

  environment.systemPackages = with pkgs; [
    android-tools
    remoteCamUsb
  ];

  # Keep the ADB server alive so USB camera forwarding is immediately available.
  systemd.user.services.adb-server = {
    description = "Android Debug Bridge server";
    wantedBy = ["default.target"];
    serviceConfig = {
      ExecStart = "${pkgs.android-tools}/bin/adb nodaemon server";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
