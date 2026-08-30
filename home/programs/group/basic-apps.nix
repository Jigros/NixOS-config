{
  inputs,
  pkgs,
  ...
}: let
  creamlinux =
    pkgs.symlinkJoin {
      name = "creamlinux-nvidia-wrapper";
      paths = [(import inputs.creamlinux-installer {inherit pkgs;})];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/creamlinux" \
          --set WEBKIT_DISABLE_DMABUF_RENDERER 1
      '';
    };

  prismlauncher =
    pkgs.symlinkJoin {
      name = "prismlauncher-gsettings-schema-dir";
      paths = [pkgs.prismlauncher];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/prismlauncher" \
          --set GSETTINGS_SCHEMA_DIR "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}/glib-2.0/schemas" \
          --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
            pkgs.dbus
          ]}"
      '';
    };
in {
  home.packages = with pkgs; [
    vlc # Video player
    textpieces # Manipulate texts
    resources # Ressource monitor
    gnome-clocks # Clocks app
    gnome-text-editor # Basic graphic text editor

    ayugram-desktop
    steam
    creamlinux
    prismlauncher
    vscode
    openrgb-with-all-plugins
    libreoffice
    qbittorrent

    antigravity-ide
    jetbrains.idea

    # I love TUIs
    caligula # User-friendly, lightweight TUI for disk imaging (ISO, USB BOOT)
    browsh # A modern text-based browser that renders anything that a modern browser can. It runs in a terminal and can be used remotely over SSH
    pastel # Command-line tool to generate, analyze, convert and manipulate colors
    dysk # A terminal-based disk usage analyzer
    wikiman # Offline search engine for manual pages (arch wiki, tldr)
    tealdeer # Fast tldr client
    sttr # Minimalist "cyberchef" like. Cross-platform, cli app to perform various operations on string
    httpie # Command-line HTTP client, a user-friendly cURL replacement
  ];
}
