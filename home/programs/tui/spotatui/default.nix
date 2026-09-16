# Spotatui is a terminal music player for Spotify, YouTube and other sources.
{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: let
  c = config.lib.stylix.colors;
  rgb = base: "${c."${base}-rgb-r"}, ${c."${base}-rgb-g"}, ${c."${base}-rgb-b"}";

  # nixpkgs 26.05 still ships an older Spotify-only Spotatui. Use the current
  # unstable package, enable its AI DJ, and add the YouTube source so the DJ can
  # resolve recommendations through YouTube when Spotify playback is unavailable.
  spotatuiWithYoutube =
    (pkgs-unstable.spotatui.override {
      withAiDj = true;
    }).overrideAttrs (old: {
      buildFeatures = (old.buildFeatures or []) ++ ["youtube"];
    });
in {
  home.packages = [
    spotatuiWithYoutube
    pkgs-unstable.yt-dlp
    pkgs-unstable.ffmpeg
    pkgs-unstable.ollama
  ];

  # Local model backend for Spotatui's DJ. This avoids requiring an Anthropic,
  # OpenAI, Spotify Premium, or other paid API subscription for recommendations.
  systemd.user.services.ollama = {
    Unit = {
      Description = "Ollama local model server for Spotatui AI DJ";
      After = ["network-online.target"];
    };
    Service = {
      ExecStart = "${pkgs-unstable.ollama}/bin/ollama serve";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = ["OLLAMA_HOST=127.0.0.1:11434"];
    };
    Install.WantedBy = ["default.target"];
  };

  home.persistence."/persist" = lib.mkIf (config.var.impermanenceEnabled or false) {
    directories = [".config/spotatui" ".config/spotify" ".ollama"];
  };

  xdg.desktopEntries.spotatui = {
    name = "Spotify";
    exec = "${pkgs.ghostty}/bin/ghostty +new-window -e ${spotatuiWithYoutube}/bin/spotatui";
    icon = "spotify";
    comment = "Spotify recommendations with free YouTube playback";
    categories = ["Audio" "Music"];
    terminal = false;
    settings.Keywords = "spotify;spotatui;youtube;music;dj;";
  };

  home.file.".config/spotatui/config.yml".text = ''
    keybindings:
      back: q
      next_page: ctrl-d
      previous_page: ctrl-u
      jump_to_start: ctrl-a
      jump_to_end: ctrl-e
      jump_to_album: a
      jump_to_artist_album: A
      jump_to_context: o
      manage_devices: d
      decrease_volume: '-'
      increase_volume: +
      toggle_playback: space
      seek_backwards: <
      seek_forwards: '>'
      next_track: n
      previous_track: p
      force_previous_track: P
      help: '?'
      shuffle: ctrl-s
      repeat: ctrl-r
      search: /
      submit: enter
      copy_song_url: c
      copy_album_url: C
      audio_analysis: v
      lyrics_view: B
      cover_art_view: G
      add_item_to_queue: z
      show_queue: Q
      open_settings: alt-,
      save_settings: alt-s
      listening_party: ctrl-p
      like_track: F
    behavior:
      seek_milliseconds: 5000
      volume_increment: 10
      volume_percent: 100
      tick_rate_milliseconds: 16
      enable_text_emphasis: true
      show_loading_indicator: true
      enforce_wide_search_bar: true
      enable_global_song_count: false
      disable_mouse_inputs: false
      enable_discord_rpc: false
      discord_rpc_client_id: null
      enable_announcements: false
      announcement_feed_url: null
      seen_announcement_ids:
      - 2026-05-19-sonos-help-wanted
      - 2026-02-27-major-refactor-complete
      shuffle_enabled: false
      liked_icon: ♥
      shuffle_icon: 🔀
      repeat_track_icon: 🔂
      repeat_context_icon: 🔁
      playing_icon: ▶
      paused_icon: ⏸
      set_window_title: true
      visualizer_style: Equalizer
      dismissed_announcements: []
      relay_server_url: wss://spotatui-party.spotatui.workers.dev/ws
      stop_after_current_track: false
      sidebar_width_percent: 20
      playbar_height_rows: 6
      library_height_percent: 30
      startup_behavior: continue
      disable_auto_update: true
      auto_update_delay: '0'
      keepawake_enabled: true

      # Free playback path: the DJ resolves track names against Spotify metadata
      # first, then falls back to YouTube and plays them through yt-dlp.
      ytdlp_path: ${pkgs-unstable.yt-dlp}/bin/yt-dlp
      dj_backend: openai_compat
      dj_base_url: http://127.0.0.1:11434/v1
      dj_model: qwen3:4b
      dj_batch_size: 6
      dj_history_period: 30d
      dj_avoid_library: false
      dj_configured: true
    theme:
      preset: Custom
      active: ${rgb "base0D"}
      banner: ${rgb "base0C"}
      error_border: ${rgb "base08"}
      error_text: ${rgb "base08"}
      hint: ${rgb "base0A"}
      hovered: ${rgb "base0E"}
      inactive: ${rgb "base03"}
      playbar_background: Reset
      playbar_progress: ${rgb "base0D"}
      playbar_progress_text: ${rgb "base05"}
      playbar_text: Reset
      selected: ${rgb "base0D"}
      text: Reset
      background: Reset
      header: Reset
      highlighted_lyrics: ${rgb "base0B"}
  '';
}
