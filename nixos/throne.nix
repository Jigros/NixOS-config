{pkgs, ...}: {
  programs.throne = {
    enable = true;
    tunMode = {
      enable = true;
      # Use NixOS' privileged wrapper for ThroneCore instead of trying to
      # modify the read-only binary in the Nix store.
      setuid = true;
    };
  };

  # Start Throne automatically with the graphical user session. Throne's
  # NixOS patch looks up ThroneCore in PATH first, so /run/wrappers/bin must
  # be visible to this user service; otherwise it falls back to the unprivileged
  # ThroneCore symlink in /nix/store and TUN startup fails with the read-only
  # store warning.
  systemd.user.services.throne = {
    description = "Throne proxy client";
    wantedBy = ["graphical-session.target"];
    after = ["graphical-session.target"];
    serviceConfig = {
      ExecStart = "${pkgs.throne}/bin/Throne";
      Environment = "PATH=/run/wrappers/bin:/run/current-system/sw/bin";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
