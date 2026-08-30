# Misc
{
  lib,
  pkgs,
  config,
  ...
}: let
  hostname = config.var.hostname;
  keyboardLayout = config.var.keyboardLayout;
  configDir = config.var.configDirectory;
  timeZone = config.var.timeZone;
  defaultLocale = config.var.defaultLocale;
  extraLocale = config.var.extraLocale;
  autoUpgrade = config.var.autoUpgrade;
  networkDropLogger = pkgs.writeShellScript "network-drop-logger" ''
    set -u

    PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.iproute2
      pkgs.iputils
      pkgs.networkmanager
      pkgs.ethtool
      pkgs.systemd
      pkgs.procps
      pkgs.util-linux
      pkgs.nettools
      pkgs.dnsutils
    ]}

    log_dir="/var/log/network-drop-captures"
    state_dir="/run/network-drop-logger"
    probe_log="$state_dir/probes.log"
    fail_count_file="$state_dir/fail-count"
    last_capture_file="$state_dir/last-capture"

    mkdir -p "$log_dir" "$state_dir"
    touch "$probe_log"
    echo 0 > "$fail_count_file"
    echo 0 > "$last_capture_file"

    section() {
      printf '\n===== %s =====\n' "$1"
    }

    run_cmd() {
      section "$*"
      timeout 20 "$@" 2>&1 || true
    }

    probe_ping() {
      ping -n -c 1 -W 2 "$1" >/dev/null 2>&1
    }

    probe_dns() {
      timeout 5 dig +time=2 +tries=1 "$1" A >/dev/null 2>&1
    }

    capture_drop() {
      now="$(date --iso-8601=seconds)"
      stamp="$(date +%Y%m%d-%H%M%S)"
      out="$log_dir/network-drop-$stamp.log"

      {
        section "summary"
        echo "captured_at=$now"
        echo "reason=$1"
        echo "hostname=$(hostname)"
        echo "kernel=$(uname -a)"

        section "recent probe history"
        tail -n 240 "$probe_log"

        run_cmd date --iso-8601=seconds
        run_cmd ip -details addr show
        run_cmd ip -details link show
        run_cmd ip route show table all
        run_cmd ip rule show
        run_cmd ss -tupn
        run_cmd nmcli general status
        run_cmd nmcli networking connectivity check
        run_cmd nmcli device status
        run_cmd nmcli device show
        run_cmd nmcli connection show --active
        run_cmd ethtool enp9s0
        run_cmd ethtool --show-eee enp9s0
        run_cmd ethtool -k enp9s0
        run_cmd cat /etc/resolv.conf
        run_cmd dig +time=2 +tries=1 google.com A
        run_cmd dig +time=2 +tries=1 cloudflare.com A
        run_cmd ping -n -c 20 -i 0.2 -W 2 192.168.1.1
        run_cmd ping -n -c 20 -i 0.2 -W 2 1.1.1.1
        run_cmd ping -n -c 20 -i 0.2 -W 2 9.9.9.9
        run_cmd journalctl -b --no-pager --since "-45 minutes" -u NetworkManager
        run_cmd journalctl -b --no-pager --since "-45 minutes" -u network-drop-logger
        run_cmd journalctl -b --no-pager --since "-45 minutes" -g "enp9s0|throne|tun|DNS|dhcp|carrier|link|disconnect|NetworkManager|r8169|RTL|ethernet"
        run_cmd ps aux
      } > "$out"

      ln -sfn "$out" "$log_dir/latest.log"
      logger -t network-drop-logger "captured network drop diagnostics: $out"
    }

    while true; do
      ts="$(date --iso-8601=seconds)"
      gateway=ok
      cloudflare=ok
      quad9=ok
      dns=ok

      probe_ping 192.168.1.1 || gateway=fail
      probe_ping 1.1.1.1 || cloudflare=fail
      probe_ping 9.9.9.9 || quad9=fail
      probe_dns google.com || dns=fail

      line="$ts gateway=$gateway cloudflare=$cloudflare quad9=$quad9 dns=$dns"
      echo "$line" >> "$probe_log"
      tail -n 1000 "$probe_log" > "$probe_log.tmp"
      mv "$probe_log.tmp" "$probe_log"

      if [ "$gateway" = fail ] || [ "$cloudflare" = fail ] || [ "$quad9" = fail ] || [ "$dns" = fail ]; then
        fail_count="$(cat "$fail_count_file" 2>/dev/null || echo 0)"
        fail_count="$((fail_count + 1))"
        echo "$fail_count" > "$fail_count_file"
      else
        echo 0 > "$fail_count_file"
        fail_count=0
      fi

      last_capture="$(cat "$last_capture_file" 2>/dev/null || echo 0)"
      now_epoch="$(date +%s)"
      if [ "$fail_count" -ge 3 ] && [ "$((now_epoch - last_capture))" -ge 300 ]; then
        echo "$now_epoch" > "$last_capture_file"
        capture_drop "$line"
      fi

      sleep 5
    done
  '';
