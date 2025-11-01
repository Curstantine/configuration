{ config, pkgs, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "amberwood";
    };
    languages = {
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "nixfmt";
          };
        }
      ];
    };
  };
}
