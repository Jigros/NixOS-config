{pkgs, ...}: let
  omnirouteVersion = "3.8.51";

  opencodeWrapped = pkgs.stdenv.mkDerivation rec {
    pname = "opencode";
    version = "1.18.32";
    src = pkgs.fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      sha256 = "3046e0404fdc60fb80307e7a47824ba07477364178a4d09baa8548496dd6d43b";
    };
    sourceRoot = ".";
    unpackPhase = ''
      tar -xzf $src
    '';
    installPhase = ''
      mkdir -p $out/bin $out/libexec
      install -m755 opencode $out/libexec/opencode-real
      cat > $out/bin/opencode <<EOF
#!${pkgs.bash}/bin/bash
set -eo pipefail

# OpenCode 1.x keeps all sessions in one SQLite DB by default. Concurrent
# processes can deadlock on that shared DB, so use one DB per project while
# keeping the normal shared config, credentials, cache, and OmniRoute account.
if [[ -z "\''${OPENCODE_DB:-}" ]]; then
  project_root="\$PWD"
  git_root="\$(${pkgs.git}/bin/git -C "\$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "\$git_root" ]] && project_root="\$git_root"

  db_dir="\''${XDG_DATA_HOME:-\$HOME/.local/share}/opencode/project-db"
  ${pkgs.coreutils}/bin/mkdir -p "\$db_dir"

  project_hash="\$(printf '%s' "\$project_root" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)"
  project_name="\$(${pkgs.coreutils}/bin/basename "\$project_root" | ${pkgs.coreutils}/bin/tr -c 'A-Za-z0-9._-' '_')"
  export OPENCODE_DB="\$db_dir/\''${project_name}-\''${project_hash}.sqlite"
fi

exec ${pkgs.stdenv.cc.bintools.dynamicLinker} \
  --library-path "${pkgs.lib.makeLibraryPath [pkgs.glibc pkgs.stdenv.cc.cc.lib]}:\$LD_LIBRARY_PATH" \
  "$out/libexec/opencode-real" "\$@"
EOF
      chmod +x $out/bin/opencode
    '';
    dontFixup = true;
  };

  opencodeQueueConfig = pkgs.writeText "opencode-omniroute-haproxy.cfg" ''
    global
      maxconn 64

    defaults
      mode http
      timeout connect 10s
      timeout client 1h
      timeout server 1h
      timeout queue 1h

    frontend opencode
      bind 127.0.0.1:20129
      default_backend omniroute

    backend omniroute
      server local 127.0.0.1:20128 maxconn 1
  '';

  configureOmniRouteCompression = pkgs.writeShellApplication {
    name = "configure-omniroute-compression";
    runtimeInputs = with pkgs; [coreutils sqlite];
    text = ''
      set -euo pipefail

      mkdir -p "$HOME/.omniroute"
      db="$HOME/.omniroute/storage.sqlite"

      # Fresh installs create the DB on first OmniRoute start; restored installs
      # already have it. In the former case, simply apply this on the next start.
      [[ -f "$db" ]] || exit 0

      sqlite3 "$db" <<'SQL'
      BEGIN IMMEDIATE;

      INSERT INTO key_value (namespace, key, value)
      VALUES ('compression', 'enabled', 'true')
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES ('compression', 'defaultMode', '"stacked"')
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES ('compression', 'autoTriggerMode', '"stacked"')
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES ('compression', 'autoTriggerTokens', '32000')
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES (
        'compression',
        'stackedPipeline',
        '[{"engine":"rtk","intensity":"standard"},{"engine":"caveman","intensity":"full"}]'
      )
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES ('compression', 'mcpDescriptionCompressionEnabled', 'true')
      ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;

      INSERT INTO key_value (namespace, key, value)
      VALUES (
        'compression',
        'rtkConfig',
        '{"enabled":true,"intensity":"standard","applyToToolResults":true,"applyToCodeBlocks":false,"applyToAssistantMessages":false,"deduplicateThreshold":3,"enableGrouping":true,"groupingThreshold":3,"stripCodeComments":false,"preserveDocstrings":true,"rawOutputRetention":"never"}'
      )
      ON CONFLICT(namespace, key) DO UPDATE SET value = json_set(
        CASE WHEN json_valid(key_value.value) THEN key_value.value ELSE '{}' END,
        '$.enabled', json('true'),
        '$.intensity', 'standard',
        '$.applyToToolResults', json('true'),
        '$.applyToCodeBlocks', json('false'),
        '$.applyToAssistantMessages', json('false'),
        '$.deduplicateThreshold', 3,
        '$.enableGrouping', json('true'),
        '$.groupingThreshold', 3,
        '$.stripCodeComments', json('false'),
        '$.preserveDocstrings', json('true'),
        '$.rawOutputRetention', 'never'
      );

      COMMIT;
SQL
    '';
  };

  restoreOpenCodeBackup = pkgs.writeShellApplication {
    name = "restore-opencode-backup";
    runtimeInputs = with pkgs; [coreutils rsync systemd];
    text = ''
      set -euo pipefail

      backup_root="''${1:-$HOME/restore-backup}"
      opencode_backup="$backup_root/opencode"
      omniroute_backup="$backup_root/omniroute-data"

      if [[ ! -d "$opencode_backup" ]]; then
        echo "Missing OpenCode backup: $opencode_backup" >&2
        exit 1
      fi

      if [[ ! -d "$omniroute_backup" ]]; then
        echo "Missing OmniRoute backup: $omniroute_backup" >&2
        exit 1
      fi

      stamp="$(date +%Y%m%d-%H%M%S)"
      safety="$HOME/.restore-pre-ai-$stamp"
      mkdir -p "$safety"

      systemctl --user stop omniroute.service 2>/dev/null || true

      if [[ -d "$HOME/.local/share/opencode" ]]; then
        mkdir -p "$safety/opencode"
        rsync -a "$HOME/.local/share/opencode/" "$safety/opencode/"
      fi

      if [[ -d "$HOME/.omniroute" ]]; then
        mkdir -p "$safety/omniroute-data"
        rsync -a "$HOME/.omniroute/" "$safety/omniroute-data/"
      fi

      mkdir -p "$HOME/.local/share/opencode" "$HOME/.omniroute"
      rsync -a "$opencode_backup/" "$HOME/.local/share/opencode/"
      rsync -a "$omniroute_backup/" "$HOME/.omniroute/"

      if [[ -f "$backup_root/auth.json" && ! -f "$HOME/.local/share/opencode/auth.json" ]]; then
        install -m 600 "$backup_root/auth.json" "$HOME/.local/share/opencode/auth.json"
      fi
      if [[ -f "$backup_root/server.env" && ! -f "$HOME/.omniroute/server.env" ]]; then
        install -m 600 "$backup_root/server.env" "$HOME/.omniroute/server.env"
      fi

      [[ -f "$HOME/.local/share/opencode/auth.json" ]] && chmod 600 "$HOME/.local/share/opencode/auth.json"
      [[ -f "$HOME/.omniroute/server.env" ]] && chmod 600 "$HOME/.omniroute/server.env"

      systemctl --user start omniroute.service

      echo "Restored OpenCode state to $HOME/.local/share/opencode"
      echo "Restored OmniRoute state to $HOME/.omniroute"
      echo "Previous local state (if any) was saved in $safety"
    '';
  };
