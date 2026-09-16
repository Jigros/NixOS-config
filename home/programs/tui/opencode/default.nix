{pkgs, ...}: let
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

      echo "Restored OpenCode state to $HOME/.local/share/opencode"
      echo "Restored OmniRoute state to $HOME/.omniroute"
      echo "Previous local state (if any) was saved in $safety"
    '';
  };
in {
  programs.opencode = {
    enable = true;
    extraPackages = with pkgs; [git ripgrep fd jq];

    settings = {
      autoupdate = false;
      model = "omniroute/SOL-MEDIUM";

      provider.omniroute = {
        npm = "@ai-sdk/openai-compatible";
        name = "OmniRoute";
        options.baseURL = "http://127.0.0.1:20128/v1";
        models = {
          "FREE-FAST" = {name = "FREE-FAST";};
          "FREE-CODE" = {name = "FREE-CODE";};
          "FREE-HARD" = {name = "FREE-HARD";};
          "SOL-XHIGH" = {name = "SOL-XHIGH";};
          "SOL-MEDIUM" = {name = "SOL-MEDIUM";};
          "SOL-HIGH" = {name = "SOL-HIGH";};
          "LUNA-LOW" = {name = "LUNA-LOW";};
          "TERRA-MEDIUM" = {name = "TERRA-MEDIUM";};
        };
      };
    };

    tui.theme = "system";
  };

  home.packages = [restoreOpenCodeBackup];
}
