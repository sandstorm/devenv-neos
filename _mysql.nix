# Module: Mysql Configuration

{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.neos;
in
{
  config = lib.mkIf cfg.enable {
    # configure mysql with DB "app" and user "app" (empty password)
    services.mysql = lib.mkIf cfg.mysql {
      # DB migrations on mariadb M1 Mac are painfully slow (40 secs), so we switch to Mysql.
      package = mkDefault pkgs.mysql80;
      enable = true;
      initialDatabases = [
        { name = "app"; }
      ];
      ensureUsers = [
        {
          name = "app";
          ensurePermissions = {
            "app.*" = "ALL PRIVILEGES";
          };
        }
      ];
      # we use a non standard port by default, to not clash with the default one. To override, you can set another one
      # via services.mysql.settings.mysqld.port = 12345;
      settings.mysqld.port = mkDefault 4406;
    };
  };
}
