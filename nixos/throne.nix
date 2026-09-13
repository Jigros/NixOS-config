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
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    path = [pkgs.nftables pkgs.tailscale pkgs.iproute2 pkgs.gnused];
    serviceConfig.Type = "oneshot";
    script = ''
      set -u

      if ! nft list set inet sing-box inet4_local_address_set >/dev/null 2>&1; then
        # Throne/TUN is not running yet. The timer will retry.
        exit 0
      fi

      if nft get element inet sing-box inet4_local_address_set '{ 100.64.0.0/10 }' >/dev/null 2>&1; then
        exit 0
      fi

      # Throne inserts this machine's own Tailscale /32 into the interval set.
      # Remove every locally discovered tailscale0 IPv4 address first because
      # nftables interval sets reject a /10 that overlaps an existing /32.
      local_addresses="$(
        {
          tailscale ip -4 2>/dev/null || true
          ip -4 -o addr show dev tailscale0 2>/dev/null | sed -n 's/.* inet \([^/ ]*\).*/\1/p'
        } | sed '/^$/d' | sort -u
      )"

      # Keep the currently known address as a fallback for activation ordering
      # where tailscale0 is briefly unavailable during nixos-rebuild.
      local_addresses="''${local_addresses}
100.88.176.74"

      printf '%s\n' "$local_addresses" | sed '/^$/d' | sort -u | while IFS= read -r address; do
        nft delete element inet sing-box inet4_local_address_set "{ $address }" 2>/dev/null || true
      done

      # Do not fail nixos-rebuild if Throne rewrites the set concurrently; the
      # timer retries every 30 seconds and will converge once the set is stable.
      nft add element inet sing-box inet4_local_address_set '{ 100.64.0.0/10 }' 2>/dev/null || true
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
