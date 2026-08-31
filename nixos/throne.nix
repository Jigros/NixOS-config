{pkgs, ...}: {
  programs.throne = {
    enable = true;
    tunMode.enable = true;
  };

  # Start Throne automatically with the graphical user session so its tray
  # icon is available without launching the app manually.
  systemd.user.services.throne = {
    description = "Throne proxy client";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.throne}/bin/Throne";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
