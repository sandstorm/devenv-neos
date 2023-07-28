# Module: Mysql Configuration

{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.neos;
in
{
  config = lib.mkIf (and cfg.enable config.services.caddy.enable) {
    services.caddy = {
      virtualHosts = {
        "http://127.0.0.1:${toString cfg.caddyDefaultVhostPort}" = {
          extraConfig = ''
            root * ${cfg.caddyDefaultVhostRoot}
          '' + cfg.caddyDefaultVhostConfig;
        };
      };
    };
  };
}