in {
  networking.hostName = hostname;

  networking.networkmanager = {
    enable = true;
    ethernet.macAddress = "permanent";
    wifi = {
      powersave = false;
      scanRandMacAddress = false;
    };
    insertNameservers = [
      "1.1.1.1"
      "9.9.9.9"
    ];
    dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "10-enp9s0-stable-link" ''
          if [ "$1" != "enp9s0" ]; then
            exit 0
          fi

          case "$2" in
            up|dhcp4-change|connectivity-change)
              ${pkgs.ethtool}/bin/ethtool --set-eee enp9s0 eee off >/dev/null 2>&1 || true
              ${pkgs.ethtool}/bin/ethtool -K enp9s0 tso off gso off gro off >/dev/null 2>&1 || true
              ;;
          esac
        '';
      }
    ];
  };
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.network-drop-logger = {
    description = "Capture detailed diagnostics when network connectivity drops";
    wantedBy = ["multi-user.target"];
    after = ["NetworkManager.service"];
    wants = ["NetworkManager.service"];
    serviceConfig = {
      Type = "simple";
      ExecStart = networkDropLogger;
      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/log/network-drop-captures 0755 root root -"
  ];

  system.autoUpgrade = {
    enable = autoUpgrade;
    dates = "04:00";
    flake = "${configDir}";
    flags = [
      "--update-input"
      "nixpkgs"
      "--commit-lock-file"
    ];
    allowReboot = false;
  };

  time = {
    timeZone = timeZone;
  };
  i18n.defaultLocale = defaultLocale;
  i18n.extraLocaleSettings = {
    LC_ADDRESS = extraLocale;
    LC_IDENTIFICATION = extraLocale;
    LC_MEASUREMENT = extraLocale;
    LC_MONETARY = extraLocale;
    LC_NAME = extraLocale;
    LC_NUMERIC = extraLocale;
    LC_PAPER = extraLocale;
    LC_TELEPHONE = extraLocale;
    LC_TIME = extraLocale;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = keyboardLayout;
      xkb.variant = "";
    };
    gnome.gnome-keyring.enable = true;
    psd = {
      enable = true;
      resyncTimer = "10m";
    };
  };
  console.keyMap = lib.head (lib.splitString "," keyboardLayout);

  environment.variables = {
    XDG_DATA_HOME = "$HOME/.local/share";
    PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
    EDITOR = "code --wait";
    VISUAL = "code --wait";
    JAVA_HOME = "${pkgs.jdk21}";
  };

  services.libinput.enable = true;
  programs.dconf.enable = true;
  boot.supportedFilesystems = [
    "exfat"
    "ntfs"
  ];

  services = {
    dbus = {
      enable = true;
      implementation = "broker";
      packages = with pkgs; [
        gcr
        gnome-settings-daemon
      ];
    };
    gvfs.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    udisks2.enable = true;
  };

  # enable zsh autocompletion for system packages (systemd, etc)
  environment.pathsToLink = ["/share/zsh"];

  # Faster rebuilding
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    dev.enable = false;
    info.enable = false;
    nixos.enable = false;
  };

  environment.systemPackages = with pkgs; [
    fd
    bc
    gcc
    file
    git-ignore
    xdg-utils
    wget
    ethtool
    curl
    gnupg
    openssl
    vim
    go
    comma
    zip
    unzip
    optipng
    jpegoptim
    pfetch
    btop
    dnsutils
    unrar
    p7zip
  ];

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common.default = ["gtk"];
      hyprland.default = [
        "gtk"
        "hyprland"
      ];
    };

    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  security = {
    # allow wayland lockers to unlock the screen
    pam.services.hyprlock.text = "auth include login";

    # userland niceness
    rtkit.enable = true;

    # don't ask for password for wheel group
    sudo.wheelNeedsPassword = false;
  };
}
