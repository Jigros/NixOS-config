# Tailscale client.
{
  config,
  ...
}: {
  # Let Tailscale integrate with the system resolver normally.
  services.resolved.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--hostname=${config.var.hostname}"
      "--accept-dns=true"
    ];
  };

  # Temporary fallback for a MagicDNS/Quad100 failure on this client:
  # tailscaled knows this peer's DNSName, but Quad100 returns no A record.
  networking.extraHosts = ''
    100.67.19.53 answer-animal.tail75889f.ts.net
  '';

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose";
  };
}
