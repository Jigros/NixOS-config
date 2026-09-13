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

  # Throne recreates its sing-box nftables table when TUN is restarted. Its
  # route bypass list does not currently place the whole Tailscale CGNAT range
  # into inet4_local_address_set, so TCP to tailnet peers can be redirected to
  # the local proxy. Re-apply the bypass periodically so it also survives a
  # Throne restart or a VPS receiving a different Tailscale address.
  systemd.services.throne-tailscale-bypass = {
    description = "Keep Tailscale traffic out of Throne transparent proxy";
    path = [pkgs.nftables pkgs.tailscale];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu

      if ! nft list set inet sing-box inet4_local_address_set >/dev/null 2>&1; then
        # Throne/TUN is not running yet. The timer will retry.
        exit 0
      fi

      if nft get element inet sing-box inet4_local_address_set '{ 100.64.0.0/10 }' >/dev/null 2>&1; then
        exit 0
      fi

      # Throne inserts this machine's own Tailscale /32 into the interval set.
      # Remove it first because nftables interval sets reject overlapping ranges.
      tailscale ip -4 2>/dev/null | while IFS= read -r address; do
        [ -n "$address" ] || continue
        nft delete element inet sing-box inet4_local_address_set "{ $address }" 2>/dev/null || true
      done

      nft add element inet sing-box inet4_local_address_set '{ 100.64.0.0/10 }'
    '';
  };

  systemd.timers.throne-tailscale-bypass = {
    description = "Re-apply the Throne Tailscale bypass";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      AccuracySec = "5s";
      Unit = "throne-tailscale-bypass.service";
    };
  };
}
