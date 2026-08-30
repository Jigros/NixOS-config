{
  pkgs,
  pkgs-stable,
  inputs,
  system,
}: let
  minecraftNativeLibraryPath = pkgs.lib.makeLibraryPath [
    pkgs.dbus
  ];

  minecraft-java-temurin25 = pkgs.writeShellScriptBin "minecraft-java-temurin25" ''
    export LD_LIBRARY_PATH="${minecraftNativeLibraryPath}:''${LD_LIBRARY_PATH:-}"
    exec ${pkgs.temurin-bin-25}/bin/java --enable-native-access=ALL-UNNAMED "$@"
  '';

  minecraft-java-zulu25 = pkgs.writeShellScriptBin "minecraft-java-zulu25" ''
    export LD_LIBRARY_PATH="${minecraftNativeLibraryPath}:''${LD_LIBRARY_PATH:-}"
    exec ${pkgs.zulu25}/bin/java --enable-native-access=ALL-UNNAMED "$@"
  '';
in
  (with pkgs; [
    go
    bun
    nodejs
    jdk21
    minecraft-java-temurin25
    minecraft-java-zulu25
    gradle
    inputs.bun2nix.packages.${system}.default
  ])
  ++ (with pkgs-stable; [
    air
    duckdb
    python3
    jq
    just
    nix-prefetch-github
    rsync
  ])
