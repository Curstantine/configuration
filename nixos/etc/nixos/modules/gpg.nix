{ config, pkgs, ... }:
{
  programs.gpg.enable = true;
  programs.gpg.settings.keyserver = "hkps://keys.opengpg.org";
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
    enableFishIntegration = true;
    maxCacheTtl = 86400;
    maxCacheTtlSsh = 86400;
    pinentry.package = pkgs.pinentry-qt;
  };
}
