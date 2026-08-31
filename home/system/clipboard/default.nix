{pkgs, ...}: let
  clipboardHistory = pkgs.writeShellScriptBin "clipboard-history" ''
    selection="$(${pkgs.cliphist}/bin/cliphist list | ${pkgs.tofi}/bin/tofi --prompt-text 'Clipboard: ')"
    [ -z "$selection" ] && exit 0

    printf '%s\n' "$selection" \
      | ${pkgs.cliphist}/bin/cliphist decode \
      | ${pkgs.wl-clipboard}/bin/wl-copy

    # After the picker closes, focus returns to the previous window.
    # Paste the selected history entry just like Win+V on Windows.
    sleep 0.1
    ${pkgs.wtype}/bin/wtype -M ctrl -k v -m ctrl
  '';
in {
  home.packages = [
    pkgs.wl-clipboard
    pkgs.wtype
    clipboardHistory
  ];

  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