in {
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;
    extraPackages = with pkgs; [git ripgrep fd jq];

    settings = {
      autoupdate = false;
      model = "omniroute/SOL-MEDIUM";

      provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options = {
          baseURL = "http://127.0.0.1:20129/v1";
          apiKey = "{file:/run/secrets/omniroute-opencode-key}";
        };
        models = {
          "FREE-FAST" = {name = "FREE-FAST";};
          "FREE-CODE" = {name = "FREE-CODE";};
          "FREE-HARD" = {name = "FREE-HARD";};
          "SOL-MEDIUM" = {name = "SOL-MEDIUM";};
          "SOL-HIGH" = {name = "SOL-HIGH";};
          "LUNA-LOW" = {name = "LUNA-LOW";};
          "LUNA-MEDIUM" = {name = "LUNA-MEDIUM";};
        };
      };
    };
  };

  # Upstream's Nix flake only exposes a devShell, not an installable package.
  # Pin the npm release and let npx cache it under ~/.cache/npm.
  systemd.user.services.opencode-omniroute-queue = {
    Unit = {
      Description = "Serialize OpenCode requests to the single Codex account";
      After = ["omniroute.service"];
      Wants = ["omniroute.service"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.haproxy}/bin/haproxy -W -db -f ${opencodeQueueConfig}";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.omniroute = {
    Unit = {
      Description = "OmniRoute AI gateway";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };

    Service = {
      Type = "simple";
      ExecStartPre = "${configureOmniRouteCompression}/bin/configure-omniroute-compression";
      ExecStart = "${pkgs.nodejs_22}/bin/npx --yes omniroute@${omnirouteVersion} --no-open";
      WorkingDirectory = "%h/.omniroute";
      Environment = [
        "PORT=20128"
        "OMNIROUTE_SERVER_HOST=127.0.0.1"
        "NODE_ENV=production"
        "NODE_OPTIONS=--max-old-space-size=8192"
        "NPM_CONFIG_CACHE=%h/.cache/npm"
      ];
      EnvironmentFile = "-%h/.omniroute/server.env";
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install.WantedBy = ["default.target"];
  };

  home.packages = [restoreOpenCodeBackup];
}
