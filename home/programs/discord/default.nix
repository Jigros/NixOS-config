# Discord is a popular chat application.
{inputs, ...}: {
  imports = [inputs.nixcord.homeModules.nixcord];

  programs.nixcord = {
    enable = true;
    config = {frameless = true;};
    discord = {
    vencord.enable = false;
    equicord.enable = true;  # Use Equicord 
    };
    equibop.enable = true;
    dorion.enable = true;   # Dorion
  };
}
