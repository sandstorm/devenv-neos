# Module: PHPStorm / IntelliJ IDEA config

{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.neos;

  # not sure why we need to read and write it again; but we had problems with stale contents of this script otherwise
  ideConfigOptions = pkgs.writeTextFile { name = "ideConfigUpdates.php"; text = (builtins.readFile ./ide-config-updates.php); };
in
{
  config = lib.mkIf cfg.enable {
    # Setup and Documentation
    enterShell = ''
      ${if cfg.jetbrainsIdeConfig then ''
        mkdir -p .idea

        DB_USER=${(head config.services.mysql.ensureUsers).name} DB_PORT=${toString config.services.mysql.settings.mysqld.port} DB_NAME=${(head config.services.mysql.initialDatabases).name} php ${ideConfigOptions}
      '' else ""}
    '';
  };
}
