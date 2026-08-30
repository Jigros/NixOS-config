{
  pkgs,
  lib,
  ...
}: let
  ghosttyBin = lib.getExe pkgs.ghostty;
  prismLauncherBin = lib.getExe' pkgs.prismlauncher "prismlauncher";
  gsettingsSchemasDir = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}";
  gtk3SchemasDir = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
  # These names must match PrismLauncher directory names exactly.
  afkInstances = [
    "AFK (1) Mexul"
    "AFK (2) Arvenixa"
    "AFK (3) Malojoby"
    "AFK (4) Vobla67"
    "AFK (5) Meta"
    "AFK (6) Mexul"
  ];
  afkInstancesConfig =
    lib.concatMapStringsSep "\n" (instance: "  ${lib.escapeShellArg instance}") afkInstances;

  defaultConfigText = ''
    # mcfarm runtime configuration
    # This file is managed by Home Manager.
    # Override local values in ~/.config/mcfarm/config.local.sh if you want to experiment
    # without immediately rebuilding the system.

    AUTO_START=0
    STARTUP_DELAY=25
    PRISM_GUI_BOOT_DELAY=8
    INSTANCE_DELAY=25
    NETWORK_TIMEOUT=240
    THRONE_BOOT_DELAY=20
    REBOOT_DELAY=10
    SESSION_AUTOSTART_DELAY=8
    WAIT_FOR_CAELESTIA=1
    CAELESTIA_WAIT_TIMEOUT=90
    CAELESTIA_STABILIZE_DELAY=12
    WAIT_FOR_NETWORK=1
    START_THRONE=1
    THRONE_AUTO_CONNECT=1
    THRONE_START_MINIMAL=1
    THRONE_VPN_MTU=1400
    SKIP_INVALID_INSTANCES=1

    PRISM_LAUNCHER_BIN=${lib.escapeShellArg prismLauncherBin}
    THRONE_START_CMD="Throne"

    # Optional command that explicitly connects VPN inside Throne.
    # Leave empty if Throne restores the previous VPN/session state by itself.
    VPN_CONNECT_CMD=""

    # Optional command that returns 0 only when VPN is ready.
    # Example:
    # VPN_CHECK_CMD="curl --silent --fail --max-time 5 https://1.1.1.1 >/dev/null"
    VPN_CHECK_CMD=""

    NETWORK_CHECK_HOSTS=(
      "1.1.1.1"
      "8.8.8.8"
      "9.9.9.9"
    )

    INSTANCES=(
    ${afkInstancesConfig}
    )
  '';

  defaultConfig = pkgs.writeText "mcfarm-default-config.sh" defaultConfigText;

  mcfarm =
    pkgs.writeShellScriptBin "mcfarm"
    ''
      set -euo pipefail

      CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/mcfarm"
      CONFIG_FILE="$CONFIG_DIR/config.sh"
      LOCAL_CONFIG_FILE="$CONFIG_DIR/config.local.sh"
      DEFAULT_CONFIG_FILE="${defaultConfig}"
      PRISM_DATA_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/PrismLauncher"
      INSTANCES_DIR="$PRISM_DATA_DIR/instances"
      NOHUP_BIN="${pkgs.coreutils}/bin/nohup"
      FIND_BIN="${pkgs.findutils}/bin/find"
      DATE_BIN="${pkgs.coreutils}/bin/date"
      SLEEP_BIN="${pkgs.coreutils}/bin/sleep"
      PING_BIN="${pkgs.iputils}/bin/ping"
      Pgrep_BIN="${pkgs.procps}/bin/pgrep"
      BASENAME_BIN="${pkgs.coreutils}/bin/basename"
      SORT_BIN="${pkgs.coreutils}/bin/sort"
      MKDIR_BIN="${pkgs.coreutils}/bin/mkdir"
      MV_BIN="${pkgs.coreutils}/bin/mv"
      CP_BIN="${pkgs.coreutils}/bin/cp"
      JQ_BIN="${lib.getExe pkgs.jq}"
      FZF_BIN="${lib.getExe pkgs.fzf}"
      GHOSTTY_BIN="${ghosttyBin}"
      BASH_BIN="${pkgs.bashInteractive}/bin/bash"
      ZSH_BIN="${pkgs.zsh}/bin/zsh"
      GSETTINGS_SCHEMAS_DIR="${gsettingsSchemasDir}"
      GTK3_SCHEMAS_DIR="${gtk3SchemasDir}"
      THRONE_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/Throne/config"
      THRONE_CONFIG_FILE="$THRONE_CONFIG_DIR/configs.json"

      load_config() {
        source "$DEFAULT_CONFIG_FILE"

        if [[ -f "$CONFIG_FILE" ]]; then
          source "$CONFIG_FILE"
        fi

        if [[ -f "$LOCAL_CONFIG_FILE" ]]; then
          source "$LOCAL_CONFIG_FILE"
        fi

        : "''${AUTO_START:=1}"
        : "''${STARTUP_DELAY:=25}"
        : "''${PRISM_GUI_BOOT_DELAY:=8}"
        : "''${INSTANCE_DELAY:=25}"
        : "''${NETWORK_TIMEOUT:=240}"
        : "''${THRONE_BOOT_DELAY:=20}"
        : "''${REBOOT_DELAY:=10}"
        : "''${SESSION_AUTOSTART_DELAY:=8}"
        : "''${WAIT_FOR_CAELESTIA:=1}"
        : "''${CAELESTIA_WAIT_TIMEOUT:=90}"
        : "''${CAELESTIA_STABILIZE_DELAY:=12}"
        : "''${WAIT_FOR_NETWORK:=1}"
        : "''${START_THRONE:=1}"
        : "''${THRONE_AUTO_CONNECT:=1}"
        : "''${THRONE_START_MINIMAL:=1}"
        : "''${THRONE_VPN_MTU:=1400}"
        : "''${SKIP_INVALID_INSTANCES:=1}"
        : "''${PRISM_LAUNCHER_BIN:=${prismLauncherBin}}"
        : "''${THRONE_START_CMD:=Throne}"
        : "''${VPN_CONNECT_CMD:=}"
        : "''${VPN_CHECK_CMD:=}"
        : "''${DRY_RUN_MODE:=0}"
      }

      log() {
        printf '[%s] %s\n' "$("$DATE_BIN" '+%F %T')" "$*"
      }

      fail() {
        log "ERROR: $*" >&2
        exit 1
      }

      reboot_cycle() {
        log "Reboot cycle requested. The machine will reboot in $REBOOT_DELAY seconds."
        log "After boot, autologin + mcfarm autorun will continue the automation."
        "$SLEEP_BIN" "$REBOOT_DELAY"
        systemctl reboot
      }

      append_xdg_data_dir() {
        local dir="$1"

        [[ -d "$dir" ]] || return 0

        case ":''${XDG_DATA_DIRS:-}:" in
          *":$dir:"*) ;;
          :)
            XDG_DATA_DIRS="$dir"
            ;;
          *)
            XDG_DATA_DIRS="$dir:''${XDG_DATA_DIRS:-}"
            ;;
        esac
      }

      ensure_gui_runtime_env() {
        append_xdg_data_dir "$GSETTINGS_SCHEMAS_DIR"
        append_xdg_data_dir "$GTK3_SCHEMAS_DIR"
        append_xdg_data_dir "$HOME/.nix-profile/share"
        append_xdg_data_dir "/etc/profiles/per-user/$USER/share"
        append_xdg_data_dir "/nix/var/nix/profiles/default/share"
        append_xdg_data_dir "/run/current-system/sw/share"

        export XDG_DATA_DIRS
        export GTK_USE_PORTAL=0
      }

      open_log_window() {
        local runner

        ensure_gui_runtime_env
        runner="$(printf '%q' "$0") autorun; printf '\\n[mcfarm] finished. Press Ctrl+D to close.\\n'; exec $(printf '%q' "$ZSH_BIN") -l"
        "$GHOSTTY_BIN" --title="mcfarm startup logs" -e "$BASH_BIN" -lc "$runner"
      }

      usage() {
        printf '%s\n' \
          "mcfarm - AFK farm orchestrator for Throne + PrismLauncher" \
          "" \
          "Usage:" \
          "  mcfarm" \
          "  mcfarm run" \
          "  mcfarm startup-check" \
          "  mcfarm session-autostart" \
          "  mcfarm dry-run" \
          "  mcfarm reboot-cycle" \
          "  mcfarm check" \
          "  mcfarm doctor" \
          "  mcfarm test network" \
          "  mcfarm test throne" \
          "  mcfarm test prism" \
          "  mcfarm test instances" \
          "  mcfarm list" \
          "  mcfarm config" \
          "  mcfarm edit" \
          "  mcfarm edit-local" \
          "  mcfarm help"
      }

      run_shell_command() {
        local command_string="$1"
        bash -lc "$command_string"
      }

      open_in_editor() {
        local target_file="$1"
        local editor_cmd

        editor_cmd="''${EDITOR:-nvim}"
        run_shell_command "$editor_cmd $(printf '%q' "$target_file")"
      }

      ensure_local_config_file() {
        "$MKDIR_BIN" -p "$CONFIG_DIR"
        if [[ ! -f "$LOCAL_CONFIG_FILE" ]]; then
          printf '%s\n' \
            "#!/usr/bin/env bash" \
            "" \
            "# Local mcfarm overrides." \
            "# Examples:" \
            "# STARTUP_DELAY=5" \
            "# INSTANCE_DELAY=5" \
            "# NETWORK_TIMEOUT=30" \
            "# REBOOT_DELAY=5" \
            "# SESSION_AUTOSTART_DELAY=5" \
            "# WAIT_FOR_CAELESTIA=1" \
            "# CAELESTIA_WAIT_TIMEOUT=60" \
            "# CAELESTIA_STABILIZE_DELAY=8" \
            "# WAIT_FOR_NETWORK=0" \
            "# THRONE_BOOT_DELAY=8" \
            "# THRONE_START_MINIMAL=0" \
            "# THRONE_VPN_MTU=1400" \
            "# THRONE_START_CMD=\"Throne\"" \
            "# SKIP_INVALID_INSTANCES=1" \
            "# INSTANCES=(\"AFK (1) N1th\")" \
            >"$LOCAL_CONFIG_FILE"
        fi
      }

      ui() {
        local selected line command
        local default_icon="󰘳"
        local -a apps=(
          "󰑓;Run full start;mcfarm run"
          "󰖲;Startup check;mcfarm startup-check"
          "󰐊;Dry run;mcfarm dry-run"
          "󰜉;Reboot cycle;mcfarm reboot-cycle"
          "󰋩;Doctor;mcfarm doctor"
          "󰛨;Test network;mcfarm test network"
          "󰛨;Test throne;mcfarm test throne"
          "󰛨;Test prism;mcfarm test prism"
          "󰛨;Test instances;mcfarm test instances"
          ";List instances;mcfarm list"
          "󰌌;Show config;mcfarm config"
          "󰏫;Edit config;mcfarm edit"
          "󰏫;Edit local overrides;mcfarm edit-local"
        )

        for i in "''${!apps[@]}"; do
          apps[i]=$(echo "''${apps[i]}" | sed 's/^;/'$default_icon';/')
        done

        selected=$(printf "%s\n" "''${apps[@]}" | awk -F ';' '{print $1" "$2}' | "$FZF_BIN" --prompt="mcfarm > " --height=40% --reverse)
        [[ -z "$selected" ]] && exit 0

        selected=''${selected/ /;}
        line=$(printf "%s\n" "''${apps[@]}" | grep "$selected")
        command=$(echo "$line" | sed 's/^[^;]*;//;s/^[^;]*;//')
        run_shell_command "$command"
      }

      ensure_graphical_session() {
        if [[ -z "''${WAYLAND_DISPLAY:-}" && -z "''${DISPLAY:-}" ]]; then
          fail "No graphical session detected. Run this from Hyprland/GUI session."
        fi
      }

      caelestia_shell_running() {
        "$Pgrep_BIN" -fa 'caelestia shell|quickshell|caelestia-shell' >/dev/null 2>&1
      }

      wait_for_caelestia() {
        local deadline now

        if [[ "$WAIT_FOR_CAELESTIA" != "1" ]]; then
          log "Caelestia wait disabled"
          return 0
        fi

        deadline=$(( $("$DATE_BIN" +%s) + CAELESTIA_WAIT_TIMEOUT ))
        log "Waiting for caelestia/quickshell session"

        while true; do
          if caelestia_shell_running; then
            log "Caelestia/quickshell detected, waiting $CAELESTIA_STABILIZE_DELAY seconds for it to settle"
            "$SLEEP_BIN" "$CAELESTIA_STABILIZE_DELAY"
            return 0
          fi

          now=$("$DATE_BIN" +%s)
          if (( now >= deadline )); then
            log "Caelestia/quickshell was not detected within $CAELESTIA_WAIT_TIMEOUT seconds, continuing anyway"
            return 0
          fi

          "$SLEEP_BIN" 2
        done
      }

      list_available_instances() {
        [[ -d "$INSTANCES_DIR" ]] || return 0

        "$FIND_BIN" "$INSTANCES_DIR" -mindepth 1 -maxdepth 1 -type d -print \
          | while read -r dir; do
              "$BASENAME_BIN" "$dir"
            done \
          | "$SORT_BIN"
      }

      instance_exists() {
        [[ -d "$INSTANCES_DIR/$1" ]]
      }

      validate_instance() {
        local instance="$1"
        local instance_dir="$INSTANCES_DIR/$instance"

        if [[ ! -d "$instance_dir" ]]; then
          log "Skipping missing instance directory: $instance"
          return 1
        fi

        if [[ ! -f "$instance_dir/instance.cfg" ]]; then
          log "Skipping invalid instance '$instance': missing instance.cfg"
          return 1
        fi

        if [[ ! -f "$instance_dir/mmc-pack.json" ]]; then
          log "Skipping invalid instance '$instance': missing mmc-pack.json"
          return 1
        fi

        return 0
      }

      start_background_command() {
        local command_string="$1"
        "$NOHUP_BIN" bash -lc "$command_string" >/dev/null 2>&1 &
      }

      prepare_throne_config() {
        local tmp_file remember_id

        if [[ "$THRONE_AUTO_CONNECT" != "1" ]]; then
          log "Throne auto-connect patch disabled"
          return 0
        fi

        if [[ ! -f "$THRONE_CONFIG_FILE" ]]; then
          log "Throne config not found: $THRONE_CONFIG_FILE"
          return 0
        fi

        remember_id="$("$JQ_BIN" -r '.remember_id // empty' "$THRONE_CONFIG_FILE")"
        if [[ -z "$remember_id" || "$remember_id" == "null" || "$remember_id" == "0" ]]; then
          log "Throne config has no remembered profile id, skipping auto-connect patch"
          return 0
        fi

        "$MKDIR_BIN" -p "$THRONE_CONFIG_DIR"
        "$CP_BIN" -f "$THRONE_CONFIG_FILE" "$THRONE_CONFIG_FILE.bak"
        tmp_file="$(mktemp)"

        "$JQ_BIN" \
          --argjson startMinimal "$THRONE_START_MINIMAL" \
          --argjson vpnMtu "$THRONE_VPN_MTU" \
          '
            .remember_enable = true
            | .start_minimal = ($startMinimal == 1)
            | .enable_tun_routing = true
            | .vpn_mtu = $vpnMtu
            | .spmode2 = ["vpn"]
          ' \
          "$THRONE_CONFIG_FILE" >"$tmp_file"

        "$MV_BIN" "$tmp_file" "$THRONE_CONFIG_FILE"
        log "Throne auto-connect prepared for profile id $remember_id"
      }

      wait_for_network() {
        local deadline now host

        if [[ "$WAIT_FOR_NETWORK" != "1" ]]; then
          log "Network wait disabled"
          return 0
        fi

        deadline=$(( $("$DATE_BIN" +%s) + NETWORK_TIMEOUT ))

        if [[ -n "$VPN_CHECK_CMD" ]]; then
          log "Waiting for VPN check command to succeed"
          while true; do
            if bash -lc "$VPN_CHECK_CMD" >/dev/null 2>&1; then
              log "VPN check passed"
              return 0
            fi

            now=$("$DATE_BIN" +%s)
            if (( now >= deadline )); then
              fail "VPN did not become ready within $NETWORK_TIMEOUT seconds"
            fi

            "$SLEEP_BIN" 5
          done
        fi

        log "Waiting for network reachability"
        while true; do
          for host in "''${NETWORK_CHECK_HOSTS[@]}"; do
            if "$PING_BIN" -c 1 -W 2 "$host" >/dev/null 2>&1; then
              log "Network reachable via $host"
              return 0
            fi
          done

          now=$("$DATE_BIN" +%s)
          if (( now >= deadline )); then
            fail "Network did not become reachable within $NETWORK_TIMEOUT seconds"
          fi

          "$SLEEP_BIN" 5
        done
      }

      start_throne() {
        if [[ "$START_THRONE" != "1" ]]; then
          log "Throne startup disabled"
          return 0
        fi

        if [[ "$DRY_RUN_MODE" == "1" ]]; then
          log "Dry-run: would prepare and start Throne"
          return 0
        fi

        prepare_throne_config

        if "$Pgrep_BIN" -fa 'Throne|throne' >/dev/null 2>&1; then
          log "Throne already running"
        else
          log "Starting Throne"
          start_background_command "$THRONE_START_CMD"
          "$SLEEP_BIN" "$THRONE_BOOT_DELAY"
        fi

        if ! "$Pgrep_BIN" -fa 'Throne|throne' >/dev/null 2>&1; then
          fail "Throne did not start. Check THRONE_START_CMD in $CONFIG_FILE or $LOCAL_CONFIG_FILE."
        fi

        if [[ -n "$VPN_CONNECT_CMD" ]]; then
          log "Running VPN connect command"
          bash -lc "$VPN_CONNECT_CMD"
        fi
      }

      ensure_prism_launcher() {
        if [[ ! -x "$PRISM_LAUNCHER_BIN" ]]; then
          fail "PrismLauncher binary not found: $PRISM_LAUNCHER_BIN"
        fi

        if [[ "$DRY_RUN_MODE" == "1" ]]; then
          log "Dry-run: would ensure PrismLauncher is running"
          return 0
        fi

        if "$Pgrep_BIN" -fa prism >/dev/null 2>&1; then
          log "PrismLauncher already running"
          return 0
        fi

        log "Starting PrismLauncher"
        "$NOHUP_BIN" "$PRISM_LAUNCHER_BIN" >/dev/null 2>&1 &
        "$SLEEP_BIN" "$PRISM_GUI_BOOT_DELAY"
      }

      launch_single_instance() {
        local instance="$1"
        local dry_run="$2"

        if ! validate_instance "$instance"; then
          if [[ "$SKIP_INVALID_INSTANCES" == "1" ]]; then
            return 1
          fi

          fail "Invalid PrismLauncher instance: $instance"
        fi

        if [[ "$dry_run" == "1" ]]; then
          log "Dry-run launch: $instance"
          return 0
        fi

        if "$PRISM_LAUNCHER_BIN" --launch "$instance"; then
          log "Launch command sent: $instance"
          return 0
        fi

        log "Launch command failed, skipping instance: $instance"
        return 1
      }

      launch_instances() {
        local dry_run="$1"
        local instance total processed launched skipped

        total="''${#INSTANCES[@]}"
        processed=0
        launched=0
        skipped=0

        if (( total == 0 )); then
          fail "No instances configured"
        fi

        for instance in "''${INSTANCES[@]}"; do
          processed=$(( processed + 1 ))
          log "Processing instance $processed/$total: $instance"

          if launch_single_instance "$instance" "$dry_run"; then
            launched=$(( launched + 1 ))
          else
            skipped=$(( skipped + 1 ))
          fi

          if (( processed < total )); then
            "$SLEEP_BIN" "$INSTANCE_DELAY"
          fi
        done

        log "Instances done: launched=$launched skipped=$skipped total=$total"
      }

      cmd_run_impl() {
        local dry_run="$1"
        load_config
        DRY_RUN_MODE="$dry_run"
        ensure_gui_runtime_env
        ensure_graphical_session
        if [[ "$DRY_RUN_MODE" == "1" ]]; then
          log "mcfarm dry-run start"
        else
          log "mcfarm start"
        fi
        "$SLEEP_BIN" "$STARTUP_DELAY"
        start_throne
        wait_for_network
        ensure_prism_launcher
        launch_instances "$dry_run"
        log "mcfarm finished"
      }

      cmd_run() {
        cmd_run_impl 0
      }

      cmd_dry_run() {
        cmd_run_impl 1
      }

      cmd_startup_check() {
        load_config
        open_log_window
      }

      cmd_session_autostart() {
        load_config
        ensure_gui_runtime_env
        ensure_graphical_session
        wait_for_caelestia

        if (( SESSION_AUTOSTART_DELAY > 0 )); then
          log "Session autostart delay: $SESSION_AUTOSTART_DELAY seconds"
          "$SLEEP_BIN" "$SESSION_AUTOSTART_DELAY"
        fi

        open_log_window
      }

      cmd_reboot_cycle() {
        load_config
        reboot_cycle
      }

      cmd_autorun() {
        load_config

        if [[ "$AUTO_START" != "1" ]]; then
          log "AUTO_START=0, skipping autorun"
          exit 0
        fi

        cmd_run
      }

      cmd_check() {
        load_config

        log "Config file: $CONFIG_FILE"
        log "Local override: $LOCAL_CONFIG_FILE"
        log "Prism binary: $PRISM_LAUNCHER_BIN"
        log "Instances dir: $INSTANCES_DIR"

        if "$Pgrep_BIN" -fa 'Throne|throne' >/dev/null 2>&1; then
          log "Throne process: running"
        else
          log "Throne process: stopped"
        fi

        if "$Pgrep_BIN" -fa prism >/dev/null 2>&1; then
          log "PrismLauncher process: running"
        else
          log "PrismLauncher process: stopped"
        fi

        log "Configured instances: ''${#INSTANCES[@]}"
        printf '%s\n' "''${INSTANCES[@]}"
      }

      cmd_doctor() {
        local instance

        load_config
        log "Doctor start"
        cmd_check

        if [[ -f "$THRONE_CONFIG_FILE" ]]; then
          log "Throne remembered profile: $("$JQ_BIN" -r '.remember_id // "none"' "$THRONE_CONFIG_FILE")"
          log "Throne auto-connect flag: $("$JQ_BIN" -r '.remember_enable // false' "$THRONE_CONFIG_FILE")"
        else
          log "Throne config missing: $THRONE_CONFIG_FILE"
        fi

        for instance in "''${INSTANCES[@]}"; do
          validate_instance "$instance" || true
        done
      }

      cmd_list() {
        load_config
        list_available_instances
      }

      cmd_config() {
        cat "$CONFIG_FILE"
      }

      cmd_edit() {
        load_config
        open_in_editor "$CONFIG_FILE"
      }

      cmd_edit_local() {
        load_config
        ensure_local_config_file
        open_in_editor "$LOCAL_CONFIG_FILE"
      }

      cmd_test() {
        load_config

        case "''${2:-}" in
          network)
            wait_for_network
            ;;
          throne)
            ensure_graphical_session
            prepare_throne_config
            start_throne
            ;;
          prism)
            ensure_graphical_session
            ensure_prism_launcher
            ;;
          instances)
            local instance
            for instance in "''${INSTANCES[@]}"; do
              validate_instance "$instance" || true
            done
            ;;
          *)
            fail "Unknown test target. Use: network, throne, prism, instances"
            ;;
        esac
      }

      [[ "''${1:-}" == "" ]] && ui

      case "''${1:-run}" in
        run)
          cmd_run
          ;;
        startup-check)
          cmd_startup_check
          ;;
        session-autostart)
          cmd_session_autostart
          ;;
        dry-run)
          cmd_dry_run
          ;;
        reboot-cycle)
          cmd_reboot_cycle
          ;;
        autorun)
          cmd_autorun
          ;;
        check)
          cmd_check
          ;;
        doctor)
          cmd_doctor
          ;;
        test)
          cmd_test "$@"
          ;;
        list)
          cmd_list
          ;;
        config)
          cmd_config
          ;;
        edit)
          cmd_edit
          ;;
        edit-local)
          cmd_edit_local
          ;;
        help|-h|--help)
          usage
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
in {
  home.packages = [mcfarm];

  home.file.".config/mcfarm/config.sh".text = defaultConfigText;
}
