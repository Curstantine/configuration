{ config, pkgs, ... }:
{
  home.username = "curstantine";
  home.homeDirectory = "/home/curstantine";
  home.stateVersion = "25.05";
  home.packages = with pkgs; [
    discord
    chromium
    grc
  ];

  programs.git = {
    enable = true;
    userName = "Curstantine";
    userEmail = "Curstantine@proton.me";
  };

  # Only enable chromium profiles
  programs.chromium.enable = true;

  programs.zed-editor.enable = true;
  programs.vscode.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  imports = [
    ../modules/fish.nix
    ../modules/gpg.nix
    ../modules/helix.nix
    ../modules/fooyin/fooyin.nix
  ];
}
