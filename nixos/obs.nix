{config, pkgs, ...}: let
  # PopDroidCam is a small upstream wrapper around scrcpy camera capture.
  # Package the CLI declaratively instead of running its distro-specific installer.
  popDroidCam = pkgs.stdenvNoCC.mkDerivation {
    pname = "popdroidcam";
    version = "1.1.3";

    src = pkgs.fetchFromGitHub {
      owner = "MaxySpark";
      repo = "PopDroidCam";
      rev = "eec4118fdeb560ec3a0c8f2962fa8e8630e22417";
      sha256 = "0wbiskiym7j005w9ab3c9jh3fpvf2gx3zw6sw6v0jb93z3q3qi87";
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/popdroidcam $out/bin
      cp -r . $out/share/popdroidcam/
      chmod +x $out/share/popdroidcam/popdroidcam
      makeWrapper $out/share/popdroidcam/popdroidcam $out/bin/popdroidcam \
        --prefix PATH : ${pkgs.lib.makeBinPath [
          pkgs.android-tools pkgs.scrcpy pkgs.v4l-utils pkgs.bc pkgs.coreutils
          pkgs.gnugrep pkgs.gnused pkgs.gawk pkgs.procps pkgs.kmod
        ]}
      runHook postInstall
    '';
  };
in {
  # OBS with Android phone camera support, background removal and a virtual
  # V4L2 camera that applications such as Zoom can select.
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = false;
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
    options v4l2loopback devices=2 video_nr=1,2 exclusive_caps=1,1 card_label="OBS Virtual Camera,PopDroidCam"
  '';

  # DroidCam's USB mode uses ADB. On NixOS 26.05 systemd handles USB uaccess
  # rules automatically; installing android-tools is enough to provide adb.
  environment.systemPackages = with pkgs; [
    android-tools
    scrcpy
    v4l-utils
    popDroidCam
  ];

  # Keep the ADB server alive for DroidCam so the OBS plugin never blocks
  # the UI while waiting for adb start-server. Use adb's default local socket;
  # setting ADB_SERVER_SOCKET to a hostname makes Android Tools 35 abort.
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
